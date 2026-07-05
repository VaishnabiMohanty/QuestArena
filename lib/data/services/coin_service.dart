import '../models/user_model.dart';
import '../repositories/coin_repository.dart';
import '../../core/errors/result.dart';
import '../../core/errors/app_error.dart';

class CoinService {
  final CoinRepository _repository;

  CoinService(this._repository);

  /// Automatically rewards coins based on match results (Win: 20, Loss: 5, Draw: 10).
  /// Enforces daily limit and duplicate protection.
  Future<Result<void>> rewardCoins({
    required String uid,
    required String matchId,
    required String result, // 'win', 'loss', 'draw'
  }) async {
    int amount = 0;
    switch (result) {
      case 'win': amount = 20; break;
      case 'loss': amount = 5; break;
      case 'draw': amount = 10; break;
    }

    return await _repository.updateCoinsTransaction(
      uid: uid,
      amount: amount,
      isMatchReward: true,
      matchId: matchId,
    );
  }

  /// Manually add coins (e.g., from an admin action or special event).
  Future<Result<void>> addCoins(String uid, int amount) async {
    return await _repository.updateCoinsTransaction(uid: uid, amount: amount);
  }

  /// Spend coins on items. Prevents negative balances.
  Future<Result<void>> spendCoins(String uid, int price) async {
    return await _repository.updateCoinsTransaction(uid: uid, amount: -price);
  }

  /// Checks if the user has enough coins for a purchase.
  bool canPurchase(int balance, int price) => balance >= price;

  /// Returns the current coin balance.
  int getCurrentBalance(UserModel user) => user.coins;

  /// Logic for the 7-day Daily Login System.
  Future<Result<int>> claimDailyReward(UserModel user) async {
    final now = DateTime.now();
    final lastClaim = user.lastDailyLoginRewardDate;

    // Already claimed today
    if (now.day == lastClaim.day && now.month == lastClaim.month && now.year == lastClaim.year) {
      return const Failure<int>(DatabaseError("Daily reward already claimed"));
    }

    // Check streak: If last claim was yesterday, increment. Otherwise reset.
    final yesterday = now.subtract(const Duration(days: 1));
    bool isConsecutive = yesterday.day == lastClaim.day && 
                         yesterday.month == lastClaim.month && 
                         yesterday.year == lastClaim.year;

    int newStreak = isConsecutive ? (user.loginStreak % 7) + 1 : 1;
    int rewardAmount = _getDailyRewardAmount(newStreak);

    final txResult = await _repository.claimDailyRewardTransaction(
      uid: user.uid,
      amount: rewardAmount,
      newStreak: newStreak,
    );

    if (txResult is Success) {
      return Success(rewardAmount);
    } else {
      return Failure((txResult as Failure).error);
    }
  }

  int _getDailyRewardAmount(int day) {
    const rewards = [20, 30, 40, 50, 60, 80, 100];
    return rewards[(day - 1).clamp(0, 6)];
  }

  /// Rewards coins based on the user's league once per season.
  Future<Result<void>> rewardLeagueCoins(String uid, String league, String seasonId) async {
    int amount = 0;
    switch (league) {
      case 'Bronze': amount = 100; break;
      case 'Silver': amount = 250; break;
      case 'Gold': amount = 500; break;
      case 'Platinum': amount = 1000; break;
      case 'Diamond': amount = 2000; break;
    }

    return await _repository.updateCoinsTransaction(
      uid: uid,
      amount: amount,
      isLeagueReward: true,
      leagueRewardKey: '${league}_$seasonId',
    );
  }

  /// Forces a reset of the daily coin limit (admin or test utility).
  Future<Result<void>> resetDailyCoinLimit(String uid) async {
    return await _repository.updateCoinsTransaction(
      uid: uid, 
      amount: 0, 
      lastCoinResetDate: DateTime(2000), // Setting to past triggers reset
    );
  }
}
