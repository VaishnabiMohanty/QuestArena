import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:questarena/data/repositories/border_repository.dart';
import 'package:questarena/data/services/border_service.dart';
import 'package:questarena/providers/user_providers.dart';

final borderRepositoryProvider = Provider<BorderRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return BorderRepository(firestoreService);
});

final borderServiceProvider = Provider<BorderService>((ref) {
  final repository = ref.watch(borderRepositoryProvider);
  return BorderService(repository: repository, ref: ref);
});

final availableBordersProvider = Provider((ref) {
  final user = ref.watch(currentUserProvider).value;
  final service = ref.watch(borderServiceProvider);
  if (user == null) return [];
  return service.getBorders(user);
});

final selectedBorderProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return null;
  return user.selectedBorder;
});

final weeklyRewardEligibilityProvider = Provider((ref) {
  final user = ref.watch(currentUserProvider).value;
  final service = ref.watch(borderServiceProvider);
  if (user == null) return false;
  return service.isEligible(user);
});

final weeklyRewardProvider = FutureProvider((ref) async {
  final user = ref.watch(currentUserProvider).value;
  final service = ref.watch(borderServiceProvider);
  if (user == null) return null;
  
  // Check if reward was already claimed this week
  if (user.lastWeeklyRewardDate != null) {
    final now = DateTime.now();
    final repository = ref.read(borderRepositoryProvider);
    if (repository.isSameCalendarWeek(now, user.lastWeeklyRewardDate!)) {
      return null;
    }
  }

  return service.calculateWeeklyRewards(user);
});
