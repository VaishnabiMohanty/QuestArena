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
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) return const Failure(DatabaseError("User not found"));

        final definition = achievementDefinitions.firstWhere((d) => d['id'] == achievementId);
        final currentProgress = achievementDoc.exists ? (achievementDoc.data()?['progress'] ?? 0) : 0;
        final isAlreadyUnlocked = achievementDoc.exists ? (achievementDoc.data()?['isUnlocked'] ?? false) : false;

        if (isAlreadyUnlocked) return const Success(null); // No need to update if already done

        final newProgress = currentProgress + increment;
        final shouldUnlock = newProgress >= (definition['target'] as int);

        final updateData = {
          'progress': newProgress,
          'isUnlocked': shouldUnlock,
          'unlockedAt': shouldUnlock ? FieldValue.serverTimestamp() : null,
        };

        transaction.set(achievementRef, updateData, SetOptions(merge: true));

        if (shouldUnlock) {
          // Award coins only once
          final currentCoins = userDoc.data()?['coins'] ?? 0;
          final reward = definition['rewardCoins'] as int;
          transaction.update(userRef, {'coins': currentCoins + reward});
          
          return Success(Achievement.fromJson(updateData, definition));
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
        final userDoc = await transaction.get(userRef);

        if (!userDoc.exists) return const Failure(DatabaseError("User not found"));

        final definition = achievementDefinitions.firstWhere((d) => d['id'] == achievementId);
        final currentProgress = achievementDoc.exists ? (achievementDoc.data()?['progress'] ?? 0) : 0;
        final isAlreadyUnlocked = achievementDoc.exists ? (achievementDoc.data()?['isUnlocked'] ?? false) : false;

        if (isAlreadyUnlocked) return const Success(null); 

        // Proceed if absoluteProgress is >= currentProgress
        if (absoluteProgress < currentProgress) return const Success(null);

        final shouldUnlock = absoluteProgress >= (definition['target'] as int);

        final updateData = {
          'progress': absoluteProgress,
          'isUnlocked': shouldUnlock,
          'unlockedAt': shouldUnlock ? FieldValue.serverTimestamp() : null,
        };

        transaction.set(achievementRef, updateData, SetOptions(merge: true));

        if (shouldUnlock) {
          final currentCoins = userDoc.data()?['coins'] ?? 0;
          final reward = definition['rewardCoins'] as int;
          transaction.update(userRef, {'coins': currentCoins + reward});
          
          return Success(Achievement.fromJson(updateData, definition));
        }

        return const Success(null);
      });
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }
}
