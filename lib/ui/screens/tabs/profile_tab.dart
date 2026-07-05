import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/neon_swirl_background.dart';
import '../../widgets/smart_avatar.dart';
import 'edit_profile_screen.dart';

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

  void _showDeleteConfirmation(String uid) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('DELETE ACCOUNT?', style: AppTextStyles.headline.copyWith(color: AppColors.red)),
        content: const Text('This action is permanent. All your data will be lost.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(userRepositoryProvider).deleteUserProfile(uid);
              await ref.read(authRepositoryProvider).deleteAccount();
            },
            child: const Text('DELETE', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const Center(child: CircularProgressIndicator());

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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  SmartAvatar(avatarUrl: user.avatarUrl, size: 120, showGlow: true, showBorder: true),
                  const SizedBox(height: 16),
                  Text(user.username.toUpperCase(), style: AppTextStyles.headline.copyWith(fontSize: 26, letterSpacing: 2)),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen())),
                      icon: const Icon(Icons.tune_rounded, size: 20, color: Colors.white),
                      label: const Text('EDIT PROFILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 4,
                        shadowColor: AppColors.purple.withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildAnalyticsGrid(user),
                  const SizedBox(height: 32),
                  const _FriendRequestsSection(),
                  const _FriendsListSection(),
                  const SizedBox(height: 32),
                  _buildSupportCard(),
                  const SizedBox(height: 48),
                  TextButton.icon(
                    onPressed: () => _showDeleteConfirmation(user.uid),
                    icon: const Icon(Icons.delete_forever_rounded, color: AppColors.red, size: 20),
                    label: Text('DELETE ACCOUNT', style: AppTextStyles.label.copyWith(color: AppColors.red, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsGrid(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ANALYTICS', style: AppTextStyles.label.copyWith(color: AppColors.gold, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.7,
            children: [
              _StatItem(icon: Icons.stars_rounded, label: 'TOTAL XP', value: '${user.xp}', color: AppColors.purple),
              _StatItem(icon: Icons.monetization_on_rounded, label: 'COINS', value: '${user.coins}', color: AppColors.gold),
              _StatItem(icon: Icons.emoji_events_rounded, label: 'WINS', value: '${user.wins}', color: AppColors.teal),
              _StatItem(icon: Icons.whatshot_rounded, label: 'STREAK', value: '${user.currentWinStreak}', color: AppColors.red),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.surface, height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SimpleStat(label: 'MATCHES', value: '${user.matchesPlayed}'),
              _SimpleStat(label: 'WIN RATE', value: '${user.winRate.toStringAsFixed(1)}%'),
              _SimpleStat(label: 'DRAWS', value: '${user.draws}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
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
              Icon(Icons.help_outline_rounded, color: AppColors.neonPink.withValues(alpha: 0.8), size: 24),
              const SizedBox(width: 16),
              Text('SUPPORT', style: AppTextStyles.headline.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _reportIssue,
              icon: const Icon(Icons.bug_report_rounded, color: AppColors.neonPink),
              label: const Text('REPORT AN ISSUE', style: TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.neonPink),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('imaginati.appdev@gmail.com', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatItem({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _SimpleStat extends StatelessWidget {
  final String label;
  final String value;
  const _SimpleStat({required this.label, required this.value});

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
            Text('FRIEND REQUESTS', style: AppTextStyles.label.copyWith(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...requests.map((request) {
              final data = request.data();
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.surface)),
                child: Row(
                  children: [
                    SmartAvatar(avatarUrl: data['senderAvatar'], size: 40),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['senderUsername'], style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)), Text('Sent a request', style: AppTextStyles.label.copyWith(fontSize: 10))])),
                    IconButton(onPressed: () => ref.read(friendsRepositoryProvider).acceptFriendRequest(request.id, data), icon: const Icon(Icons.check_circle_rounded, color: AppColors.teal)),
                    IconButton(onPressed: () => ref.read(friendsRepositoryProvider).rejectFriendRequest(request.id), icon: const Icon(Icons.cancel_rounded, color: AppColors.red)),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _FriendsListSection extends ConsumerWidget {
  const _FriendsListSection();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text('FRIENDS', style: AppTextStyles.label.copyWith(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        friendsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error: $e'),
          data: (friends) {
            if (friends.isEmpty) return Padding(padding: const EdgeInsets.symmetric(vertical: 20), child: Text('No friends added yet', style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted, fontSize: 12)));
            return SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: friends.length,
                itemBuilder: (context, index) {
                  final friend = friends[index];
                  return Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        SmartAvatar(avatarUrl: friend.avatarUrl, size: 50),
                        const SizedBox(height: 8),
                        Text(friend.username, style: AppTextStyles.bodyMd.copyWith(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
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
