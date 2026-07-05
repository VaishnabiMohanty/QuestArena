// WHAT THIS FILE DOES:
// Mathematical logic for Leveling and Ranking.

import 'dart:ui';
import '../constants/colors.dart';
import 'level_system.dart';
import 'rank_system.dart';

class RankUpdateResult {
  final String rank;
  final int? subRank;
  final int remainingPoints;

  RankUpdateResult({required this.rank, this.subRank, required this.remainingPoints});
}

class RankCalculator {
  static String getRank(int xp) {
    if (xp >= 10000) return 'Diamond';
    if (xp >= 4000) return 'Platinum';
    if (xp >= 1500) return 'Gold';
    if (xp >= 500) return 'Silver';
    return 'Bronze';
  }

  static Color getRankColor(String rank) {
    switch (rank) {
      case 'Diamond': return AppColors.rankDiamond;
      case 'Platinum': return AppColors.rankPlatinum;
      case 'Gold': return AppColors.rankGold;
      case 'Silver': return AppColors.rankSilver;
      default: return AppColors.rankBronze;
    }
  }

  /// Returns the XP required to reach the next level from [currentLevel].
  /// Now delegates to the central [LevelSystem].
  static int getXpToNextLevel(int currentLevel) {
    return LevelSystem.xpForNextLevel(currentLevel);
  }

  static RankUpdateResult calculateNewRank(String currentRank, int? currentSubRank, int points) {
    String rank = currentRank;
    int? subRank = currentSubRank;
    int remainingPoints = points;

    if (remainingPoints >= 100) {
      final promotion = RankSystem.promote(rank, subRank);
      rank = promotion['rank'];
      subRank = promotion['subRank'];
      remainingPoints -= 100;
    } else if (remainingPoints < 0) {
      final demotion = RankSystem.demote(rank, subRank);
      rank = demotion['rank'];
      subRank = demotion['subRank'];
      remainingPoints = rank == currentRank ? 0 : 80; // Start at 80 if demoted
    }

    return RankUpdateResult(rank: rank, subRank: subRank, remainingPoints: remainingPoints);
  }
}
