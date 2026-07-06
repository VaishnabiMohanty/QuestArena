// WHAT THIS FILE DOES:
// Orchestrates achievement logic and triggers updates based on game events.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../models/achievement_model.dart';
import '../repositories/achievement_repository.dart';
import '../../core/errors/result.dart';
import '../../providers/achievement_providers.dart';
import '../../providers/user_providers.dart';
import '../../core/utils/rank_system.dart';

class AchievementService {
  final AchievementRepository _repository;
  final Ref _ref;

  AchievementService(this._repository, this._ref);

  /// Called when a match is completed.
  Future<void> processMatchEnd({
    required String uid,
    required bool isWin,
    required int correctAnswers,
    required int totalQuestions,
    int? currentWinStreak,
    double? averageAccuracy,
    bool isArenaBreaker = false,
  }) async {
    // 1. Matches Played
    await _updateByType(uid, AchievementType.matchesPlayed, 1);

    // 2. Matches Won
    if (isWin) {
      await _updateByType(uid, AchievementType.matchesWon, 1);
      
      // 5. Win Streak (Always sync against both current and highest for maximum reliability)
      if (currentWinStreak != null && currentWinStreak > 0) {
        await _syncByType(uid, AchievementType.winStreak, currentWinStreak);
      }
      
      // Fetch the updated user profile within the service to get the absolute highest streak
      final userResult = await _ref.read(userRepositoryProvider).getUserProfile(uid);
      if (userResult is Success<UserModel>) {
        await _syncByType(uid, AchievementType.winStreak, userResult.data.highestWinStreak);
      }

      // Arena Breaker Wins
      if (isArenaBreaker) {
        await _updateByType(uid, AchievementType.arenaBreakerWins, 1);
      }
    }

    // 3. Questions Correct
    if (correctAnswers > 0) {
      await _updateByType(uid, AchievementType.questionsCorrect, correctAnswers);
    }
    
    // 4. Perfect Scores
    if (correctAnswers == totalQuestions && totalQuestions > 0) {
      await _updateByType(uid, AchievementType.perfectScores, 1);
    }

    // Accuracy
    if (averageAccuracy != null && averageAccuracy > 0) {
      await _syncByType(uid, AchievementType.accuracy, averageAccuracy.toInt());
    }
  }

  /// Updates progress for login-related achievements.
  Future<void> updateLoginStreakProgress(String uid, int streak) async {
    if (streak >= 1) {
      await _syncByType(uid, AchievementType.loginStreak, streak);
    }
  }

  /// Checks for rank-based achievements.
  Future<void> updateRankProgress(String uid, String rank) async {
    final rankIndex = RankSystem.ranks.indexOf(rank);
    if (rankIndex >= 1) { // 1 is Bronze
      await _syncByType(uid, AchievementType.rankReached, rankIndex);
    }
  }

  /// Updates progress for level-based achievements.
  Future<void> updateLevelProgress(String uid, int level) async {
    if (level >= 1) {
      await _syncByType(uid, AchievementType.levelReached, level);
    }
  }

  /// Syncs all possible achievements based on current user stats.
  Future<void> syncAll(UserModel user) async {
    print('Syncing achievements for user: ${user.uid}');
    print('Stats: wins=${user.wins}, matches=${user.matchesPlayed}, streak=${user.highestWinStreak}');

    // Matches Played
    await _syncByType(user.uid, AchievementType.matchesPlayed, user.matchesPlayed);
    
    // Matches Won
    await _syncByType(user.uid, AchievementType.matchesWon, user.wins);
    
    // Login Streak
    await _syncByType(user.uid, AchievementType.loginStreak, user.loginStreak);
    
    // Win Streak
    await _syncByType(user.uid, AchievementType.winStreak, user.highestWinStreak);
    
    // Rank
    await updateRankProgress(user.uid, user.rank);

    // Level
    await updateLevelProgress(user.uid, user.level);

    // Accuracy
    await _syncByType(user.uid, AchievementType.accuracy, user.averageAccuracy.toInt());

    // Questions Correct
    await _syncByType(user.uid, AchievementType.questionsCorrect, user.totalQuestionsCorrect);

    // Perfect Scores
    await _syncByType(user.uid, AchievementType.perfectScores, user.totalPerfectScores);

    // Arena Breaker Wins
    await _syncByType(user.uid, AchievementType.arenaBreakerWins, user.arenaBreakerWins);
    
    print('Achievement sync complete.');
  }

  Future<Result<void>> claimReward(String uid, String achievementId) async {
    return await _repository.claimAchievementReward(
      uid: uid,
      achievementId: achievementId,
    );
  }

  Future<void> _syncByType(String uid, AchievementType type, int absoluteValue) async {
    final related = achievementDefinitions.where((d) => d['type'] == type).toList();
    
    for (var def in related) {
      final result = await _repository.syncAchievementProgress(
        uid: uid,
        achievementId: def['id'],
        absoluteProgress: absoluteValue,
      );

      if (result is Success<Achievement?>) {
        if (result.data != null) {
          _onAchievementUnlocked(result.data!);
        }
      } else if (result is Failure) {
        print('Error syncing achievement ${def['id']}: ${(result as Failure).error.message}');
      }
    }
  }

  Future<void> _updateByType(String uid, AchievementType type, int increment) async {
    final related = achievementDefinitions.where((d) => d['type'] == type).toList();
    
    for (var def in related) {
      final result = await _repository.updateAchievementProgress(
        uid: uid,
        achievementId: def['id'],
        increment: increment,
      );

      if (result is Success<Achievement?>) {
        if (result.data != null) {
          _onAchievementUnlocked(result.data!);
        }
      }
    }
  }

  void _onAchievementUnlocked(Achievement achievement) {
    // Update the state provider to trigger the popup in the UI
    _ref.read(lastUnlockedAchievementProvider.notifier).state = achievement;
  }
}
