// WHAT THIS FILE DOES:
// Provides achievement data and the service to the rest of the app.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/achievement_model.dart';
import '../data/repositories/achievement_repository.dart';
import '../data/services/achievement_service.dart';
import 'auth_providers.dart';

final achievementRepositoryProvider = Provider((ref) => AchievementRepository());

final achievementServiceProvider = Provider((ref) {
  final repo = ref.watch(achievementRepositoryProvider);
  return AchievementService(repo, ref);
});

final userAchievementsProvider = StreamProvider.autoDispose<List<Achievement>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return Stream.value([]);
  
  return ref.watch(achievementRepositoryProvider).watchUserAchievements(user.uid);
});

// A provider to track the most recently unlocked achievement for popups
final lastUnlockedAchievementProvider = StateProvider<Achievement?>((ref) => null);
