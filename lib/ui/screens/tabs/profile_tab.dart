import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:questarena/core/constants/colors.dart';
import 'package:questarena/core/constants/text_styles.dart';
import 'package:questarena/core/utils/rank_system.dart';
import 'package:questarena/providers/user_providers.dart';
import 'package:questarena/providers/auth_providers.dart';
import 'package:questarena/providers/leaderboard_providers.dart';
import 'package:questarena/data/models/leaderboard_model.dart';
import 'package:questarena/data/models/user_model.dart';
import 'package:questarena/ui/widgets/neon_swirl_background.dart';
import 'package:questarena/ui/widgets/smart_avatar.dart';
import 'package:questarena/ui/widgets/expandable_player_card.dart';
import 'package:questarena/ui/screens/tabs/edit_profile_screen.dart';
import 'package:questarena/ui/screens/tabs/leaderboard_tab.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/achievement_providers.dart';
import '../../../data/models/achievement_model.dart';
import '../../../core/errors/result.dart';
import '../../widgets/animated_coin_counter.dart';
import '../../widgets/bordered_avatar.dart';
import '../avatar_selection_screen.dart';
import '../border_selection_screen.dart';

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
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeIn);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showDeleteConfirmation(BuildContext context, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('DELETE ACCOUNT?', style: AppTextStyles.headline.copyWith(color: AppColors.red)),
        content: const Text('This action is permanent. All your data will be lost.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('CANCEL', style: AppTextStyles.label)),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
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

  Future<void> _reportIssue() async {
    final String subject = Uri.encodeComponent('QuestArena Bug Report');
    final String body = Uri.encodeComponent('Hello, I would like to report an issue: ');
    final Uri mailUri = Uri.parse('mailto:imaginati.appdev@gmail.com?subject=$subject&body=$body');

    try {
      if (!await launchUrl(mailUri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $mailUri';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to open email app. Please email imaginati.appdev@gmail.com directly.'),
            backgroundColor: AppColors.neonPink,
          ),
        );
      }
    }
  }

