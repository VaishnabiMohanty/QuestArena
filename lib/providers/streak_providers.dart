import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/streak_repository.dart';
import '../data/services/streak_service.dart';

final streakRepositoryProvider = Provider((ref) => StreakRepository());

final streakServiceProvider = Provider((ref) {
  final repo = ref.watch(streakRepositoryProvider);
  return StreakService(repo, ref);
});
