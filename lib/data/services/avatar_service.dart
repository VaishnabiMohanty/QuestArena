import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/avatars.dart';
import '../models/user_model.dart';
import '../../providers/unlock_providers.dart';

class AvatarService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Ref _ref;

  AvatarService(this._ref);

  /// Checks if the user should unlock any new avatars based on their current league.
  /// This should be called whenever the user's league changes.
  Future<void> checkAndUnlockLeagues(String uid, String currentLeague) async {
    final userRef = _db.collection('users').doc(uid);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists || snapshot.data() == null) return;

      final user = UserModel.fromJson(snapshot.data()!);
      final currentlyUnlocked = Set<String>.from(user.unlockedAvatars);

      final eligibleAvatars = AppAvatars.avatars.where((avatar) {
        return _isLeagueEligible(currentLeague, avatar.requiredLeague);
      }).map((a) => a.image).toList();

      bool changed = false;
      List<String> newlyUnlocked = [];

      for (final image in eligibleAvatars) {
        if (currentlyUnlocked.add(image)) {
          changed = true;
          newlyUnlocked.add(image);
        }
      }

      if (changed) {
        transaction.update(userRef, {
          'unlockedAvatars': currentlyUnlocked.toList(),
        });
        
        if (newlyUnlocked.isNotEmpty) {
          _ref.read(lastUnlockedAvatarProvider.notifier).state = newlyUnlocked.first;
        }
      }
    });
  }

  /// Determines if a league qualifies for avatars of a target league.
  static bool _isLeagueEligible(String currentLeague, String targetLeague) {
    const leaguePriority = {
      'Unranked': 0,
      'Bronze': 1,
      'Silver': 2,
      'Gold': 3,
      'Platinum': 4,
      'Diamond': 5,
      'Master': 6,
      'Champion': 7,
      'Legend': 8,
    };

    final currentLevel = leaguePriority[currentLeague] ?? 0;
    final targetLevel = leaguePriority[targetLeague] ?? 0;

    return currentLevel >= targetLevel;
  }

  /// Manually select a new avatar if it's unlocked.
  Future<void> selectAvatar(String uid, String avatarImage, List<String> unlockedAvatars) async {
    final avatar = AppAvatars.avatars.firstWhere((a) => a.image == avatarImage, orElse: () => AppAvatars.avatars[0]);
    final isDefault = avatar.requiredLeague == 'Unranked';

    if (!isDefault && !unlockedAvatars.contains(avatarImage)) {
      throw Exception("This avatar is locked. Reach the required league to unlock.");
    }

    await _db.collection('users').doc(uid).update({
      'avatarUrl': avatarImage,
    });
  }

  /// Helper to calculate newly unlocked avatars based on league.
  static List<String> getEligibleAvatars(String currentLeague, List<String> currentlyUnlocked) {
    final unlockedSet = Set<String>.from(currentlyUnlocked);

    for (final avatar in AppAvatars.avatars) {
      if (_isLeagueEligible(currentLeague, avatar.requiredLeague)) {
        unlockedSet.add(avatar.image);
      }
    }

    return unlockedSet.toList();
  }
}
