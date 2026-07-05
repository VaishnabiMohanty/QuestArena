import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../repositories/streak_repository.dart';
import '../../core/errors/result.dart';
import '../../providers/achievement_providers.dart';

class StreakService {
  final StreakRepository _repository;
  final Ref _ref;

  StreakService(this._repository, this._ref);

  /// Logic to handle daily login streak.
  Future<Result<int>> checkAndUpdateLoginStreak(UserModel user) async {
    final now = DateTime.now();
    final lastLogin = user.lastLoginDate;

    // 1. Check if already processed today
    if (now.day == lastLogin.day && now.month == lastLogin.month && now.year == lastLogin.year) {
      return const Success(0); // Already logged in today
    }

    // 2. Check if it's consecutive (yesterday)
    final yesterday = now.subtract(const Duration(days: 1));
    bool isConsecutive = yesterday.day == lastLogin.day && 
                         yesterday.month == lastLogin.month && 
                         yesterday.year == lastLogin.year;

    // 3. Calculate new streak
    int newStreak = isConsecutive ? user.loginStreak + 1 : 1;
    bool shouldReward = newStreak % 7 == 0; // Reward every 7 days

    final result = await _repository.processLoginStreakTransaction(
      uid: user.uid,
      newStreak: newStreak,
      shouldReward: shouldReward,
      rewardAmount: 200,
    );

    if (result is Success<int>) {
      // Trigger achievement check with the ACTUAL streak (before possible reset to 0)
      _ref.read(achievementServiceProvider).updateLoginStreakProgress(user.uid, newStreak);
    }

    return result;
  }

  /// Logic to handle win streak after a match.
  Future<Result<int>> updateWinStreak({
    required String uid,
    required bool isWin,
  }) async {
    return await _repository.processWinStreakTransaction(
      uid: uid,
      isWin: isWin,
      rewardThreshold: 3,
      rewardAmount: 100,
    );
  }
}
