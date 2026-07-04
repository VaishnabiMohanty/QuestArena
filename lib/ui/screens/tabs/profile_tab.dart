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

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) return const Center(child: Text('User not found'));

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('PROFILE', style: AppTextStyles.display.copyWith(fontSize: 18, letterSpacing: 4)),
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
                      // CLEAN HEADER
                      Center(
                        child: SmartAvatar(avatarUrl: user.avatarUrl, size: 120, showGlow: true, showBorder: true),
                      ),
                      const SizedBox(height: 20),
                      Text(user.username.toUpperCase(), style: AppTextStyles.headline.copyWith(fontSize: 28, letterSpacing: 2)),
                      const SizedBox(height: 24),

                      // UNIFIED EDIT BUTTON (Purple as requested)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                          icon: const Icon(Icons.tune_rounded, size: 20, color: Colors.white),
                          label: const Text('EDIT PROFILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            elevation: 8,
                            shadowColor: AppColors.purple.withValues(alpha: 0.4),
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // UNIFIED ANALYTICS CARD
                      _buildAnalyticsSection(user),

                      const SizedBox(height: 32),

                      // SOCIAL SECTION
                      const _FriendRequestsSection(),
                      const _FriendsListSection(),

                      const SizedBox(height: 40),

                      // SUPPORT CARD
                      _buildSupportSection(),

                      const SizedBox(height: 48),

                      // DELETE ACCOUNT
                      TextButton.icon(
                        onPressed: () => _showDeleteConfirmation(context, user.uid),
                        icon: const Icon(Icons.delete_forever_rounded, color: AppColors.red, size: 20),
                        label: Text(
                          'DELETE ACCOUNT',
                          style: AppTextStyles.label.copyWith(color: AppColors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 32),
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

  Widget _buildAnalyticsSection(UserModel user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.surface),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('PERFORMANCE ANALYTICS', style: AppTextStyles.label.copyWith(letterSpacing: 2, color: AppColors.gold, fontWeight: FontWeight.w900)),
          const SizedBox(height: 24),
          
          // Primary Stats Grid - Fixed AspectRatio for better fit
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.8, // Decreased from 2.1 to make items TALLER
            children: [
              _AnalyticsItem(label: 'TOTAL XP', value: '${user.xp}', color: AppColors.purple, icon: Icons.stars_rounded),
              _AnalyticsItem(label: 'COINS', value: '${user.coins}', color: AppColors.gold, icon: Icons.monetization_on_rounded),
              _AnalyticsItem(label: 'WINS', value: '${user.wins}', color: AppColors.teal, icon: Icons.emoji_events_rounded),
              _AnalyticsItem(label: 'STREAK', value: '${user.currentWinStreak}', color: AppColors.red, icon: Icons.whatshot_rounded),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Divider(color: AppColors.surface, height: 1),
          ),

          // Secondary Stats Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ProfileStatItem(label: 'MATCHES', value: '${user.matchesPlayed}'),
              _ProfileStatItem(label: 'WIN RATE', value: '${user.winRate.toStringAsFixed(1)}%'),
              _ProfileStatItem(label: 'DRAWS', value: '${user.draws}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.neonPink.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.help_center_rounded, color: AppColors.neonPink, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NEED ASSISTANCE?', style: AppTextStyles.headline.copyWith(fontSize: 16)),
                    Text('Contact our development team', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SupportButton(
            icon: Icons.bug_report_rounded,
            label: 'REPORT AN ISSUE',
            color: AppColors.neonPink,
            onTap: _reportIssue,
          ),
          const SizedBox(height: 12),
          Text(
            'Email: imaginati.appdev@gmail.com',
            style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _AnalyticsItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _AnalyticsItem({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label, 
                  style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: AppTextStyles.headline.copyWith(fontSize: 22, color: Colors.white)),
            ),
          ),
        ],
      ),
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
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 16)),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _SupportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SupportButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: color.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.label.copyWith(color: color, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
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
        const SizedBox(height: 32),
        const Text('FRIENDS', style: TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 16),
        friendsAsync.when(
          loading: () => const SizedBox(height: 100, child: Center(child: CircularProgressIndicator())),
          error: (e, s) => Text('Error: $e'),
          data: (friends) {
            if (friends.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text('You haven\'t added any friends yet.', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted, fontSize: 12)),
              );
            }
            return SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return GestureDetector(
                    onTap: () => _showFriendProfile(context, ref, friend),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SmartAvatar(avatarUrl: friend.avatarUrl, size: 50),
                          const SizedBox(height: 8),
                          Text(
                            friend.username,
                            style: AppTextStyles.bodyMd.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
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
