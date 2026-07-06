import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import '../../core/constants/api_constants.dart';
import '../../core/utils/game_utils.dart';
import '../models/guild_model.dart';
import '../models/user_model.dart';

class GuildRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Dio _dio;

  GuildRepository(this._dio);

  Future<GuildModel?> getGuild(String guildId) async {
    final doc = await _db.collection('guilds').doc(guildId).get();
    if (!doc.exists) return null;
    return GuildModel.fromJson(doc.data()!);
  }

  Stream<GuildModel?> watchGuild(String guildId) {
    return _db.collection('guilds').doc(guildId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GuildModel.fromJson(doc.data()!);
    });
  }

  Future<String> createGuild({
    required String name,
    required String iconId,
    required UserModel leader,
  }) async {
    final guildCode = _generateGuildCode();
    final guildRef = _db.collection('guilds').doc();
    
    final guild = GuildModel(
      id: guildRef.id,
      name: name,
      iconId: iconId,
      code: guildCode,
      leaderUid: leader.uid,
      memberUids: [leader.uid],
      createdAt: DateTime.now(),
    );

    await _db.runTransaction((transaction) async {
      transaction.set(guildRef, guild.toJson());
      transaction.update(_db.collection('users').doc(leader.uid), {'guildId': guildRef.id});
    });

    return guildRef.id;
  }

  Future<void> joinGuild(String code, UserModel user) async {
    final query = await _db.collection('guilds').where('code', isEqualTo: code).limit(1).get();
    if (query.docs.isEmpty) throw Exception('Guild not found');

    final guildDoc = query.docs.first;
    final guild = GuildModel.fromJson(guildDoc.data());

    if (guild.memberUids.contains(user.uid)) return;

    await _db.runTransaction((transaction) async {
      transaction.update(guildDoc.reference, {
        'memberUids': FieldValue.arrayUnion([user.uid])
      });
      transaction.update(_db.collection('users').doc(user.uid), {'guildId': guild.id});
    });
  }

  Future<void> leaveGuild(String guildId, String uid) async {
    final guildDoc = await _db.collection('guilds').doc(guildId).get();
    if (!guildDoc.exists) return;

    final guild = GuildModel.fromJson(guildDoc.data()!);
    final newMemberUids = List<String>.from(guild.memberUids)..remove(uid);

    await _db.runTransaction((transaction) async {
      if (newMemberUids.isEmpty) {
        transaction.delete(guildDoc.reference);
        // Also delete sub-collections or matches related to this guild if necessary
      } else {
        String newLeaderUid = guild.leaderUid;
        if (guild.leaderUid == uid) {
          newLeaderUid = newMemberUids.first;
        }
        transaction.update(guildDoc.reference, {
          'memberUids': newMemberUids,
          'leaderUid': newLeaderUid,
        });
      }
      transaction.update(_db.collection('users').doc(uid), {'guildId': null});
    });
  }

  Future<void> updateGuildIcon(String guildId, String iconId) async {
    await _db.collection('guilds').doc(guildId).update({'iconId': iconId});
  }

  // GUILD BATTLE METHODS

  Future<void> startReadyCheck(String guildId, List<String> memberUids) async {
    final matchRef = _db.collection('guildMatches').doc();
    final startTime = DateTime.now();

    final guild = await getGuild(guildId);
    if (guild == null) return;

    final match = GuildBattleMatchModel(
      id: matchRef.id,
      guildAId: guildId,
      guildBId: '',
      guildAName: guild.name,
      guildBName: '',
      guildAIcon: guild.iconId,
      guildBIcon: '',
      guildAPlayers: memberUids,
      guildBPlayers: [],
      startTime: startTime,
      status: GuildBattleStatus.readyCheck,
      readyStatus: {for (var uid in memberUids) uid: false},
    );

    await _db.runTransaction((transaction) async {
      transaction.set(matchRef, match.toJson());
      transaction.update(_db.collection('guilds').doc(guildId), {'currentBattleId': matchRef.id});
    });
  }

  Future<void> setPlayerReady(String guildId, String uid, bool ready) async {
    await _db.collection('guilds').doc(guildId).update({
      'readyPlayerUids': ready 
          ? FieldValue.arrayUnion([uid]) 
          : FieldValue.arrayRemove([uid])
    });
  }

  Future<void> startMatchmaking(String guildId, String categoryId, String categoryName) async {
    await _db.collection('guilds').doc(guildId).update({
      'battleStatus': GuildBattleStatus.searching.name,
      'selectedCategoryId': categoryId,
      'selectedCategoryName': categoryName,
    });
    
    // Trigger matchmaking logic
    _tryMatchGuilds(guildId, categoryId);
  }

  Future<void> cancelMatchmaking(String guildId) async {
    await _db.collection('guilds').doc(guildId).update({
      'battleStatus': GuildBattleStatus.idle.name,
      'readyPlayerUids': [],
      'selectedCategoryId': null,
      'selectedCategoryName': null,
    });
  }

  Future<void> _tryMatchGuilds(String myGuildId, String categoryId) async {
    // 1. Find potential opponents
    final query = await _db.collection('guilds')
        .where('battleStatus', isEqualTo: GuildBattleStatus.searching.name)
        .where('selectedCategoryId', isEqualTo: categoryId)
        .get();

    final opponents = query.docs
        .map((doc) => GuildModel.fromJson(doc.data()))
        .where((g) => g.id != myGuildId && g.readyPlayerUids.length >= 2)
        .toList();

    if (opponents.isEmpty) return;

    // Sort by XP/Level proximity (simple matching)
    final myGuildDoc = await _db.collection('guilds').doc(myGuildId).get();
    final myGuild = GuildModel.fromJson(myGuildDoc.data()!);
    
    opponents.sort((a, b) => (a.xp - myGuild.xp).abs().compareTo((b.xp - myGuild.xp).abs()));
    final opponent = opponents.first;

    // 2. Create the Battle Match Document
    try {
      await _db.runTransaction((transaction) async {
        // Re-verify both are still searching
        final g1Doc = await transaction.get(_db.collection('guilds').doc(myGuildId));
        final g2Doc = await transaction.get(_db.collection('guilds').doc(opponent.id));
        
        final g1 = GuildModel.fromJson(g1Doc.data()!);
        final g2 = GuildModel.fromJson(g2Doc.data()!);

        if (g1.battleStatus != GuildBattleStatus.searching || g2.battleStatus != GuildBattleStatus.searching) {
          return;
        }

        final matchId = _db.collection('guildMatches').doc().id;
        final matchRef = _db.collection('guildMatches').doc(matchId);

        final match = GuildBattleMatchModel(
          id: matchId,
          guildAId: g1.id,
          guildBId: g2.id,
          guildAName: g1.name,
          guildBName: g2.name,
          guildAIcon: g1.iconId,
          guildBIcon: g2.iconId,
          guildAPlayers: g1.readyPlayerUids,
          guildBPlayers: g2.readyPlayerUids,
          startTime: DateTime.now().add(const Duration(seconds: 5)), // 5s countdown
          status: GuildBattleStatus.matched,
        );

        // Update Match
        transaction.set(matchRef, match.toJson());

        // Update Guilds
        transaction.update(g1Doc.reference, {
          'battleStatus': GuildBattleStatus.matched.name,
          'currentBattleId': matchId,
        });
        transaction.update(g2Doc.reference, {
          'battleStatus': GuildBattleStatus.matched.name,
          'currentBattleId': matchId,
        });

        // 3. Setup individual Game Rooms for players
        final questions = await _fetchMatchQuestions();
        
        // Pair players (simplified: random pairs or just create a room for each pair)
        // Since guilds might have different counts, we might need a more complex pairing.
        // For now, let's assume we pair them up to the smaller count.
        final minCount = g1.readyPlayerUids.length < g2.readyPlayerUids.length 
            ? g1.readyPlayerUids.length 
            : g2.readyPlayerUids.length;

        for (int i = 0; i < minCount; i++) {
          final pA = g1.readyPlayerUids[i];
          final pB = g2.readyPlayerUids[i];
          final roomId = _db.collection('gameRooms').doc().id;

          final pADoc = await _db.collection('users').doc(pA).get();
          final pBDoc = await _db.collection('users').doc(pB).get();

          transaction.set(_db.collection('gameRooms').doc(roomId), {
            'roomId': roomId,
            'status': 'active',
            'isRanked': true,
            'guildBattleId': matchId,
            'guildAId': g1.id,
            'guildBId': g2.id,
            'player1': {...pADoc.data()!, 'score': 0, 'answers': [], 'isReady': true},
            'player2': {...pBDoc.data()!, 'score': 0, 'answers': [], 'isReady': true},
            'questions': questions,
            'createdAt': FieldValue.serverTimestamp(),
            'questionStartedAt': FieldValue.serverTimestamp(),
            'currentQuestionIndex': 0,
          });
        }
      });
    } catch (e) {
      debugPrint('Guild Match Creation Error: $e');
    }
  }

  Future<void> cancelMatch(String matchId, String guildId) async {
    await _db.runTransaction((transaction) async {
      transaction.update(_db.collection('guildMatches').doc(matchId), {'status': GuildBattleStatus.cancelled.name});
      transaction.update(_db.collection('guilds').doc(guildId), {'currentBattleId': null});
    });
  }

  Future<void> enterQueue(String matchId, GuildModel guild, List<String> readyPlayers, int avgRankPoints) async {
    final queueRef = _db.collection('guildBattleQueue').doc(guild.id);
    final queueItem = GuildBattleQueueModel(
      guildId: guild.id,
      guildName: guild.name,
      guildIconId: guild.iconId,
      guildXp: guild.xp,
      averageRankPoints: avgRankPoints,
      readyPlayerUids: readyPlayers,
      joinedAt: DateTime.now(),
    );

    await _db.runTransaction((transaction) async {
      transaction.set(queueRef, queueItem.toJson());
      transaction.update(_db.collection('guildMatches').doc(matchId), {'status': GuildBattleStatus.matchmaking.name});
    });

    _findMatch(queueItem, matchId);
  }

  Future<void> _findMatch(GuildBattleQueueModel myQueue, String myMatchId) async {
    final query = await _db.collection('guildBattleQueue')
        .where('guildId', isNotEqualTo: myQueue.guildId)
        .get();

    final potentialOpponents = query.docs.map((doc) => GuildBattleQueueModel.fromJson(doc.data())).toList();
    final compatibleOpponents = potentialOpponents.where((o) => o.readyPlayerUids.length == myQueue.readyPlayerUids.length).toList();

    if (compatibleOpponents.isEmpty) return;

    compatibleOpponents.sort((a, b) {
      final scoreA = (a.guildXp - myQueue.guildXp).abs() + (a.averageRankPoints - myQueue.averageRankPoints).abs();
      final scoreB = (b.guildXp - myQueue.guildXp).abs() + (b.averageRankPoints - myQueue.averageRankPoints).abs();
      return scoreA.compareTo(scoreB);
    });

    final opponent = compatibleOpponents.first;

    try {
      await _db.runTransaction((transaction) async {
        final oppDoc = await transaction.get(_db.collection('guildBattleQueue').doc(opponent.guildId));
        if (!oppDoc.exists) return;

        final oppGuildDoc = await transaction.get(_db.collection('guilds').doc(opponent.guildId));
        final String? oppMatchId = oppGuildDoc.data()?['currentBattleId'];
        if (oppMatchId == null) return;

        // PAIR PLAYERS AND CREATE ROOMS
        final List<String> playerAIds = myQueue.readyPlayerUids;
        final List<String> playerBIds = List<String>.from(opponent.readyPlayerUids)..shuffle();

        final List<Map<String, dynamic>> questions = await _fetchMatchQuestions();

        for (int i = 0; i < playerAIds.length; i++) {
          final pA = playerAIds[i];
          final pB = playerBIds[i];
          final roomId = _db.collection('gameRooms').doc().id;

          // Fetch player datas
          final pADoc = await transaction.get(_db.collection('users').doc(pA));
          final pBDoc = await transaction.get(_db.collection('users').doc(pB));

          final pAData = pADoc.data()!;
          final pBData = pBDoc.data()!;

          transaction.set(_db.collection('gameRooms').doc(roomId), {
            'roomId': roomId,
            'status': 'active',
            'isRanked': true,
            'guildBattleId': myMatchId,
            'guildAId': myQueue.guildId,
            'guildBId': opponent.guildId,
            'player1': {...pAData, 'score': 0, 'answers': [], 'isReady': true},
            'player2': {...pBData, 'score': 0, 'answers': [], 'isReady': true},
            'questions': questions,
            'createdAt': FieldValue.serverTimestamp(),
            'questionStartedAt': FieldValue.serverTimestamp(),
            'currentQuestionIndex': 0,
          });
        }

        transaction.update(_db.collection('guildMatches').doc(myMatchId), {
          'guildBId': opponent.guildId,
          'guildBName': opponent.guildName,
          'guildBIcon': opponent.guildIconId,
          'guildBPlayers': opponent.readyPlayerUids,
          'status': GuildBattleStatus.live.name,
        });

        transaction.update(_db.collection('guilds').doc(opponent.guildId), {'currentBattleId': myMatchId});
        transaction.delete(_db.collection('guildMatches').doc(oppMatchId));
        transaction.delete(_db.collection('guildBattleQueue').doc(myQueue.guildId));
        transaction.delete(_db.collection('guildBattleQueue').doc(opponent.guildId));
      });
    } catch (e) {
      print('Matchmaking error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchMatchQuestions() async {
    try {
      final response = await _dio.get(ApiConstants.triviaUrl, queryParameters: {'amount': 10});
      return (response.data['results'] as List).map((q) => {
        'question': GameUtils.decodeHtmlEntities(q['question']),
        'correct_answer': GameUtils.decodeHtmlEntities(q['correct_answer']),
        'incorrect_answers': (q['incorrect_answers'] as List).map((a) => GameUtils.decodeHtmlEntities(a)).toList(),
      }).toList();
    } catch (e) {
      return GameUtils.getFallbackQuestions().take(10).toList();
    }
  }

  Future<void> updatePlayerScore(String matchId, String uid, int score) async {
    await _db.collection('guildMatches').doc(matchId).update({
      'playerScores.$uid': score,
      'playerStatus.$uid': 'finished',
    });
    
    // Check if all finished to finalize
    _checkFinalize(matchId);
  }

  Future<void> _checkFinalize(String matchId) async {
    final doc = await _db.collection('guildMatches').doc(matchId).get();
    if (!doc.exists) return;

    final match = GuildBattleMatchModel.fromJson(doc.data()!);
    final totalPlayers = match.guildAPlayers.length + match.guildBPlayers.length;
    
    if (match.playerStatus.length == totalPlayers) {
      finalizeBattle(matchId);
    }
  }

  Future<void> finalizeBattle(String matchId) async {
    final doc = await _db.collection('guildMatches').doc(matchId).get();
    final match = GuildBattleMatchModel.fromJson(doc.data()!);

    int scoreA = 0;
    int scoreB = 0;

    for (final uid in match.guildAPlayers) {
      scoreA += match.playerScores[uid] ?? 0;
    }
    for (final uid in match.guildBPlayers) {
      scoreB += match.playerScores[uid] ?? 0;
    }

    final winningGuildId = scoreA > scoreB ? match.guildAId : (scoreB > scoreA ? match.guildBId : null);
    
    await _db.runTransaction((transaction) async {
      transaction.update(_db.collection('guildMatches').doc(matchId), {
        'guildAScore': scoreA,
        'guildBScore': scoreB,
        'status': GuildBattleStatus.completed.name,
        'endedAt': FieldValue.serverTimestamp(),
      });

      // Update Guilds
      _updateGuildStats(transaction, match.guildAId, scoreA > scoreB, scoreA);
      _updateGuildStats(transaction, match.guildBId, scoreB > scoreA, scoreB);

      // Update Players in Guild A
      for (final uid in match.guildAPlayers) {
        _updatePlayerGuildStats(transaction, uid, scoreA > scoreB, match.playerScores[uid] ?? 0);
      }
      // Update Players in Guild B
      for (final uid in match.guildBPlayers) {
        _updatePlayerGuildStats(transaction, uid, scoreB > scoreA, match.playerScores[uid] ?? 0);
      }

      // Clear currentBattleId from guilds
      transaction.update(_db.collection('guilds').doc(match.guildAId), {'currentBattleId': null});
      transaction.update(_db.collection('guilds').doc(match.guildBId), {'currentBattleId': null});

      // Log results
      transaction.set(_db.collection('guildBattleResults').doc(matchId), {
        ...match.toJson(),
        'winningGuildId': winningGuildId,
        'finalScoreA': scoreA,
        'finalScoreB': scoreB,
      });
    });
  }

  void _updateGuildStats(Transaction transaction, String guildId, bool isWin, int score) {
    final guildRef = _db.collection('guilds').doc(guildId);
    final xpGained = (score / 10).floor() + (isWin ? 500 : 100);
    transaction.update(guildRef, {
      'xp': FieldValue.increment(xpGained),
      'weeklyXp': FieldValue.increment(xpGained),
      'weeklyWins': FieldValue.increment(isWin ? 1 : 0),
    });
  }

  void _updatePlayerGuildStats(Transaction transaction, String uid, bool isWin, int score) {
    final userRef = _db.collection('users').doc(uid);
    transaction.update(userRef, {
      'weeklyXp': FieldValue.increment(score),
      'weeklyWins': FieldValue.increment(isWin ? 1 : 0),
      'guildBattlesPlayed': FieldValue.increment(1),
      'guildBattlesWon': FieldValue.increment(isWin ? 1 : 0),
      'totalGuildXpContributed': FieldValue.increment(score),
      'coins': FieldValue.increment(isWin ? 100 : 20),
    });
  }

  Stream<GuildBattleMatchModel?> watchMatch(String matchId) {
    return _db.collection('guildMatches').doc(matchId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GuildBattleMatchModel.fromJson(doc.data()!);
    });
  }

  Future<String?> findMyRoom(String guildBattleId, String uid) async {
    final query = await _db.collection('gameRooms')
        .where('guildBattleId', isEqualTo: guildBattleId)
        .get();
    
    for (var doc in query.docs) {
      final data = doc.data();
      if (data['player1']['uid'] == uid || data['player2']['uid'] == uid) {
        return doc.id;
      }
    }
    return null;
  }

  Future<void> updateSelectedCategory(String guildId, String categoryId, String categoryName) async {
    await _db.collection('guilds').doc(guildId).update({
      'selectedCategoryId': categoryId,
      'selectedCategoryName': categoryName,
    });
  }

  // GUILD INVITATIONS

  Future<void> inviteFriend({
    required String guildId,
    required String guildName,
    required String guildIconId,
    required String senderUid,
    required String senderName,
    required String receiverUid,
  }) async {
    final invitationRef = _db.collection('guildInvitations').doc();
    final invitation = {
      'id': invitationRef.id,
      'guildId': guildId,
      'guildName': guildName,
      'guildIconId': guildIconId,
      'senderUid': senderUid,
      'senderName': senderName,
      'receiverUid': receiverUid,
      'sentAt': FieldValue.serverTimestamp(),
    };
    await invitationRef.set(invitation);
  }

  Stream<List<Map<String, dynamic>>> watchInvitations(String uid) {
    return _db.collection('guildInvitations')
        .where('receiverUid', isEqualTo: uid)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Stream<List<Map<String, dynamic>>> watchGuildSentInvitations(String guildId) {
    return _db.collection('guildInvitations')
        .where('guildId', isEqualTo: guildId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> acceptInvitation(String invitationId, String uid) async {
    final doc = await _db.collection('guildInvitations').doc(invitationId).get();
    if (!doc.exists) return;
    
    final guildId = doc.data()!['guildId'];
    final userDoc = await _db.collection('users').doc(uid).get();
    if (!userDoc.exists) return;

    await _db.runTransaction((transaction) async {
      transaction.update(_db.collection('guilds').doc(guildId), {
        'memberUids': FieldValue.arrayUnion([uid])
      });
      transaction.update(_db.collection('users').doc(uid), {'guildId': guildId});
      transaction.delete(_db.collection('guildInvitations').doc(invitationId));
    });
  }

  Future<void> declineInvitation(String invitationId) async {
    await _db.collection('guildInvitations').doc(invitationId).delete();
  }

  String _generateGuildCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }
}
