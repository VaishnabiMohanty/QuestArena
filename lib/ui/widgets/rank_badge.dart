import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class RankBadge extends StatelessWidget {
  final String rank;
  final int? subRank;
  final double size;

  const RankBadge({
    super.key,
    required this.rank,
    this.subRank,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final rankColor = _getRankColor(rank);
    final isLegend = rank == 'Legend';
    final isUnranked = rank == 'Unranked';

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: rankColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: rankColor.withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            _getRankIcon(rank),
            color: rankColor,
            size: size * (isLegend ? 0.6 : 0.5),
          ),
          if (subRank != null && !isLegend && !isUnranked)
            Positioned(
              bottom: size * 0.05,
              right: size * 0.05,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: rankColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surface, width: 1.5),
                ),
                constraints: BoxConstraints(
                  minWidth: size * 0.35,
                  minHeight: size * 0.35,
                ),
                alignment: Alignment.center,
                child: Text(
                  '$subRank',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: size * 0.22,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getRankColor(String rank) {
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

  IconData _getRankIcon(String rank) {
    switch (rank) {
      case 'Legend': return Icons.stars_rounded;
      case 'Champion': return Icons.workspace_premium_rounded;
      case 'Master': return Icons.military_tech_rounded;
      case 'Platinum': return Icons.shield_rounded;
      case 'Diamond': return Icons.diamond_rounded;
      default: return Icons.emoji_events_rounded;
    }
  }
}
