import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/repositories/shop_repository.dart';
import '../data/services/shop_service.dart';
import 'auth_providers.dart';

final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

final shopRepositoryProvider = Provider((ref) {
  final firestore = ref.watch(firestoreProvider);
  return ShopRepository(firestore);
});

final shopControllerProvider = StateNotifierProvider<ShopController, AsyncValue<void>>((ref) {
  final repository = ref.watch(shopRepositoryProvider);
  final authState = ref.watch(authStateProvider).value;
  return ShopController(repository, authState?.uid);
});

class ShopController extends StateNotifier<AsyncValue<void>> {
  final ShopRepository _repository;
  final String? _userId;

  ShopController(this._repository, this._userId) : super(const AsyncValue.data(null));

  Future<void> purchaseOneOptionLifeline() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.purchaseItem(
      userId: _userId,
      cost: ShopService.oneOptionLifelineCost,
      oneOptionLifelinesInc: 1,
    ));
  }

  Future<void> purchaseTwoOptionLifeline() async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.purchaseItem(
      userId: _userId,
      cost: ShopService.twoOptionLifelineCost,
      twoOptionLifelinesInc: 1,
    ));
  }

  Future<void> purchaseRankProtection(int matches, int cost) async {
    if (_userId == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.purchaseItem(
      userId: _userId,
      cost: cost,
      rankProtectionMatchesInc: matches,
    ));
  }

  Future<void> activateRankProtection() async {
    final uid = _userId;
    if (uid == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.setRankProtectionActive(uid, true));
  }

  Future<void> toggleRankProtection(bool active) async {
    final uid = _userId;
    if (uid == null) return;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repository.setRankProtectionActive(uid, active));
  }
}
