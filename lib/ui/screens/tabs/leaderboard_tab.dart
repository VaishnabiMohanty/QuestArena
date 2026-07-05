import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/leaderboard_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/leaderboard_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../core/utils/rank_system.dart';
import '../../widgets/smart_avatar.dart';
import '../../widgets/expandable_player_card.dart';

class LeaderboardTab extends ConsumerStatefulWidget {
  const LeaderboardTab({super.key});

  @override
  ConsumerState<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<LeaderboardTab> {
  bool _isGlobal = true;

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final friendsAsync = ref.watch(friendsProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('ARENA RANKS', style: AppTextStyles.display.copyWith(fontSize: 18, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildToggle(),
          Expanded(
            child: _isGlobal
              ? _buildLeaderboard(leaderboardAsync, currentUser)
              : _buildFriendsLeaderboard(friendsAsync, currentUser),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface),
      ),
      child: Row(
        children: [
          _ToggleItem(
            label: 'GLOBAL',
            isSelected: _isGlobal,
            onTap: () => setState(() => _isGlobal = true),
          ),
          _ToggleItem(
            label: 'FRIENDS',
            isSelected: !_isGlobal,
            onTap: () => setState(() => _isGlobal = false),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(AsyncValue<List<LeaderboardModel>> leaderboardAsync, UserModel? currentUser) {
    return leaderboardAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (players) {
        if (players.isEmpty) return const Center(child: Text('No data found'));
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: players.length,
          itemBuilder: (context, index) {
            final player = players[index];
            final isMe = player.uid == currentUser?.uid;
            return _LeaderboardItem(player: player, rank: index + 1, isMe: isMe);
          },
        );
      },
    );
  }

  Widget _buildFriendsLeaderboard(AsyncValue<List<LeaderboardModel>> friendsAsync, UserModel? currentUser) {
    return friendsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (friends) {
        final List<LeaderboardModel> all = List.from(friends);
        if (currentUser != null) {
          all.add(LeaderboardModel(
            uid: currentUser.uid,
            username: currentUser.username,
            avatarUrl: currentUser.avatarUrl,
            xp: currentUser.xp,
            level: currentUser.level,
            rank: currentUser.rank,
            subRank: currentUser.subRank ?? 0,
            eloRating: currentUser.eloRating,
            wins: currentUser.wins,
          ));
        }
        all.sort((a, b) => b.xp.compareTo(a.xp));

        if (all.isEmpty) return const Center(child: Text('Add friends to compare ranks!'));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: all.length,
          itemBuilder: (context, index) {
            final player = all[index];
            final isMe = player.uid == currentUser?.uid;
            return _LeaderboardItem(player: player, rank: index + 1, isMe: isMe);
          },
        );
      },
    );
  }
}

class _ToggleItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  const _ToggleItem({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.purple : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LeaderboardItem extends StatelessWidget {
  final LeaderboardModel player;
  final int rank;
  final bool isMe;

  const _LeaderboardItem({required this.player, required this.rank, required this.isMe});

  @override
  Widget build(BuildContext context) {
    final rankColor = rank == 1 ? AppColors.gold : (rank == 2 ? Colors.white70 : (rank == 3 ? Colors.brown : AppColors.textMuted));

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: AppColors.cardBg,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SmartAvatar(avatarUrl: player.avatarUrl, size: 80, showGlow: true),
                  const SizedBox(height: 16),
                  Text(player.username, style: AppTextStyles.headline),
                  Text(RankSystem.getRankName(player.rank, player.subRank), style: AppTextStyles.label.copyWith(color: AppColors.gold)),
                  const SizedBox(height: 24),
                  ExpandedDetails(uid: player.uid, player: player, isMe: isMe),
                  const SizedBox(height: 24),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('CLOSE')),
                ],
              ),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? AppColors.purple.withValues(alpha: 0.1) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isMe ? AppColors.purple : AppColors.surface, width: isMe ? 1.5 : 1),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 30,
              child: Text('#$rank', style: AppTextStyles.headline.copyWith(fontSize: 14, color: rankColor)),
            ),
            SmartAvatar(avatarUrl: player.avatarUrl, size: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(player.username, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold, color: isMe ? AppColors.purple : Colors.white)),
                  Text('LVL ${player.level} • ${RankSystem.getRankName(player.rank, player.subRank)}', style: AppTextStyles.label.copyWith(fontSize: 10)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${player.xp}', style: AppTextStyles.headline.copyWith(fontSize: 16, color: AppColors.gold)),
                Text('XP', style: AppTextStyles.label.copyWith(fontSize: 8)),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (rank * 50).ms).slideX(begin: 0.1, end: 0);
  }
}