class _ProfileTabState extends ConsumerState<ProfileTab> {
  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) return const Center(child: Text('User not found'));

        final achievementsAsync = ref.watch(userAchievementsProvider);

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: AppBar(
            title: Text('PLAYER PROFILE', style: AppTextStyles.display.copyWith(fontSize: 18)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.neonPink),
                onPressed: () => ref.read(authRepositoryProvider).logout(),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Header / Profile Section
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow behind avatar
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.gold.withValues(alpha: 0.15),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                    ),
                    Hero(
                      tag: 'selected_avatar',
                      child: BorderedAvatar(
                        avatarUrl: user.avatarUrl,
                        rank: user.rank,
                        size: 110,
                        showGlow: true,
                      ),
                    ),
                  ],
                ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

                const SizedBox(height: 16),
                Text(user.username, style: AppTextStyles.headline),
                Text(user.rank.toUpperCase(), style: AppTextStyles.label.copyWith(color: AppColors.gold, letterSpacing: 2)),

                const SizedBox(height: 12),

                // CHANGE BUTTONS
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AvatarSelectionScreen()),
                        );
                      },
                      icon: const Icon(Icons.person_rounded, size: 16),
                      label: const Text('AVATAR'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.gold,
                        side: const BorderSide(color: AppColors.gold, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const BorderSelectionScreen()),
                        );
                      },
                      icon: const Icon(Icons.workspace_premium_rounded, size: 16),
                      label: const Text('BORDER'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.neonCyan,
                        side: const BorderSide(color: AppColors.neonCyan, width: 1.5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        textStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold, fontSize: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Stats Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ProfileStat(label: 'LEVEL', value: '${user.level}', color: AppColors.purple, icon: Icons.star_rounded),
                    _ProfileStat(label: 'WINS', value: '${user.wins}', color: AppColors.teal, icon: Icons.emoji_events_rounded),
                    Column(
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 24),
                        const SizedBox(height: 8),
                        AnimatedCoinCounter(
                          value: user.coins,
                          style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 18),
                        ),
                        Text('COINS', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                      ],
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 32),

                // Streak Stats
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.surface),
                  ),
                  child: Column(
                    children: [
                      _StreakRow(
                        label: 'Login Streak',
                        value: '${user.loginStreak} Days',
                        icon: Icons.whatshot_rounded,
                        color: AppColors.gold,
                      ),
                      const Divider(color: AppColors.surface, height: 32),
                      _StreakRow(
                        label: 'Current Win Streak',
                        value: '${user.currentWinStreak} Wins',
                        icon: Icons.auto_awesome_rounded,
                        color: AppColors.teal,
                      ),
                      const Divider(color: AppColors.surface, height: 32),
                      _StreakRow(
                        label: 'Highest Win Streak',
                        value: '${user.highestWinStreak} Wins',
                        icon: Icons.emoji_events_rounded,
                        color: AppColors.purple,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 40),

                // Achievement Grid
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ACHIEVEMENTS', style: AppTextStyles.label),
                ),
                const SizedBox(height: 16),
                achievementsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Text('Error: $e'),
                  data: (achievements) => ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: achievements.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final ach = achievements[index];
                      return _AchievementTile(achievement: ach);
                    },
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
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String uid) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('DELETE ACCOUNT?', style: AppTextStyles.headline.copyWith(color: AppColors.red)),
        content: Text(
          'This action is permanent. All your XP, coins, and achievements will be lost forever.',
          style: AppTextStyles.bodyMd,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: AppTextStyles.label),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog

              // 1. Delete Firestore data first
              await ref.read(userRepositoryProvider).deleteUserProfile(uid);

              // 2. Delete Auth account
              final result = await ref.read(authRepositoryProvider).deleteAccount();

              if (context.mounted) {
                if (result case Failure(error: final e)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.message),
                      backgroundColor: AppColors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('DELETE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final Achievement achievement;
  const _AchievementTile({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final bool isUnlocked = achievement.isUnlocked;
    final double progressPercent = (achievement.progress / achievement.target).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.cardBg : AppColors.cardBg.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isUnlocked ? AppColors.gold : AppColors.surface, width: isUnlocked ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUnlocked ? AppColors.gold.withValues(alpha: 0.1) : AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getIcon(achievement.type),
              color: isUnlocked ? AppColors.gold : AppColors.textMuted,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  achievement.title,
                  style: AppTextStyles.bodyMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isUnlocked ? Colors.white : AppColors.textMuted,
                  ),
                ),
                Text(
                  achievement.description,
                  style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textMuted),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressPercent,
                    backgroundColor: AppColors.surface,
                    color: isUnlocked ? AppColors.gold : AppColors.purple,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${achievement.progress}/${achievement.target}',
                      style: AppTextStyles.label.copyWith(fontSize: 9),
                    ),
                    Text(
                      'REWARD: ${achievement.rewardCoins} C',
                      style: AppTextStyles.label.copyWith(
                        fontSize: 9,
                        color: isUnlocked ? AppColors.gold : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIcon(AchievementType type) {
    switch (type) {
      case AchievementType.matchesPlayed:
        return Icons.sports_esports_rounded;
      case AchievementType.matchesWon:
        return Icons.emoji_events_rounded;
      case AchievementType.questionsCorrect:
        return Icons.psychology_rounded;
      case AchievementType.perfectScores:
        return Icons.star_rounded;
      case AchievementType.loginStreak:
        return Icons.whatshot_rounded;
    }
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

class _StreakRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StreakRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

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
            const SizedBox(height: 32),
            const Text('FRIEND REQUESTS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
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
                            onPressed: () => _showConfirmDialog(context, ref, request.id, data, true),
                            icon: const Icon(Icons.check_circle_rounded, color: AppColors.teal),
                          ),
                          IconButton(
                            onPressed: () => _showConfirmDialog(context, ref, request.id, data, false),
                            icon: const Icon(Icons.cancel_rounded, color: AppColors.red),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _showConfirmDialog(BuildContext context, WidgetRef ref, String requestId, Map<String, dynamic> requestData, bool isAccept) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(isAccept ? 'Accept Request?' : 'Decline Request?', style: AppTextStyles.headline.copyWith(fontSize: 18)),
        content: Text('Are you sure you want to ${isAccept ? 'accept' : 'decline'} the friend request from ${requestData['senderUsername']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (isAccept) {
                ref.read(friendsRepositoryProvider).acceptFriendRequest(requestId, requestData);
              } else {
                ref.read(friendsRepositoryProvider).rejectFriendRequest(requestId);
              }
              Navigator.pop(context);
            },
            child: Text(isAccept ? 'Accept' : 'Decline', style: TextStyle(color: isAccept ? AppColors.teal : AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class _FriendsListSection extends ConsumerWidget {
  const _FriendsListSection();
  void _showFriendProfile(BuildContext context, WidgetRef ref, LeaderboardModel friend) {
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
                          Text('LVL ${friend.level} • ${RankSystem.getRankName(friend.rank, friend.subRank)}',
                            style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ExpandedDetails(uid: friend.uid, isMe: false),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('CLOSE', style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                ),
              ],
            ),
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(label, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
        ),
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18, color: color)),
      ],
    );
  }
}
