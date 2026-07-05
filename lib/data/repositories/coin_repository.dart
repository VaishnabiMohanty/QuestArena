import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../models/user_model.dart';

class CoinRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Handles all coin-related updates via Firestore transactions to ensure data integrity.
  Future<Result<void>> updateCoinsTransaction({
    required String uid,
    required int amount,
    bool isMatchReward = false,
    String? matchId,
    bool isDailyBonus = false,
    bool isLeagueReward = false,
    String? leagueRewardKey,
    DateTime? lastCoinResetDate,
  }) async {
    try {
      final userRef = _db.collection('users').doc(uid);

      return await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return const Failure(DatabaseError("User not found"));

        final user = UserModel.fromJson(snapshot.data() as Map<String, dynamic>);

        // 1. Prevent duplicate match rewards
        if (isMatchReward && matchId != null && user.lastRewardedMatchId == matchId) {
          return const Success(null);
        }

        // 2. Prevent duplicate league rewards
        if (isLeagueReward && leagueRewardKey != null && user.lastLeagueRewardClaimed == leagueRewardKey) {
          return const Failure(DatabaseError("League reward already claimed"));
        }

        int currentCoins = user.coins;
        int todayEarned = user.todayCoinsEarned;
        DateTime lastReset = lastCoinResetDate ?? user.lastCoinResetDate;
        final now = DateTime.now();

        // 3. Reset daily limit if it's a new day
        final isNewDay = now.day != lastReset.day || now.month != lastReset.month || now.year != lastReset.year;
        if (isNewDay) {
          todayEarned = 0;
          lastReset = now;
        }

        int finalReward = amount;

        // 4. Enforce 500 coin daily limit for matches
        if (isMatchReward && amount > 0) {
          const int dailyLimit = 500;
          if (todayEarned >= dailyLimit) {
            finalReward = 0;
          } else if (todayEarned + amount > dailyLimit) {
            finalReward = dailyLimit - todayEarned;
          }
          todayEarned += finalReward;
        }

        // 5. Apply changes
        currentCoins += finalReward;

        if (currentCoins < 0) return const Failure(DatabaseError("Insufficient balance"));

        final Map<String, dynamic> updates = {
          'coins': currentCoins,
          'todayCoinsEarned': todayEarned,
          'lastCoinResetDate': lastReset,
        };

        if (isMatchReward && matchId != null) updates['lastRewardedMatchId'] = matchId;
        if (isDailyBonus) updates['lastDailyLoginRewardDate'] = now;
        if (isLeagueReward) updates['lastLeagueRewardClaimed'] = leagueRewardKey;

        transaction.update(userRef, updates);
        return const Success(null);
      });
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  /// Specialized transaction for the 7-day login system to handle streak logic safely.
  Future<Result<void>> claimDailyRewardTransaction({
    required String uid,
    required int amount,
    required int newStreak,
  }) async {
    try {
      final userRef = _db.collection('users').doc(uid);

      return await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return const Failure(DatabaseError("User not found"));

        final data = snapshot.data()!;
        final lastClaim = data['lastDailyLoginRewardDate'] != null 
            ? (data['lastDailyLoginRewardDate'] as dynamic).toDate() 
            : DateTime(2000);
        
        final now = DateTime.now();
        if (now.day == lastClaim.day && now.month == lastClaim.month && now.year == lastClaim.year) {
          return const Failure(DatabaseError("Already claimed today"));
        }

        transaction.update(userRef, {
          'coins': (data['coins'] ?? 0) + amount,
          'loginStreak': newStreak,
          'lastDailyLoginRewardDate': now,
        });
        return const Success(null);
      });
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }
}
