import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repositories/coin_repository.dart';
import '../data/services/coin_service.dart';
import 'user_providers.dart';

final coinRepositoryProvider = Provider((ref) => CoinRepository());

final coinServiceProvider = Provider((ref) {
  final repo = ref.watch(coinRepositoryProvider);
  return CoinService(repo);
});

final coinBalanceProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider).value;
  return user?.coins ?? 0;
});

// Provides the daily limit progress as a fraction (0.0 to 1.0)
final dailyCoinLimitProvider = Provider<double>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return 0.0;
  return (user.todayCoinsEarned / 500).clamp(0.0, 1.0);
});
