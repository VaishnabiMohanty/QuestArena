import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:questarena/core/errors/result.dart';
import 'package:questarena/core/errors/app_error.dart';
import 'package:questarena/data/models/user_model.dart';
import 'package:questarena/data/models/match_history_model.dart';
import 'package:questarena/data/services/firestore_service.dart';
import 'package:questarena/core/utils/level_system.dart';
import 'package:questarena/core/utils/rank_calculator.dart';

/// Repository responsible for user profile management and post-match data processing.
class UserRepository {
  final FirestoreService _service;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  UserRepository(this._service);

  /// Fetches the user profile from Firestore.
  /// Returns a [Result] containing [UserModel] on success or [AppError] on failure.
  Future<Result<UserModel>> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return Success(UserModel.fromJson(doc.data()!));
      } else {
        return const Failure(DatabaseError('User profile not found.'));
      }
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return Failure(UnknownError(e.toString()));
    }
  }

  /// Provides a real-time stream of the user profile for a given [uid].
  Stream<UserModel?> watchUserProfile(String uid) {
    return _db.collection('users').doc(uid).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (snapshot.exists && data != null) {
        return UserModel.fromJson(data);
      }
      return null;
    });
  }

  /// Creates a new user profile document.
  Future<Result<void>> createUserProfile(UserModel user) async {
    try {
      await _service.setData(
        path: 'users/${user.uid}',
        data: user.toJson(),
        merge: false,
      );
      return const Success(null);
    } catch (e) {
      debugPrint('Error creating user profile: $e');
      return Failure(DatabaseError(e.toString()));
    }
  }

  /// Updates specific fields in the user profile.
  Future<Result<void>> updateUserProfile(UserModel user) async {
    try {
      await _service.setData(
        path: 'users/${user.uid}',
        data: user.toJson(),
      );
      return const Success(null);
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return Failure(DatabaseError(e.toString()));
    }
  }

  /// Deletes the user profile.
  Future<Result<void>> deleteUserProfile(String uid) async {
    try {
      await _service.deleteData('users/$uid');
      return const Success(null);
    } catch (e) {
      debugPrint('Error deleting user profile: $e');
      return Failure(DatabaseError(e.toString()));
    }
  }

  /// Streams the match history for a user, sorted by newest first.
  Stream<List<MatchModel>> watchMatchHistory(String uid, {int limit = 20}) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('matchHistory')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id; // Ensure the ID is present for the model
              return MatchModel.fromJson(data);
            }).toList());
  }

  /// Processes all updates related to a match ending (XP, Rank, Coins, Stats).
  /// This operation is performed in a transaction to ensure atomicity.
  Future<Result<void>> processMatchEnd({
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
    int? opponentElo,
    bool isArenaBreaker = false,
  }) async {
    try {
      final userRef = _db.collection('users').doc(uid);

      await _db.runTransaction((transaction) async {
        final userDoc = await transaction.get(userRef);
        final userData = userDoc.data();
        if (userData == null) return;

        final user = UserModel.fromJson(userData);

        // 1. XP Calculation
        int xpEarned = isWin ? 50 : (isDraw ? 25 : 15);
        xpEarned += (playerScore ~/ 10) * 2; // Bonus XP for correct answers

        final int totalXp = user.xp + xpEarned;
        final int newLevel = LevelSystem.getCurrentLevel(totalXp);

        // 2. Statistics Updates
        int newWins = user.wins;
        int newLosses = user.losses;
        int newDraws = user.draws;
        int newStreak = user.currentWinStreak;
        int highestStreak = user.highestWinStreak;
        int abWins = user.arenaBreakerWins;
        int abLosses = user.arenaBreakerLosses;

        if (isWin) {
          newWins++;
          newStreak++;
          if (newStreak > highestStreak) highestStreak = newStreak;
          if (isArenaBreaker) abWins++;
        } else if (isDraw) {
          newDraws++;
          newStreak = 0;
        } else {
          newLosses++;
          newStreak = 0;
          if (isArenaBreaker) abLosses++;
        }

        // 3. Rank Points & Promotion Logic
        int rankPointsGained = 0;
        int remainingProtection = user.rankProtectionMatches;

        if (isRanked) {
          rankPointsGained = isWin ? 20 : (isDraw ? 5 : -15);
          
          // Apply Rank Protection if losing/drawing (optional, here losing only)
          if (!isWin && !isDraw && rankProtectionActive && remainingProtection > 0) {
            rankPointsGained = 0;
            remainingProtection--;
          }
        }

        int proposedPoints = user.rankPoints + rankPointsGained;
        final rankResult = RankCalculator.calculateNewRank(
          user.rank,
          user.subRank,
          proposedPoints,
        );

        // 4. Elo Calculation
        int newElo = user.eloRating;
        if (isRanked) {
          newElo = _calculateElo(user.eloRating, opponentElo ?? 1200, isWin, isDraw);
        }

        // 5. Coins & Daily Reset Logic
        final now = DateTime.now();
        final lastReset = user.lastCoinResetDate;
        final bool isNewDay = now.year != lastReset.year || 
                             now.month != lastReset.month || 
                             now.day != lastReset.day;
        
        int todayCoins = isNewDay ? 0 : user.todayCoinsEarned;
        int coinReward = isWin ? 20 : (isDraw ? 10 : 5);
        
        const int dailyCoinCap = 500;
        if (todayCoins + coinReward > dailyCoinCap) {
          coinReward = math.max(0, dailyCoinCap - todayCoins);
        }

        // 6. Weekly Progress
        int weeklyWins = user.weeklyWins + (isWin ? 1 : 0);
        int weeklyXp = user.weeklyXp + xpEarned;
        int weeklyMatches = user.weeklyMatchesPlayed + 1;

        // Perform atomic update
        transaction.update(userRef, {
          'xp': totalXp,
          'level': newLevel,
          'wins': newWins,
          'losses': newLosses,
          'draws': newDraws,
          'currentWinStreak': newStreak,
          'highestWinStreak': highestStreak,
          'rank': rankResult.rank,
          'subRank': rankResult.subRank,
          'rankPoints': rankResult.remainingPoints,
          'eloRating': newElo,
          'coins': user.coins + coinReward,
          'todayCoinsEarned': todayCoins + coinReward,
          'lastCoinResetDate': Timestamp.fromDate(now),
          'rankProtectionMatches': remainingProtection,
          'rankProtectionActive': remainingProtection > 0 && user.rankProtectionActive,
          'weeklyWins': weeklyWins,
          'weeklyXp': weeklyXp,
          'weeklyMatchesPlayed': weeklyMatches,
          'arenaBreakerWins': abWins,
          'arenaBreakerLosses': abLosses,
          'totalQuestionsCorrect': user.totalQuestionsCorrect + (playerScore ~/ 10),
          'totalPerfectScores': user.totalPerfectScores + (playerScore >= 50 ? 1 : 0),
        });

        // 7. Match History Record
        final matchRef = userRef.collection('matchHistory').doc();
        transaction.set(matchRef, {
          'id': matchRef.id,
          'opponentId': opponentId,
          'opponentName': opponentName,
          'opponentAvatarUrl': opponentAvatar,
          'playerScore': playerScore,
          'opponentScore': opponentScore,
          'xpEarned': xpEarned,
          'timestamp': FieldValue.serverTimestamp(),
          'isRanked': isRanked,
          'isArenaBreaker': isArenaBreaker,
          'rankPointsGained': rankPointsGained,
          'eloGained': newElo - user.eloRating,
        });
      });
      return const Success(null);
    } catch (e, stack) {
      debugPrint('processMatchEnd fatal error: $e\n$stack');
      return Failure(DatabaseError(e.toString()));
    }
  }

  /// Standard Elo calculation.
  int _calculateElo(int currentElo, int opponentElo, bool isWin, bool isDraw) {
    const kFactor = 32;
    final double expectedScore = 1 / (1 + math.pow(10, (opponentElo - currentElo) / 400));
    final double actualScore = isWin ? 1.0 : (isDraw ? 0.5 : 0.0);
    return currentElo + (kFactor * (actualScore - expectedScore)).round();
  }
}
