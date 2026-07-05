import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questarena/core/errors/result.dart';
import 'package:questarena/data/models/user_model.dart';
import 'package:questarena/data/models/match_history_model.dart';
import 'package:questarena/data/services/firestore_service.dart';
import 'package:questarena/core/utils/level_system.dart';
import 'package:questarena/core/utils/rank_system.dart';
import 'package:questarena/core/utils/rank_calculator.dart';

class UserRepository {
  final FirestoreService _service;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserRepository(this._service);

  Future<Result<UserModel>> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return Success(UserModel.fromJson(doc.data()!));
      } else {
        return const Failure(UnknownError('User profile not found'));
      }
    } catch (e) {
      return Failure(UnknownError(e.toString()));
    }
  }

  Stream<UserModel?> watchUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return UserModel.fromJson(snapshot.data()!);
      }
      return null;
    });
  }

  Future<void> createUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toJson());
  }

  Future<void> updateUserProfile(UserModel user) async {
    await _db.collection('users').doc(user.uid).set(user.toJson(), SetOptions(merge: true));
  }

  Future<void> deleteUserProfile(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  Stream<List<MatchModel>> watchMatchHistory(String uid, {int limit = 20}) {
    return _db.collection('users').doc(uid).collection('matchHistory')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => MatchModel.fromJson(doc.data())).toList());
  }

  Future<void> processMatchEnd({
    required String uid,
    required bool isWin,
    required bool isDraw,
    required int playerScore,
    required int opponentScore,
    required String opponentId,
    required String opponentName,
    required String? opponentAvatar,
    required bool isRanked,
    required bool rankProtectionActive,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    
    await _db.runTransaction((transaction) async {
      final userDoc = await transaction.get(userRef);
      if (!userDoc.exists) return;
      
      final user = UserModel.fromJson(userDoc.data()!);
      
      // Calculate XP
      int xpEarned = isWin ? 50 : (isDraw ? 25 : 15);
      xpEarned += (playerScore ~/ 10) * 2; // Bonus for score
      
      final totalXp = user.xp + xpEarned;
      final newLevel = LevelSystem.getCurrentLevel(totalXp);
      
      // Stats
      int newWins = user.wins;
      int newLosses = user.losses;
      int newDraws = user.draws;
      int newStreak = user.currentWinStreak;
      int highestStreak = user.highestWinStreak;
      
      if (isWin) {
        newWins++;
        newStreak++;
        if (newStreak > highestStreak) highestStreak = newStreak;
      } else if (isDraw) {
        newDraws++;
        newStreak = 0;
      } else {
        newLosses++;
        newStreak = 0;
      }
      
      // Rank Points
      int rankPointsGained = 0;
      if (isRanked) {
        rankPointsGained = isWin ? 20 : (isDraw ? 5 : -15);
      }
      
      int remainingProtection = user.rankProtectionMatches;
      if (isRanked && !isWin && !isDraw && rankProtectionActive && remainingProtection > 0) {
        rankPointsGained = 0; // Prevent loss
        remainingProtection--;
      }

      int newRankPoints = user.rankPoints + rankPointsGained;
      String newRank = user.rank;
      int? newSubRank = user.subRank;
      
      final rankResult = RankCalculator.calculateNewRank(newRank, newSubRank, newRankPoints);
      newRank = rankResult.rank;
      newSubRank = rankResult.subRank;
      newRankPoints = rankResult.remainingPoints;

      transaction.update(userRef, {
        'xp': totalXp,
        'level': newLevel,
        'wins': newWins,
        'losses': newLosses,
        'draws': newDraws,
        'currentWinStreak': newStreak,
        'highestWinStreak': highestStreak,
        'rank': newRank,
        'subRank': newSubRank,
        'rankPoints': newRankPoints,
        'coins': user.coins + (isWin ? 20 : (isDraw ? 10 : 5)),
        'rankProtectionMatches': remainingProtection,
        'rankProtectionActive': remainingProtection > 0 ? user.rankProtectionActive : false,
      });

      // Match History
      final matchRef = userRef.collection('matchHistory').doc();
      transaction.set(matchRef, {
        'opponentId': opponentId,
        'opponentName': opponentName,
        'opponentAvatarUrl': opponentAvatar,
        'playerScore': playerScore,
        'opponentScore': opponentScore,
        'xpEarned': xpEarned,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }
}
