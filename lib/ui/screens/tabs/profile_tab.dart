// WHAT THIS FILE DOES:
// Displays the player's detailed stats and achievements grid.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:questarena/core/constants/colors.dart';
import 'package:questarena/core/constants/text_styles.dart';
import 'package:questarena/core/utils/rank_system.dart';
import 'package:questarena/data/models/leaderboard_model.dart';
import 'package:questarena/providers/user_providers.dart';
import 'package:questarena/providers/auth_providers.dart';
import 'package:questarena/providers/leaderboard_providers.dart';
import 'package:questarena/ui/widgets/rank_progress_bar.dart';
import 'package:questarena/ui/widgets/xp_progress_bar.dart';
import 'package:questarena/ui/widgets/neon_swirl_background.dart';
import 'package:questarena/ui/widgets/smart_avatar.dart';
import 'package:questarena/ui/screens/character_select_screen.dart';

import 'leaderboard_tab.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('DELETE ACCOUNT?', style: AppTextStyles.headline.copyWith(color: AppColors.red)),
        content: const Text(
          'This action is permanent. All your XP, coins, and achievements will be lost forever.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: AppTextStyles.label),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await ref.read(userRepositoryProvider).deleteUserProfile(uid);
              await ref.read(authRepositoryProvider).deleteAccount();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showAllAchievements(BuildContext context, List<String> unlockedIds, List<Map<String, dynamic>> all) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('ALL ACHIEVEMENTS', style: AppTextStyles.headline.copyWith(fontSize: 20)),
                ),
                Expanded(
                  child: GridView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: all.length,
                    itemBuilder: (context, index) {
                      final a = all[index];
                      final isUnlocked = unlockedIds.contains(a['id']);
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isUnlocked ? AppColors.cardBg : AppColors.cardBg.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isUnlocked ? AppColors.gold.withValues(alpha: 0.5) : AppColors.surface),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(a['icon'] as IconData, color: isUnlocked ? AppColors.gold : AppColors.textMuted, size: 32),
                            const SizedBox(height: 12),
                            Text(
                              a['name'] as String,
                              style: AppTextStyles.bodyMd.copyWith(
                                color: isUnlocked ? Colors.white : AppColors.textMuted,
                                fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final weeklyMvp = ref.watch(weeklyMvpProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) return const Center(child: Text('User not found'));

        final isMvp = weeklyMvp?.uid == user.uid;

        final allAchievements = [
          {'id': 'first_win', 'name': 'First Blood', 'desc': 'Win your first match', 'icon': Icons.flash_on_rounded},
          {'id': 'on_fire', 'name': 'On Fire', 'desc': 'Win 3 games in a row', 'icon': Icons.whatshot},
          {'id': 'veteran', 'name': 'Veteran', 'desc': 'Win 10 matches', 'icon': Icons.military_tech},
          {'id': 'scholar', 'name': 'Scholar', 'desc': 'Get 10/10 in one match', 'icon': Icons.school},
          {'id': 'arena_breaker', 'name': 'Arena Breaker', 'desc': 'Win a match against a higher rank', 'icon': Icons.security},
          {'id': 'clutch_master', 'name': 'Clutch Master', 'desc': 'Win in the final seconds', 'icon': Icons.timer},
          {'id': 'unbreakable', 'name': 'Unbreakable', 'desc': 'Reach a 10 match win streak', 'icon': Icons.shield},
        ];

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('PLAYER PROFILE', style: AppTextStyles.display.copyWith(fontSize: 18)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.red),
                onPressed: () => ref.read(authRepositoryProvider).logout(),
              ),
            ],
          ),
          body: NeonSwirlBackground(
            colors: const [AppColors.neonCyan, AppColors.neonViolet],
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Header
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CharacterSelectScreen(
                                    username: user.username,
                                    onConfirm: (selected) async {
                                      await ref.read(userRepositoryProvider).updateAvatarUrl(user.uid, selected.id);
                                      if (context.mounted) Navigator.pop(context);
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Stack(
                              children: [
                                SmartAvatar(
                                  avatarUrl: user.avatarUrl,
                                  size: 100,
                                  showGlow: true,
                                  showBorder: true,
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: AppColors.neonViolet,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit_rounded, size: 14, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),
                      Text(user.username, style: AppTextStyles.headline),
                      Text(
                        RankSystem.getRankName(user.rank, user.subRank),
                        style: AppTextStyles.label.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
                      ),

                      if (isMvp) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                '🏆 MVP HOLDER',
                                style: AppTextStyles.label.copyWith(
                                  color: AppColors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 40),

                      // Main Stats Row (4 statistics)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _ProfileStat(label: 'XP', value: '${user.xp}', color: AppColors.purple, icon: Icons.stars_rounded),
                          _ProfileStat(label: 'WINS', value: '${user.wins}', color: AppColors.teal, icon: Icons.emoji_events_rounded),
                          _ProfileStat(label: 'COINS', value: '${user.coins}', color: AppColors.gold, icon: Icons.monetization_on_rounded),
                          _ProfileStat(label: 'STREAK', value: '${user.currentWinStreak}', color: AppColors.red, icon: Icons.whatshot_rounded),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // XP & Rank Progress
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.surface),
                        ),
                        child: Column(
                          children: [
                            XpProgressBar(totalXp: user.xp),
                            if (user.rank != 'Legend' && user.rank != 'Unranked') ...[
                              const SizedBox(height: 20),
                              RankProgressBar(rank: user.rank, subRank: user.subRank, points: user.rankPoints),
                            ],
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 32),

                      // Friend Requests Section
                      const _FriendRequestsSection(),

                      // Friends List Section
                      const _FriendsListSection(),

                      // Statistics Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.surface),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _ProfileStatItem(label: 'MATCHES', value: '${user.matchesPlayed}'),
                                _ProfileStatItem(label: 'WIN RATE', value: '${user.winRate.toStringAsFixed(0)}%'),
                                _ProfileStatItem(label: 'LEVEL', value: '${user.level}'),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Divider(color: AppColors.surface, height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _ProfileStatItem(label: 'LOSSES', value: '${user.losses}'),
                                _ProfileStatItem(label: 'DRAWS', value: '${user.draws}'),
                                _ProfileStatItem(label: 'BEST STREAK', value: '${user.highestWinStreak}'),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 48),

                      // Achievements Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('ACHIEVEMENTS', style: AppTextStyles.label.copyWith(fontSize: 10, letterSpacing: 1, color: AppColors.textMuted)),
                          TextButton(
                            onPressed: () => _showAllAchievements(context, user.achievements, allAchievements),
                            child: Text('VIEW ALL', style: AppTextStyles.label.copyWith(color: AppColors.gold, fontSize: 10)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (user.achievements.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Text('No achievements unlocked yet', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted)),
                        )
                      else
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: allAchievements.where((a) => user.achievements.contains(a['id'])).map((achievement) {
                              return _AchievementChip(
                                icon: achievement['icon'] as IconData,
                                name: achievement['name'] as String,
                              );
                            }).toList(),
                          ),
                        ),

                      const SizedBox(height: 48),

                      // Delete Account Button
                      TextButton.icon(
                        onPressed: () => _showDeleteConfirmation(context, ref, user.uid),
                        icon: const Icon(Icons.delete_forever_rounded, color: AppColors.red, size: 20),
                        label: Text(
                          'DELETE ACCOUNT',
                          style: AppTextStyles.label.copyWith(color: AppColors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ProfileStat({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18, color: Colors.white)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _ProfileStatItem extends StatelessWidget {
  final String label;
  final String value;
  const _ProfileStatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 20)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _AchievementChip extends StatelessWidget {
  final IconData icon;
  final String name;
  const _AchievementChip({required this.icon, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.gold, size: 14),
          const SizedBox(width: 8),
          Text(name.toUpperCase(), style: AppTextStyles.label.copyWith(color: AppColors.gold, fontSize: 9, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _FriendRequestsSection extends ConsumerWidget {
  const _FriendRequestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(incomingRequestsProvider);

    return requestsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (requests) {
        if (requests.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('FRIEND REQUESTS', style: AppTextStyles.label.copyWith(letterSpacing: 2)),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final data = request.data();

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surface),
                  ),
                  child: Row(
                    children: [
                      SmartAvatar(avatarUrl: data['senderAvatar'], size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['senderUsername'], style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                            Text('Sent you a request', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => ref.read(friendsRepositoryProvider).acceptFriendRequest(request.id, data),
                            icon: const Icon(Icons.check_circle_rounded, color: AppColors.teal),
                          ),
                          IconButton(
                            onPressed: () => ref.read(friendsRepositoryProvider).rejectFriendRequest(request.id),
                            icon: const Icon(Icons.cancel_rounded, color: AppColors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _FriendsListSection extends ConsumerWidget {
  const _FriendsListSection();

  void _showFriendProfile(BuildContext context, LeaderboardModel friend) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    SmartAvatar(avatarUrl: friend.avatarUrl, size: 60),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(friend.username, style: AppTextStyles.headline.copyWith(fontSize: 20)),
                          Text(
                            'LVL ${friend.level} • ${RankSystem.getRankName(friend.rank, friend.subRank)}',
                            style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ExpandedDetails(uid: friend.uid, player: friend, isMe: false),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CLOSE', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('FRIENDS', style: AppTextStyles.label.copyWith(letterSpacing: 2)),
        const SizedBox(height: 16),
        friendsAsync.when(
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (e, s) => Text('Error: $e'),
          data: (friends) {
            if (friends.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text('You haven\'t added any friends yet.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted)),
              );
            }

            return SizedBox(
              height: 120,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return GestureDetector(
                    onTap: () => _showFriendProfile(context, friend),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surface),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SmartAvatar(avatarUrl: friend.avatarUrl, size: 40),
                          const SizedBox(height: 8),
                          Text(
                            friend.username,
                            style: AppTextStyles.bodyMd.copyWith(fontSize: 12, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text('LVL ${friend.level}', style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.gold)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
