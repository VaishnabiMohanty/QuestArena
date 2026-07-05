class ShopService {
  static const int oneOptionLifelineCost = 5;
  static const int twoOptionLifelineCost = 10;

  static const Map<int, int> rankProtectionCosts = {
    1: 20,
    2: 35,
    5: 75,
  };

  static int getRankProtectionCost(int matches) {
    return rankProtectionCosts[matches] ?? (matches * 15); // Fallback
  }
}
