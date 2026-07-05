import 'package:flutter/material.dart';
import '../constants/colors.dart';

class RankSystem {
  static const List<String> ranks = [
    'Unranked',
    'Bronze',
    'Silver',
    'Gold',
    'Platinum',
    'Diamond',
    'Master',
    'Champion',
    'Legend',
  ];

  static const List<int> subRanks = [3, 2, 1];

  static Color getRankColor(String rank) {
    switch (rank) {
      case 'Bronze': return AppColors.rankBronze;
      case 'Silver': return AppColors.rankSilver;
      case 'Gold': return AppColors.rankGold;
      case 'Diamond': return AppColors.rankDiamond;
      case 'Platinum': return AppColors.rankPlatinum;
      case 'Master': return AppColors.rankMaster;
      case 'Champion': return AppColors.rankChampion;
      case 'Legend': return AppColors.gold;
      default: return AppColors.textMuted;
    }
  }

  /// Returns the next rank/sub-rank configuration.
  static Map<String, dynamic> promote(String currentRank, int? currentSubRank) {
    if (currentRank == 'Legend') {
      return {'rank': 'Legend', 'subRank': null};
    }

    if (currentRank == 'Unranked') {
      return {'rank': 'Bronze', 'subRank': 3};
    }

    // Fallback for missing sub-rank on ranked players
    final actualSubRank = currentSubRank ?? 3;

    if (actualSubRank == 1) {
      final currentIndex = ranks.indexOf(currentRank);
      if (currentIndex < ranks.length - 1) {
        final nextRank = ranks[currentIndex + 1];
        if (nextRank == 'Legend') {
          return {'rank': 'Legend', 'subRank': null};
        }
        return {'rank': nextRank, 'subRank': 3};
      }
    } else {
      return {'rank': currentRank, 'subRank': actualSubRank - 1};
    }

    return {'rank': currentRank, 'subRank': actualSubRank};
  }

  /// Returns the previous rank/sub-rank configuration.
  static Map<String, dynamic> demote(String currentRank, int? currentSubRank) {
    if (currentRank == 'Unranked') {
      return {'rank': 'Unranked', 'subRank': null};
    }

    // Fallback for missing sub-rank
    final actualSubRank = currentSubRank ?? 1;

    if (currentRank == 'Bronze' && actualSubRank == 3) {
      return {'rank': 'Unranked', 'subRank': null};
    }

    if (currentRank == 'Legend') {
      return {'rank': 'Champion', 'subRank': 1};
    }

    if (actualSubRank == 3) {
      final currentIndex = ranks.indexOf(currentRank);
      if (currentIndex > 1) { // 0 is Unranked, 1 is Bronze
        final prevRank = ranks[currentIndex - 1];
        return {'rank': prevRank, 'subRank': 1};
      }
    } else {
      return {'rank': currentRank, 'subRank': actualSubRank + 1};
    }

    return {'rank': currentRank, 'subRank': actualSubRank};
  }

  static String getRankName(String rank, int? subRank) {
    if (subRank == null) return rank;
    return '$rank $subRank';
  }

  static String subRankToRoman(int subRank) {
    switch (subRank) {
      case 1: return 'I';
      case 2: return 'II';
      case 3: return 'III';
      default: return '';
    }
  }

  static String getRankFromElo(int elo) {
    if (elo >= 1800) return 'Master';
    if (elo >= 1600) return 'Diamond';
    if (elo >= 1400) return 'Platinum';
    if (elo >= 1200) return 'Gold';
    if (elo >= 1000) return 'Silver';
    return 'Bronze';
  }
}
