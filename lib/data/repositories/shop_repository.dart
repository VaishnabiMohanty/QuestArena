import 'package:cloud_firestore/cloud_firestore.dart';

class ShopRepository {
  final FirebaseFirestore _firestore;

  ShopRepository(this._firestore);

  Future<void> purchaseItem({
    required String userId,
    required int cost,
    int? oneOptionLifelinesInc,
    int? twoOptionLifelinesInc,
    int? rankProtectionMatchesInc,
  }) async {
    final userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);

      if (!snapshot.exists) {
        throw Exception('User does not exist');
      }

      final userData = snapshot.data()!;
      final currentCoins = userData['coins'] ?? 0;

      if (currentCoins < cost) {
        throw Exception('Insufficient coins');
      }

      transaction.update(userRef, {
        'coins': FieldValue.increment(-cost),
        if (oneOptionLifelinesInc != null)
          'oneOptionLifelines': FieldValue.increment(oneOptionLifelinesInc),
        if (twoOptionLifelinesInc != null)
          'twoOptionLifelines': FieldValue.increment(twoOptionLifelinesInc),
        if (rankProtectionMatchesInc != null) ...{
          'rankProtectionMatches': FieldValue.increment(rankProtectionMatchesInc),
        }
      });
    });
  }

  Future<void> setRankProtectionActive(String userId, bool active) async {
    final userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final userData = snapshot.data()!;
      final currentShieldMatches = userData['rankProtectionMatches'] ?? 0;

      if (active && currentShieldMatches <= 0) {
        throw Exception('No rank protection shields available');
      }

      transaction.update(userRef, {'rankProtectionActive': active});
    });
  }

  Future<void> activateRankProtection(String userId) async {
    return setRankProtectionActive(userId, true);
  }
}
