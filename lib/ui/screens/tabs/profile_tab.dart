import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/rank_system.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/guild_providers.dart';
import '../../../data/models/user_model.dart';
import '../../../data/models/guild_model.dart';
import '../../widgets/neon_swirl_background.dart';
import '../../widgets/smart_avatar.dart';
import '../../widgets/player_profile_dialog.dart';
import 'edit_profile_screen.dart';
import '../guild/guild_home_screen.dart';
import '../guild/guild_dialogs.dart';

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
                  _ProfileGuildSection(user: user),
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

class _ProfileGuildSection extends ConsumerWidget {
  final UserModel user;
  const _ProfileGuildSection({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Case 1: User is already in a guild
    if (user.guildId != null) {
      final guildAsync = ref.watch(userGuildProvider);
      return guildAsync.when(
        data: (guild) {
          if (guild == null) return const _NoGuildCard();
          return _GuildInformationCard(guild: guild);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const _NoGuildCard(),
      );
    }

    // Case 2 & 3: Not in a guild, check for invitations
    final invitesAsync = ref.watch(guildInvitationsProvider);
    return invitesAsync.when(
      data: (invites) {
        if (invites.isNotEmpty) {
          return _GuildInvitationsCarousel(invites: invites);
        }
        return const _NoGuildCard();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const _NoGuildCard(),
    );
  }
}

class _GuildInformationCard extends ConsumerWidget {
  final GuildModel guild;
  const _GuildInformationCard({required this.guild});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildHomeScreen())),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.3), width: 1.5),
          boxShadow: [
            BoxShadow(color: AppColors.neonPink.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.neonPink.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.3)),
                  ),
                  child: Icon(_getGuildIcon(guild.iconId), color: AppColors.neonPink, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(guild.name.toUpperCase(), style: AppTextStyles.headline.copyWith(fontSize: 20, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.gold, size: 14),
                          const SizedBox(width: 4),
                          Text('LEVEL ${guild.level}', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
            const SizedBox(height: 20),
            const _GuildLeaderInfo(),
            const SizedBox(height: 20),
            _GuildXpProgressBar(xp: guild.xp),
          ],
        ),
      ),
    );
  }

  IconData _getGuildIcon(String id) {
    switch (id) {
      case '1': return Icons.auto_awesome_rounded;
      case '2': return Icons.military_tech_rounded;
      case '3': return Icons.shield_rounded;
      case '4': return Icons.bolt_rounded;
      case '5': return Icons.workspace_premium_rounded;
      case '6': return Icons.pets_rounded;
      default: return Icons.groups_rounded;
    }
  }
}

class _NoGuildCard extends StatelessWidget {
  const _NoGuildCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.castle_rounded, color: AppColors.textMuted, size: 48),
          const SizedBox(height: 16),
          Text('NOT CURRENTLY IN A GUILD', style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
          const SizedBox(height: 12),
          Text(
            'Join a guild to participate in exclusive battles and climb the ranks with your team.',
            style: AppTextStyles.label.copyWith(fontSize: 11, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) => OutlinedButton(
                    onPressed: () => showJoinGuildDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.neonCyan),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('JOIN', style: TextStyle(color: AppColors.neonCyan, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) => ElevatedButton(
                    onPressed: () => showCreateGuildDialog(context, ref),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonPink,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('CREATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuildInvitationsCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> invites;
  const _GuildInvitationsCarousel({required this.invites});

  @override
  State<_GuildInvitationsCarousel> createState() => _GuildInvitationsCarouselState();
}

class _GuildInvitationsCarouselState extends State<_GuildInvitationsCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('PENDING INVITATIONS', style: AppTextStyles.label.copyWith(letterSpacing: 2, fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neonCyan)),
            if (widget.invites.length > 1)
              Text('${_currentPage + 1}/${widget.invites.length}', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: widget.invites.length,
            itemBuilder: (context, index) => _InvitationCard(invite: widget.invites[index]),
          ),
        ),
      ],
    );
  }
}

class _InvitationCard extends ConsumerWidget {
  final Map<String, dynamic> invite;
  const _InvitationCard({required this.invite});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: AppColors.neonCyan.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.neonCyan.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(_getGuildIcon(invite['guildIconId']), color: AppColors.neonCyan, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(invite['guildName'].toUpperCase(), style: AppTextStyles.headline.copyWith(fontSize: 18, letterSpacing: 1)),
                    Text('Invited by @${invite['senderName']}', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => ref.read(guildRepositoryProvider).declineInvitation(invite['id']),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('DECLINE', style: TextStyle(color: AppColors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => ref.read(guildRepositoryProvider).acceptInvitation(invite['id'], user!.uid),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonCyan,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('JOIN GUILD', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getGuildIcon(String id) {
    switch (id) {
      case '1': return Icons.auto_awesome_rounded;
      case '2': return Icons.military_tech_rounded;
      case '3': return Icons.shield_rounded;
      case '4': return Icons.bolt_rounded;
      case '5': return Icons.workspace_premium_rounded;
      case '6': return Icons.pets_rounded;
      default: return Icons.groups_rounded;
    }
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
                  return GestureDetector(
                    onTap: () => PlayerProfileDialog.show(context, uid: friend.uid, player: friend, isMe: false),
                    child: Container(
                      width: 80,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          SmartAvatar(avatarUrl: friend.avatarUrl, size: 50),
                          const SizedBox(height: 8),
                          Text(friend.username, style: AppTextStyles.bodyMd.copyWith(fontSize: 10, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
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

class _GuildLeaderInfo extends ConsumerWidget {
  const _GuildLeaderInfo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guildAsync = ref.watch(userGuildProvider);
    return guildAsync.when(
      data: (guild) {
        if (guild == null) return const SizedBox.shrink();
        final leaderAsync = ref.watch(userProfileProvider(guild.leaderUid));
        return leaderAsync.when(
          data: (leader) {
            if (leader == null) return const SizedBox.shrink();
            return Row(
              children: [
                Text('LEADER: ', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                Text('@${leader.username}', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.bold)),
              ],
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _GuildXpProgressBar extends StatelessWidget {
  final int xp;
  const _GuildXpProgressBar({required this.xp});

  @override
  Widget build(BuildContext context) {
    final int xpInLevel = xp % 1000;
    final double progress = xpInLevel / 1000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('GUILD XP', style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.textSecondary)),
            Text('$xpInLevel / 1000', style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation(AppColors.neonPink),
          ),
        ),
      ],
    );
  }
}
