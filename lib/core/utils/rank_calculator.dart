// WHAT THIS FILE DOES:
// Mathematical logic for Leveling and Ranking.

import 'dart:ui';
import 'dart:math' as math;
import 'level_system.dart';
import 'rank_system.dart';

class RankUpdateResult {
  final String rank;
  final int? subRank;
  final int remainingPoints;

  RankUpdateResult({required this.rank, this.subRank, required this.remainingPoints});
}

class RankCalculator {
  /// Returns the basic rank name based on cumulative XP (legacy/simple version).
  static String getRankFromXp(int xp) {
    if (xp >= 10000) return 'Diamond';
    if (xp >= 4000) return 'Platinum';
    if (xp >= 1500) return 'Gold';
    if (xp >= 500) return 'Silver';
    return 'Bronze';
  }

  /// Returns the color associated with a rank.
  static Color getRankColor(String rank) {
    return RankSystem.getRankColor(rank);
  }

  /// Returns the XP required to reach the next level from [currentLevel].
  static int getXpToNextLevel(int currentLevel) {
    return LevelSystem.xpForNextLevel(currentLevel);
  }

  /// Calculates the new rank and sub-rank based on competitive points.
  /// Handles multiple promotions/demotions and point overflows.
  static RankUpdateResult calculateNewRank(String currentRank, int? currentSubRank, int points) {
    String rank = currentRank;
    int? subRank = currentSubRank;
    int remainingPoints = points;

    // 1. Handle Promotions
    // If points reach 100, promote the player and carry over excess points.
    while (remainingPoints >= 100 && rank != 'Legend') {
      final promotion = RankSystem.promote(rank, subRank);
      if (promotion['rank'] == rank && promotion['subRank'] == subRank) break;
      
      rank = promotion['rank'];
      subRank = promotion['subRank'];
      remainingPoints -= 100;
    }

    // 2. Handle Demotions
    // If points drop below 0, demote the player.
    while (remainingPoints < 0 && rank != 'Unranked') {
      final demotion = RankSystem.demote(rank, subRank);
      if (demotion['rank'] == rank && demotion['subRank'] == subRank) {
        remainingPoints = 0;
        break;
      }

      rank = demotion['rank'];
      subRank = demotion['subRank'];

      if (rank == 'Unranked') {
        remainingPoints = 0;
        break;
      }

      // After demotion, the player typically starts at a high point value (e.g., 80)
      // minus any extra negative points they had.
      remainingPoints = 80 + remainingPoints;
      
      // If they are still negative after one demotion, the loop continues.
      if (remainingPoints >= 0) break;
    }

    // Final safety checks
    if (rank == 'Unranked') remainingPoints = 0;
    if (rank == 'Legend') remainingPoints = math.max(0, remainingPoints);
    if (remainingPoints < 0) remainingPoints = 0;

    return RankUpdateResult(
      rank: rank,
      subRank: subRank,
      remainingPoints: remainingPoints,
    );
  }
}
