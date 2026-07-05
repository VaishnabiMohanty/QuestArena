import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../models/user_model.dart';

class StreakRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Updates login streak and rewards if applicable using a transaction.
  Future<Result<int>> processLoginStreakTransaction({
    required String uid,
    required int newStreak,
    required bool shouldReward,
    required int rewardAmount,
  }) async {
    try {
      final userRef = _db.collection('users').doc(uid);

      return await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return const Failure(DatabaseError("User not found"));

        final data = snapshot.data()!;
        final now = DateTime.now();

        final Map<String, dynamic> updates = {
          'loginStreak': newStreak,
          'lastLoginDate': now,
        };

        if (shouldReward) {
          updates['coins'] = (data['coins'] ?? 0) + rewardAmount;
        }

        transaction.update(userRef, updates);
        return Success(shouldReward ? rewardAmount : 0);
      });
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  /// Updates win streak and rewards if applicable using a transaction.
  Future<Result<int>> processWinStreakTransaction({
    required String uid,
    required bool isWin,
    required int rewardThreshold,
    required int rewardAmount,
  }) async {
    try {
      final userRef = _db.collection('users').doc(uid);

      return await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) return const Failure(DatabaseError("User not found"));

        final user = UserModel.fromJson(snapshot.data()!);
        
        int currentStreak = user.currentWinStreak;
        int highestStreak = user.highestWinStreak;
        int rewardedAmount = 0;

        if (isWin) {
          currentStreak++;
          if (currentStreak > highestStreak) {
            highestStreak = currentStreak;
          }

          if (currentStreak == rewardThreshold) {
            rewardedAmount = rewardAmount;
            currentStreak = 0; // Reset after reward as per requirements
          }
        } else {
          currentStreak = 0;
        }

        final Map<String, dynamic> updates = {
          'currentWinStreak': currentStreak,
          'highestWinStreak': highestStreak,
        };

        if (rewardedAmount > 0) {
          updates['coins'] = user.coins + rewardedAmount;
        }

        transaction.update(userRef, updates);
        return Success(rewardedAmount);
      });
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }
}
