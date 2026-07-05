import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/utils/rank_system.dart';
import '../../data/models/leaderboard_model.dart';
import '../../data/models/user_model.dart';
import '../../providers/user_providers.dart';
import 'smart_avatar.dart';

class ExpandablePlayerCard extends StatelessWidget {
  final String uid;
  final String username;
  final String? avatarUrl;
  final int level;
  final int xp;
  final String rank;
  final int? subRank;
  final bool isMe;
  final bool isExpanded;
  final int index;
  final VoidCallback onTap;
  final Widget? trailing;

  const ExpandablePlayerCard({
    super.key,
    required this.uid,
    required this.username,
    this.avatarUrl,
    required this.level,
    required this.xp,
    required this.rank,
    this.subRank,
    required this.isMe,
    required this.isExpanded,
    required this.index,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.purple.withValues(alpha: 0.1) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isMe ? AppColors.purple : (isExpanded ? AppColors.neonCyan : AppColors.surface),
            width: (isMe || isExpanded) ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                SmartAvatar(avatarUrl: avatarUrl, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(username, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: isMe ? AppColors.purple : Colors.white)),
                      Text('LVL $level • ${RankSystem.getRankName(rank, subRank)}', style: AppTextStyles.label.copyWith(fontSize: 10)),
                    ],
                  ),
                ),
                if (trailing != null) trailing!,
                const SizedBox(width: 8),
                Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: AppColors.textMuted, size: 20),
              ],
            ),
            if (isExpanded)
              ExpandedDetails(uid: uid, player: LeaderboardModel(
                uid: uid,
                username: username,
                avatarUrl: avatarUrl,
                level: level,
                xp: xp,
                rank: rank,
                subRank: subRank,
              ), isMe: isMe),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
  }
}

class ExpandedDetails extends ConsumerWidget {
  final String uid;
  final LeaderboardModel player;
  final bool isMe;

  const ExpandedDetails({super.key, required this.uid, required this.player, required this.isMe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));

    return profileAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
      ),
      error: (e, s) => Text('Error loading stats', style: AppTextStyles.label.copyWith(color: AppColors.red)),
      data: (UserModel? user) {
        final xpVal = user?.xp ?? player.xp;
        final winsVal = user?.wins ?? player.wins;
        final matchesVal = user?.matchesPlayed ?? player.totalMatches;
        final winRateVal = user?.winRate ?? player.winRate;
        final streakVal = user?.currentWinStreak ?? player.currentWinStreak;

        return Column(
          children: [
            const Divider(color: AppColors.surface, height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DetailStat(label: 'XP', value: '$xpVal', color: AppColors.purple),
                _DetailStat(label: 'WINS', value: '$winsVal', color: AppColors.teal),
                _DetailStat(label: 'STREAK', value: '$streakVal', color: AppColors.red),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _DetailStat(label: 'MATCHES', value: '$matchesVal', color: Colors.white70),
                _DetailStat(label: 'WIN RATE', value: '${winRateVal.toStringAsFixed(1)}%', color: AppColors.gold),
              ],
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _DetailStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18, color: color)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textSecondary)),
      ],
    );
  }
}
