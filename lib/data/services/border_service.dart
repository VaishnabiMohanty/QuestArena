import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/result.dart';
import '../../core/errors/app_error.dart';
import '../models/border_model.dart';
import '../models/user_model.dart';
import '../repositories/border_repository.dart';
import '../../core/constants/borders.dart';
import '../../providers/unlock_providers.dart';

class BorderService {
  final BorderRepository _repository;
  final Ref _ref;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  BorderService({required BorderRepository repository, required Ref ref}) 
    : _repository = repository, _ref = ref;

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
        coins = 1200;
        borderId = 'diamond_border';
        break;
      case 'Master':
        coins = 1500;
        borderId = 'master_border';
        break;
      case 'Champion':
        coins = 2000;
        borderId = 'champion_border';
        break;
      case 'Legend':
        coins = 3000;
        borderId = 'legend_border';
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

    final result = await _repository.claimWeeklyReward(
      uid: user.uid,
      coinsReward: rewards['coins'],
      borderToUnlock: rewards['borderId'],
      currentLeague: rewards['league'],
    );

    if (result is Success && rewards['borderId'] != null) {
      _ref.read(lastUnlockedBorderProvider.notifier).state = rewards['borderId'];
    }

    return result;
  }

  Future<Result<void>> selectBorder(String uid, String borderId) async {
    return await _repository.selectBorder(uid, borderId);
  }

  /// Checks if the user should unlock any new borders based on their current league.
  Future<void> checkAndUnlockLeagues(String uid, String currentLeague) async {
    final userRef = _db.collection('users').doc(uid);
    
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;
      
      final user = UserModel.fromJson(snapshot.data()!);
      final currentlyUnlocked = Set<String>.from(user.unlockedBorders);

      final eligibleBorders = AppBorders.borders.where((border) {
        if (border.id == 'no_border') return false;
        return _isLeagueEligible(currentLeague, border.requiredLeague);
      }).map((b) => b.id).toList();

      bool changed = false;
      String? lastNew;

      for (final borderId in eligibleBorders) {
        if (currentlyUnlocked.add(borderId)) {
          changed = true;
          lastNew = borderId;
        }
      }

      if (changed) {
        transaction.update(userRef, {
          'unlockedBorders': currentlyUnlocked.toList(),
        });
        
        if (lastNew != null) {
          _ref.read(lastUnlockedBorderProvider.notifier).state = lastNew;
        }
      }
    });
  }

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
