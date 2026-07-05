import '../../core/errors/result.dart';
import '../../core/errors/app_error.dart';
import '../models/border_model.dart';
import '../models/user_model.dart';
import '../repositories/border_repository.dart';
import '../../core/constants/borders.dart';

class BorderService {
  final BorderRepository _repository;

  BorderService(this._repository);

  static const int minMatchesRequired = 5;

  Map<String, dynamic>? calculateWeeklyRewards(UserModel user) {
    if (user.weeklyMatchesPlayed < minMatchesRequired) {
      return null;
    }

    final league = user.rank;
    int coins = 0;
    String? borderId;

    switch (league) {
      case 'Bronze':
        coins = 100;
        borderId = 'bronze_border';
        break;
      case 'Silver':
        coins = 250;
        borderId = 'silver_border';
        break;
      case 'Gold':
        coins = 500;
        borderId = 'gold_border';
        break;
      case 'Platinum':
        coins = 800;
        borderId = 'platinum_border';
        break;
      case 'Diamond':
      case 'Master':
      case 'Champion':
      case 'Legend':
        coins = 1200;
        borderId = 'diamond_border';
        break;
      default:
        return null;
    }

    return {
      'coins': coins,
      'borderId': borderId,
      'league': league,
    };
  }

  Future<Result<void>> claimWeeklyReward(UserModel user) async {
    final rewards = calculateWeeklyRewards(user);
    if (rewards == null) {
      return const Failure(DatabaseError("You don't meet the requirements for weekly rewards yet."));
    }

    return await _repository.claimWeeklyReward(
      uid: user.uid,
      coinsReward: rewards['coins'],
      borderToUnlock: rewards['borderId'],
      currentLeague: rewards['league'],
    );
  }

  Future<Result<void>> selectBorder(String uid, String borderId) async {
    return await _repository.selectBorder(uid, borderId);
  }

  List<BorderModel> getBorders(UserModel user) {
    return AppBorders.borders.map((b) {
      return b.copyWith(
        isUnlocked: b.id == 'no_border' || user.unlockedBorders.contains(b.id),
      );
    }).toList();
  }

  bool isEligible(UserModel user) {
    return user.weeklyMatchesPlayed >= minMatchesRequired;
  }
}
