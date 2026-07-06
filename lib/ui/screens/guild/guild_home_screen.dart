import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/utils/share_utils.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/rank_system.dart';
import '../../../data/models/guild_model.dart';
import '../../../providers/guild_providers.dart';
import '../../../providers/user_providers.dart';
import '../../widgets/smart_avatar.dart';
import '../../widgets/player_profile_dialog.dart';
import '../../widgets/neon_swirl_background.dart';
import 'guild_battle_card.dart';
import 'guild_dialogs.dart';

class GuildHomeScreen extends ConsumerStatefulWidget {
  const GuildHomeScreen({super.key});

  @override
  ConsumerState<GuildHomeScreen> createState() => _GuildHomeScreenState();
}

class _GuildHomeScreenState extends ConsumerState<GuildHomeScreen> {
  String? _selectedUid;

  void _toggleProfile(String uid) {
    setState(() {
      _selectedUid = (_selectedUid == uid) ? null : uid;
    });
  }

  @override
  Widget build(BuildContext context) {
    final guildAsync = ref.watch(userGuildProvider);
    final user = ref.watch(currentUserProvider).value;

    return guildAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (guild) {
        if (guild == null || (user != null && !guild.memberUids.contains(user.uid))) {
          return const Scaffold(body: Center(child: Text('Guild not found or membership invalid')));
        }

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.neonCyan),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('GUILD HOME', style: AppTextStyles.display.copyWith(fontSize: 18, letterSpacing: 2)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: AppColors.red),
                onPressed: () => _confirmLeaveGuild(context, ref, guild),
              ),
            ],
          ),
          body: NeonSwirlBackground(
            colors: const [AppColors.neonPink, AppColors.neonViolet],
            child: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                
                // 1. GUILD INFORMATION HEADER
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _GuildHeader(guild: guild),
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 2. WEEKLY GUILD MVP
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _GuildMvpSection(memberUids: guild.memberUids),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 3. GUILD BATTLE CARD
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GuildBattleCard(guild: guild),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // 4. INVITE SECTION
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _InviteSection(guild: guild),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),

                // 5. MEMBERS SECTION
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
                    child: Text(
                      'MEMBERS (${guild.memberUids.length}/20)', 
                      style: AppTextStyles.label.copyWith(letterSpacing: 2, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: _buildMembersList(ref, guild),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMembersList(WidgetRef ref, GuildModel guild) {
    final membersAsync = ref.watch(guildMembersProvider(guild.memberUids));

    return membersAsync.when(
      loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
      error: (e, s) => SliverToBoxAdapter(child: Text('Error: $e')),
      data: (members) {
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final member = members[index];
              final isMe = member.uid == ref.read(currentUserProvider).value?.uid;
              final isLeader = member.uid == guild.leaderUid;

              return GestureDetector(
                onTap: () => PlayerProfileDialog.show(context, uid: member.uid, isMe: isMe),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surface),
                  ),
                  child: Row(
                    children: [
                      SmartAvatar(avatarUrl: member.avatarUrl, size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(member.username, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                                if (isLeader) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 14),
                                ],
                              ],
                            ),
                            Text(isLeader ? 'Leader' : 'Member', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.gold)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('LVL ${member.level}', style: AppTextStyles.label.copyWith(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                          Row(
                            children: [
                              const Icon(Icons.shield_rounded, size: 10, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(RankSystem.getRankName(member.rank, member.subRank), style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
            childCount: members.length,
          ),
        );
      },
    );
  }

  Future<void> _confirmLeaveGuild(BuildContext context, WidgetRef ref, GuildModel guild) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final isLeader = guild.leaderUid == user.uid;
    final hasOtherMembers = guild.memberUids.length > 1;

    if (isLeader && hasOtherMembers) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('CANNOT LEAVE GUILD', style: AppTextStyles.headline.copyWith(color: AppColors.red, fontSize: 18)),
          content: const Text(
            'As the leader, you cannot leave the guild while there are other members. Please transfer leadership to another member or delete the guild first.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('UNDERSTOOD', style: TextStyle(color: AppColors.neonCyan)),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isLeader ? 'DELETE GUILD?' : 'LEAVE GUILD?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          isLeader 
            ? 'Are you sure you want to delete this guild? This action is permanent.' 
            : 'Are you sure you want to leave this guild?', 
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(isLeader ? 'DELETE' : 'LEAVE', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(guildRepositoryProvider).leaveGuild(guild.id, user.uid);
      if (context.mounted) Navigator.pop(context);
    }
  }
}

class _GuildHeader extends ConsumerWidget {
  final GuildModel guild;
  const _GuildHeader({required this.guild});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(guildMembersProvider(guild.memberUids));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.surface, width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // GUILD ICON
              Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.shield, color: AppColors.neonPink.withValues(alpha: 0.1), size: 80),
                  Icon(Icons.shield_outlined, color: AppColors.neonPink.withValues(alpha: 0.5), size: 80),
                  Icon(_getIconData(guild.iconId), color: AppColors.neonPink, size: 36),
                ],
              ),
              const SizedBox(width: 16),
              // GUILD DETAILS
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guild.name, style: AppTextStyles.headline.copyWith(fontSize: 24, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text('LEVEL ${guild.level}', style: AppTextStyles.label.copyWith(color: AppColors.neonCyan, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 4),
                    membersAsync.when(
                      data: (members) {
                        final leader = members.firstWhere((m) => m.uid == guild.leaderUid, orElse: () => members.first);
                        return Text(
                          'Leader: ${leader.username}',
                          style: AppTextStyles.label.copyWith(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.bold),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _GuildXpProgress(xp: guild.xp, level: guild.level),
        ],
      ),
    );
  }

  IconData _getIconData(String id) {
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

class _InviteSection extends ConsumerWidget {
  final GuildModel guild;
  const _InviteSection({required this.guild});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.account_circle_outlined, color: AppColors.neonCyan, size: 20),
              const SizedBox(width: 8),
              Text('INVITE TO GUILD', style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Invite your friends and grow your guild together!',
            style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _InviteActionButton(
                  icon: Icons.person_add_alt_1_rounded,
                  label: 'INVITE FRIENDS',
                  color: AppColors.neonCyan,
                  onTap: () => showInviteFriendsBottomSheet(context, ref, guild),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InviteActionButton(
                  icon: Icons.share_rounded,
                  label: 'SHARE CODE',
                  color: AppColors.purple,
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: guild.code));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Code copied!')));
                    SharePlus.instance.share(
                      ShareParams(text: ShareUtils.buildGuildShareMessage(guild.name, guild.code)),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InviteActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _InviteActionButton({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.label.copyWith(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

class _GuildXpProgress extends StatelessWidget {
  final int xp;
  final int level;
  const _GuildXpProgress({required this.xp, required this.level});

  @override
  Widget build(BuildContext context) {
    final int xpInCurrentLevel = xp % 1000;
    final double progress = xpInCurrentLevel / 1000;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('GUILD XP', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            Text('$xpInCurrentLevel / 1000', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: AppColors.surface,
            valueColor: const AlwaysStoppedAnimation(AppColors.neonPink),
          ),
        ),
      ],
    );
  }
}

class _GuildMvpSection extends ConsumerWidget {
  final List<String> memberUids;
  const _GuildMvpSection({required this.memberUids});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mvpAsync = ref.watch(guildMvpProvider(memberUids));

    return mvpAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (mvp) {
        if (mvp == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: AppColors.gold.withValues(alpha: 0.1), blurRadius: 15, spreadRadius: 1),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'WEEKLY GUILD MVP', 
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.gold, 
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 60, height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: AppColors.gold.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2),
                          ],
                        ),
                      ),
                      SmartAvatar(avatarUrl: mvp.avatarUrl, size: 55, showBorder: true),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(mvp.username, style: AppTextStyles.headline.copyWith(fontSize: 18, color: Colors.white)),
                        Text('GUILD CONTRIBUTION', style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${mvp.weeklyXp} XP', style: AppTextStyles.headline.copyWith(fontSize: 16, color: AppColors.gold)),
                      Text('${mvp.weeklyWins} WINS', style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.teal, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
