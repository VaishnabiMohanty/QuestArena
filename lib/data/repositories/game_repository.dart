import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/models/quiz_category.dart';
import '../../core/utils/game_utils.dart';
import '../models/game_room_model.dart';

class GameRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Dio _dio;

  GameRepository(this._dio);

  Future<List<Map<String, dynamic>>> fetchQuestions(int amount) async {
    try {
      final response = await _dio.get(
        ApiConstants.triviaBaseUrl,
        queryParameters: {
          'amount': amount,
          'type': 'multiple',
        },
      );
      if (response.statusCode == 200 && response.data['results'] != null) {
        return (response.data['results'] as List).map((q) => {
          'question': GameUtils.decodeHtmlEntities(q['question']),
          'correct_answer': GameUtils.decodeHtmlEntities(q['correct_answer']),
          'incorrect_answers': (q['incorrect_answers'] as List)
              .map((a) => GameUtils.decodeHtmlEntities(a))
              .toList(),
        }).toList();
      }
      throw Exception("Invalid response from trivia API");
    } catch (e) {
      final allFallbacks = GameUtils.getFallbackQuestions();
      return allFallbacks.take(amount).toList();
    }
  }

  Future<String> createPrivateRoom(
    Map<String, dynamic> player1Data,
    String code,
    QuizCategory category,
  ) async {
    final roomId = _db.collection('gameRooms').doc().id;

    List<Map<String, dynamic>> questions = [];
    try {
      final response = await _dio.get(ApiConstants.triviaUrlForCategory(category.id));
      questions = (response.data['results'] as List).map((q) => {
        'question': GameUtils.decodeHtmlEntities(q['question']),
        'correct_answer': GameUtils.decodeHtmlEntities(q['correct_answer']),
        'incorrect_answers': (q['incorrect_answers'] as List)
            .map((a) => GameUtils.decodeHtmlEntities(a))
            .toList(),
      }).toList();
    } catch (e) {
      debugPrint("Trivia API Error: $e");
      questions = GameUtils.getFallbackQuestions();
    }

    await _db.collection('gameRooms').doc(roomId).set({
      'roomId': roomId,
      'roomCode': code,
      'categoryId': category.id,
      'categoryName': category.name,
      'status': 'waiting',
      'isRanked': false,
      'player1': {...player1Data, 'isReady': false, 'score': 0, 'answers': []},
      'player2': null,
      'createdAt': FieldValue.serverTimestamp(),
      'questions': questions,
    });
    return roomId;
  }

  Future<String?> joinPrivateRoom(Map<String, dynamic> player2Data, String code) async {
    final query = await _db
        .collection('gameRooms')
        .where('roomCode', isEqualTo: code)
        .limit(1)
        .get();

    if (query.docs.isEmpty) return null;

    final doc = query.docs.first;
    final status = doc.get('status');

    if (status != 'waiting' && status != 'fetching_questions') return null;

    await doc.reference.update({
      'player2': {...player2Data, 'isReady': false, 'score': 0, 'answers': []},
      'status': 'active',
    });

    return doc.id;
  }

  Stream<GameRoomModel?> watchRoom(String roomId) {
    return _db.collection('gameRooms').doc(roomId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return GameRoomModel.fromJson(doc.data()!);
    });
  }

  Future<void> setPlayerReady(String roomId, int playerNumber, String userId) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'player$playerNumber.isReady': true,
    });
  }

  Future<void> startGame(String roomId) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'status': 'active',
      'questionStartedAt': FieldValue.serverTimestamp(),
      'currentQuestionIndex': 0,
    });
  }

  Future<void> submitAnswer({
    required String roomId,
    required String userId,
    required int playerNumber,
    required String answer,
    required int scoreIncrement,
  }) async {
    final roomRef = _db.collection('gameRooms').doc(roomId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;
      final playerKey = 'player$playerNumber';
      final currentIdx = data['currentQuestionIndex'] ?? 0;
      final questions = List<dynamic>.from(data['questions'] ?? []);

      final playerAnswers = List<String>.from(data[playerKey]['answers'] ?? []);

      while (playerAnswers.length < currentIdx) {
        playerAnswers.add("TIMEOUT");
      }

      if (playerAnswers.length == currentIdx) {
        playerAnswers.add(answer);
        final player1 = data['player1'];
        final player2 = data['player2'];
        final opponentId = playerNumber == 1
            ? (player2 == null ? null : player2['uid'])
            : (player1 == null ? null : player1['uid']);
        final powerups = Map<String, dynamic>.from(data['powerups'] ?? {});
        final shieldBlocks = Map<String, dynamic>.from(
          powerups['shieldBonusBlocks'] ?? {},
        );
        final opponentShield = opponentId == null
            ? null
            : Map<String, dynamic>.from(shieldBlocks[opponentId] ?? {});
        final shieldBlocksBonus = opponentShield?['questionIndex'] == currentIdx;
        final effectiveScore =
            shieldBlocksBonus && scoreIncrement > 10 ? 10 : scoreIncrement;
        final newScore = (data[playerKey]['score'] ?? 0) + effectiveScore;

        transaction.update(roomRef, {
          '$playerKey.answers': playerAnswers,
          '$playerKey.score': newScore,
        });
      }

      final p1Len = playerNumber == 1 ? playerAnswers.length : (data['player1']['answers'] as List).length;
      final p2Len = playerNumber == 2 ? playerAnswers.length : (data['player2']['answers'] as List).length;

      if (p1Len > currentIdx && p2Len > currentIdx) {
        _advanceOrFinishInTransaction(transaction, roomRef, data, currentIdx, questions);
      }
    });
  }

  void _advanceOrFinishInTransaction(Transaction transaction, DocumentReference roomRef, Map<String, dynamic> data, int currentIdx, List<dynamic> questions) {
    if (currentIdx + 1 < questions.length) {
      transaction.update(roomRef, {
        'currentQuestionIndex': currentIdx + 1,
        'questionStartedAt': FieldValue.serverTimestamp(),
      });
    } else {
      final p1 = data['player1'];
      final p2 = data['player2'];
      final p1Score = p1['score'] ?? 0;
      final p2Score = p2['score'] ?? 0;

      if (p1Score == p2Score) {
        transaction.update(roomRef, {
          'status': 'arena_breaker',
          'isArenaBreaker': true,
          'arenaBreakerRound': 1,
          'questionStartedAt': FieldValue.serverTimestamp(),
          'arenaBreakerQuestion': null,
          'arenaBreakerSubmissions': {},
          'arenaBreakerStatusMessage': 'Preparing Sudden Death...',
        });
        _fetchArenaBreakerQuestion(roomRef.id, 1, categoryId: data['categoryId']);
      } else {
        transaction.update(roomRef, {
          'status': 'finished',
          'winnerId': p1Score > p2Score ? p1['uid'] : p2['uid'],
        });
      }
    }
  }

  Future<void> activateShieldBonusBlock({
    required String roomId,
    required String userId,
    required int questionIndex,
  }) async {
    final roomRef = _db.collection('gameRooms').doc(roomId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;
      if (data['status'] != 'active') return;
      if ((data['currentQuestionIndex'] ?? -1) != questionIndex) return;

      final p1 = data['player1'];
      final p2 = data['player2'];
      if (p1?['uid'] != userId && p2?['uid'] != userId) return;

      final powerups = Map<String, dynamic>.from(data['powerups'] ?? {});
      final shieldBlocks = Map<String, dynamic>.from(
        powerups['shieldBonusBlocks'] ?? {},
      );
      if (shieldBlocks.containsKey(userId)) return;

      transaction.update(roomRef, {
        'powerups.shieldBonusBlocks.$userId': {
          'questionIndex': questionIndex,
          'activatedAt': FieldValue.serverTimestamp(),
        },
      });
    });
  }

  Future<void> forceAdvanceQuestion(String roomId, int fromIndex) async {
    final roomRef = _db.collection('gameRooms').doc(roomId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;
      final currentIdx = data['currentQuestionIndex'] ?? 0;
      final status = data['status'];

      if (status == 'active' && currentIdx == fromIndex) {
        final questions = List<dynamic>.from(data['questions'] ?? []);
        _advanceOrFinishInTransaction(transaction, roomRef, data, currentIdx, questions);
      }
    });
  }

  Future<void> _fetchArenaBreakerQuestion(String roomId, int round, {int? categoryId}) async {
    final roomRef = _db.collection('gameRooms').doc(roomId);

    final snap = await roomRef.get();
    if (!snap.exists) return;
    final data = snap.data() as Map<String, dynamic>;
    if ((data['arenaBreakerQuestion'] != null || data['arenaBreakerStatusMessage'] == 'Fetching...') && (data['arenaBreakerRound'] == round)) {
      return;
    }

    await roomRef.update({'arenaBreakerStatusMessage': 'Fetching...'});

    try {
      final url = categoryId != null ? ApiConstants.triviaUrlForCategory(categoryId) : ApiConstants.triviaUrl;
      final response = await _dio.get(url, queryParameters: {'amount': 1});
      final q = (response.data['results'] as List).first;
      final questionMap = {
        'question': GameUtils.decodeHtmlEntities(q['question']),
        'correct_answer': GameUtils.decodeHtmlEntities(q['correct_answer']),
        'incorrect_answers': (q['incorrect_answers'] as List).map((a) => GameUtils.decodeHtmlEntities(a)).toList(),
      };

      await roomRef.update({
        'arenaBreakerQuestion': questionMap,
        'arenaBreakerSubmissions': {},
        'arenaBreakerRound': round,
        'arenaBreakerStatusMessage': null,
        'questionStartedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      await roomRef.update({
        'arenaBreakerQuestion': GameUtils.getFallbackQuestions().first,
        'arenaBreakerSubmissions': {},
        'arenaBreakerRound': round,
        'arenaBreakerStatusMessage': null,
        'questionStartedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> submitArenaBreakerAnswer({
    required String roomId,
    required String userId,
    required String answer,
  }) async {
    final roomRef = _db.collection('gameRooms').doc(roomId);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;
      if (data['status'] == 'finished') return;

      final question = data['arenaBreakerQuestion'];
      final currentRound = data['arenaBreakerRound'] ?? 0;

      if (question == null) return;

      final submissions = Map<String, dynamic>.from(data['arenaBreakerSubmissions'] ?? {});
      if (submissions.containsKey(userId)) return;

      final isCorrect = answer == question['correct_answer'];
      submissions[userId] = {
        'answer': answer,
        'isCorrect': isCorrect,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };

      transaction.update(roomRef, {'arenaBreakerSubmissions': submissions});

      final p1 = data['player1'];
      final p2 = data['player2'];
      final s1 = submissions[p1['uid']];
      final s2 = submissions[p2['uid']];

      String? winnerId;

      if (s1 != null && s1['isCorrect'] && (s2 == null || !s2['isCorrect'])) {
        winnerId = p1['uid'];
      } else if (s2 != null && s2['isCorrect'] && (s1 == null || !s1['isCorrect'])) {
        winnerId = p2['uid'];
      }
      else if (s1 != null && s2 != null && s1['isCorrect'] && s2['isCorrect']) {
        winnerId = (s1['timestamp'] < s2['timestamp']) ? p1['uid'] : p2['uid'];
      }
      else if (s1 != null && s2 != null && !s1['isCorrect'] && !s2['isCorrect']) {
        transaction.update(roomRef, {
          'arenaBreakerStatusMessage': 'Both Incorrect! Next Round...',
          'arenaBreakerQuestion': null,
        });
        _scheduleNextABRound(roomId, currentRound + 1, categoryId: data['categoryId']);
        return;
      }

      if (winnerId != null) {
        transaction.update(roomRef, {
          'status': 'finished',
          'winnerId': winnerId,
          'isArenaBreakerWin': true,
        });
      }
    });
  }

  void _scheduleNextABRound(String roomId, int nextRound, {int? categoryId}) {
    Future.delayed(const Duration(seconds: 3), () => _fetchArenaBreakerQuestion(roomId, nextRound, categoryId: categoryId));
  }

  Future<void> updatePresence(String roomId, String userId, bool isOnline) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'presence.$userId': {
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      },
    });
  }

  Future<void> handleForfeit(String roomId, String winnerId) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'status': 'finished',
      'winnerId': winnerId,
      'forfeitWinnerId': winnerId,
    });
  }

  Future<void> leaveMatch(String roomId, String userId, String opponentId) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'status': 'finished',
      'winnerId': opponentId,
      'forfeitWinnerId': opponentId,
    });
  }

  Future<GameRoomModel?> findActiveMatch(String uid) async {
    final tenMinAgo = DateTime.now().subtract(const Duration(minutes: 10));
    final query = await _db
        .collection('gameRooms')
        .where('status', whereIn: ['active', 'arena_breaker'])
        .where('createdAt', isGreaterThan: Timestamp.fromDate(tenMinAgo))
        .get();

    for (var doc in query.docs) {
      final data = doc.data();
      if (data['player1']['uid'] == uid || data['player2']?['uid'] == uid) {
        return GameRoomModel.fromJson(data);
      }
    }
    return null;
  }

  Future<void> useLifeline({
    required String userId,
    required String lifelineType,
  }) async {
    final userRef = _db.collection('users').doc(userId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final field = lifelineType == 'oneOption' ? 'oneOptionLifelines' : 'twoOptionLifelines';
      final currentCount = snapshot.data()![field] ?? 0;

      if (currentCount > 0) {
        transaction.update(userRef, {
          field: FieldValue.increment(-1),
        });
      } else {
        throw Exception('No lifelines remaining');
      }
    });
  }

  Future<void> useRankProtection(String userId) async {
    final userRef = _db.collection('users').doc(userId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final currentCount = snapshot.data()?['rankProtectionMatches'] ?? 0;

      if (currentCount > 0) {
        transaction.update(userRef, {
          'rankProtectionMatches': FieldValue.increment(-1),
        });
      }
    });
  }

  Future<void> activateRankProtectionForMatch(String roomId, int playerNumber, bool active) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'player$playerNumber.rankProtectionActive': active,
    });
  }

  Future<void> claimRewards(String roomId, String userId, bool isWin) async {
    final roomRef = _db.collection('gameRooms').doc(roomId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(roomRef);
      if (!snapshot.exists) return;

      final data = snapshot.data();
      if (data == null) return;

      final claimedList = List<String>.from(data['claimedRewards'] ?? []);

      if (claimedList.contains(userId)) return;

      claimedList.add(userId);
      transaction.update(roomRef, {'claimedRewards': claimedList});
    });
  }

  Future<void> sendEmoji(String roomId, int playerNumber, String emoji) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'player${playerNumber}Emoji': emoji,
    });

    Future.delayed(const Duration(seconds: 3), () async {
      await _db.collection('gameRooms').doc(roomId).update({
        'player${playerNumber}Emoji': FieldValue.delete(),
      });
    });
  }

  Future<void> usePowerUp(String uid, String powerUpType) async {
    final userRef = _db.collection('users').doc(uid);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final powerUps = Map<String, dynamic>.from(snapshot.get('powerUps') ?? {});
      final currentCount = powerUps[powerUpType] ?? 0;

      if (currentCount > 0) {
        powerUps[powerUpType] = currentCount - 1;
        transaction.update(userRef, {'powerUps': powerUps});
      }
    });
  }

  Future<void> requestRematch(String roomId, String userId) async {
    await _db.collection('gameRooms').doc(roomId).update({
      'rematchRequests': FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> createRematchGame({
    required String oldRoomId,
    required Map<String, dynamic> player1,
    required Map<String, dynamic> player2,
    required int? categoryId,
    required String categoryName,
    bool isRanked = true,
  }) async {
    final newRoomId = _db.collection('gameRooms').doc().id;
    List<Map<String, dynamic>> questions = [];
    try {
      final response = await _dio.get(ApiConstants.triviaUrlForCategory(categoryId));
      questions = (response.data['results'] as List).map((q) => {
        'question': GameUtils.decodeHtmlEntities(q['question']),
        'correct_answer': GameUtils.decodeHtmlEntities(q['correct_answer']),
        'incorrect_answers': (q['incorrect_answers'] as List).map((a) => GameUtils.decodeHtmlEntities(a)).toList(),
      }).toList();
    } catch (e) {
      questions = GameUtils.getFallbackQuestions();
    }

    Map<String, dynamic> resetPlayer(Map<String, dynamic> p) {
      final newP = Map<String, dynamic>.from(p);
      newP['score'] = 0;
      newP['answers'] = [];
      newP['isReady'] = false;
      return newP;
    }

    final batch = _db.batch();
    batch.set(_db.collection('gameRooms').doc(newRoomId), {
      'roomId': newRoomId,
      'roomCode': '',
      'categoryId': categoryId,
      'categoryName': categoryName,
      'status': 'active',
      'isRanked': isRanked,
      'player1': resetPlayer(player1),
      'player2': resetPlayer(player2),
      'createdAt': FieldValue.serverTimestamp(),
      'questions': questions,
      'questionStartedAt': FieldValue.serverTimestamp(),
    });
    batch.update(_db.collection('gameRooms').doc(oldRoomId), {'nextMatchId': newRoomId});
    await batch.commit();
  }
}
