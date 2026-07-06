// WHAT THIS FILE DOES:
// Handles all Firestore operations for the Achievement System.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/achievement_model.dart';
import '../../core/errors/result.dart';
import '../../core/errors/app_error.dart';

class AchievementRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Fetch all achievements for a specific user.
  Stream<List<Achievement>> watchUserAchievements(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('achievements')
        .snapshots()
        .map((snapshot) {
      final userAchievements = {
        for (var doc in snapshot.docs) doc.id: doc.data()
      };

      return achievementDefinitions.map((def) {
        final userData = userAchievements[def['id']] ?? {};
        return Achievement.fromJson(userData, def);
      }).toList();
    });
  }

  /// Update progress and handle unlocking via Transaction.
  Future<Result<Achievement?>> updateAchievementProgress({
    required String uid,
    required String achievementId,
    required int increment,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final achievementRef = userRef.collection('achievements').doc(achievementId);

      return await _firestore.runTransaction((transaction) async {
        final achievementDoc = await transaction.get(achievementRef);
        final definition = achievementDefinitions.firstWhere((d) => d['id'] == achievementId);
        
        final currentProgress = achievementDoc.exists ? (achievementDoc.data()?['progress'] ?? 0) : 0;
        final isAlreadyUnlocked = achievementDoc.exists ? (achievementDoc.data()?['isUnlocked'] ?? false) : false;

        if (isAlreadyUnlocked) return const Success(null);

        final newProgress = currentProgress + increment;
        final shouldUnlock = newProgress >= (definition['target'] as int);

        final updateData = {
          'progress': newProgress,
          'isUnlocked': shouldUnlock,
          'unlockedAt': shouldUnlock ? FieldValue.serverTimestamp() : null,
        };

        transaction.set(achievementRef, updateData, SetOptions(merge: true));
        
        if (shouldUnlock) {
          // Use current time for the local object so UI doesn't crash on FieldValue token
          final localData = Map<String, dynamic>.from(updateData)..['unlockedAt'] = DateTime.now();
          return Success(Achievement.fromJson(localData, definition));
        }

        return const Success(null);
      });
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  /// Sync progress to an absolute value and handle unlocking.
  Future<Result<Achievement?>> syncAchievementProgress({
    required String uid,
    required String achievementId,
    required int absoluteProgress,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final achievementRef = userRef.collection('achievements').doc(achievementId);

      return await _firestore.runTransaction((transaction) async {
        final achievementDoc = await transaction.get(achievementRef);
        final definition = achievementDefinitions.firstWhere((d) => d['id'] == achievementId);
        
        final currentProgress = achievementDoc.exists ? (achievementDoc.data()?['progress'] ?? 0) : 0;
        final isAlreadyUnlocked = achievementDoc.exists ? (achievementDoc.data()?['isUnlocked'] ?? false) : false;

        if (isAlreadyUnlocked) return const Success(null);

        // If not unlocked, we always want to take the higher of the two values
        final effectiveProgress = absoluteProgress > currentProgress ? absoluteProgress : currentProgress;
        final shouldUnlock = effectiveProgress >= (definition['target'] as int);

        final updateData = {
          'progress': effectiveProgress,
          'isUnlocked': shouldUnlock,
          'unlockedAt': shouldUnlock ? FieldValue.serverTimestamp() : null,
        };

        transaction.set(achievementRef, updateData, SetOptions(merge: true));

        if (shouldUnlock) {
          // Use current time for the local object so UI doesn't crash on FieldValue token
          final localData = Map<String, dynamic>.from(updateData)..['unlockedAt'] = DateTime.now();
          return Success(Achievement.fromJson(localData, definition));
        }

        return const Success(null);
      });
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  /// Handles claiming rewards for an unlocked achievement.
  Future<Result<void>> claimAchievementReward({
    required String uid,
    required String achievementId,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final achievementRef = userRef.collection('achievements').doc(achievementId);

      return await _firestore.runTransaction((transaction) async {
        final achievementDoc = await transaction.get(achievementRef);
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) return const Failure(DatabaseError("User not found"));
        if (!achievementDoc.exists) return const Failure(DatabaseError("Achievement progress not found"));

        final achievementData = achievementDoc.data()!;
        final isUnlocked = achievementData['isUnlocked'] ?? false;
        final isClaimed = achievementData['isClaimed'] ?? false;

        if (!isUnlocked) return const Failure(DatabaseError("Achievement is still locked"));
        if (isClaimed) return const Failure(DatabaseError("Reward already claimed"));

        final definition = achievementDefinitions.firstWhere((d) => d['id'] == achievementId);
        final reward = AchievementReward.fromJson(definition['reward'] ?? {});

        final userData = userDoc.data()!;
        final currentCoins = userData['coins'] ?? 0;
        final currentXp = userData['xp'] ?? 0;
        final List<String> unlockedAvatars = List<String>.from(userData['unlockedAvatars'] ?? []);
        final List<String> unlockedBorders = List<String>.from(userData['unlockedBorders'] ?? []);

        final Map<String, dynamic> userUpdates = {
          'coins': currentCoins + reward.coins,
          'xp': currentXp + reward.xp,
        };

        if (reward.avatarId != null && !unlockedAvatars.contains(reward.avatarId)) {
          unlockedAvatars.add(reward.avatarId!);
          userUpdates['unlockedAvatars'] = unlockedAvatars;
        }

        if (reward.borderId != null && !unlockedBorders.contains(reward.borderId)) {
          unlockedBorders.add(reward.borderId!);
          userUpdates['unlockedBorders'] = unlockedBorders;
        }

        // Apply updates
        transaction.update(userRef, userUpdates);
        transaction.update(achievementRef, {
          'isClaimed': true,
          'claimedAt': FieldValue.serverTimestamp(),
        });

        return const Success(null);
      });
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }
}
