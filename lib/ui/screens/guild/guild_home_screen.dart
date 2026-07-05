import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/guild_model.dart';
import '../../../providers/guild_providers.dart';
import '../../../providers/user_providers.dart';
import '../../widgets/smart_avatar.dart';
import '../../widgets/expandable_player_card.dart';
import '../../widgets/neon_swirl_background.dart';
import 'guild_battle_card.dart';

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
            title: Text('GUILD HOME', style: AppTextStyles.display.copyWith(fontSize: 18)),
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
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GuildBattleCard(guild: guild),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _GuildHeader(guild: guild),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: _GuildMvpSection(memberUids: guild.memberUids),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 24)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
                    child: Text(
                      'MEMBERS (${guild.memberUids.length})', 
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

              return ExpandablePlayerCard(
                uid: member.uid,
                username: member.username,
                avatarUrl: member.avatarUrl,
                level: member.level,
                xp: member.xp,
                rank: member.rank,
                subRank: member.subRank,
                isMe: isMe,
                isExpanded: _selectedUid == member.uid,
                index: index,
                onTap: () => _toggleProfile(member.uid),
                trailing: isLeader ? const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 20) : null,
              );
            },
            childCount: members.length,
          ),
        );
      },
    );
  }

  Future<void> _confirmLeaveGuild(BuildContext context, WidgetRef ref, GuildModel guild) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: const Text('LEAVE GUILD?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to leave this guild?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('LEAVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final uid = ref.read(currentUserProvider).value?.uid;
      if (uid != null) {
        await ref.read(guildRepositoryProvider).leaveGuild(guild.id, uid);
        if (context.mounted) Navigator.pop(context);
      }
    }
  }
}

class _GuildHeader extends ConsumerWidget {
  final GuildModel guild;
  const _GuildHeader({required this.guild});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final isLeader = user?.uid == guild.leaderUid;
    final membersAsync = ref.watch(guildMembersProvider(guild.memberUids));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: isLeader ? () => _showChangeIconDialog(context, ref, guild) : null,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.neonPink.withValues(alpha: 0.1),
                        border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.5), width: 2),
                      ),
                      child: Icon(_getIconData(guild.iconId), color: AppColors.neonPink, size: 36),
                    ),
                    if (isLeader)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: AppColors.neonPink, shape: BoxShape.circle),
                        child: const Icon(Icons.edit_rounded, size: 12, color: Colors.white),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(guild.name, style: AppTextStyles.headline.copyWith(fontSize: 22)),
                    const SizedBox(height: 2),
                    membersAsync.when(
                      data: (members) {
                        final leader = members.firstWhere((m) => m.uid == guild.leaderUid, orElse: () => members.first);
                        return Text(
                          'LEADER: ${leader.username}',
                          style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.gold, fontWeight: FontWeight.bold),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 4),
                    if (isLeader)
                      Row(
                        children: [
                          Text('CODE: ', style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.textMuted)),
                          Text(guild.code, style: AppTextStyles.label.copyWith(color: AppColors.gold, letterSpacing: 1.5, fontSize: 10, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: guild.code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Guild code copied to clipboard!'), duration: Duration(seconds: 2)),
                              );
                            },
                            child: const Icon(Icons.copy_rounded, size: 12, color: AppColors.gold),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('LVL ${guild.level}', style: AppTextStyles.headline.copyWith(fontSize: 18, color: AppColors.neonCyan)),
                  Text('${guild.memberUids.length} MEMBERS', style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          _GuildXpProgress(xp: guild.xp, level: guild.level),
        ],
      ),
    );
  }

  void _showChangeIconDialog(BuildContext context, WidgetRef ref, GuildModel guild) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text('CHANGE ICON', style: AppTextStyles.headline.copyWith(fontSize: 18, color: AppColors.neonPink)),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: List.generate(6, (i) {
            final id = (i + 1).toString();
            return GestureDetector(
              onTap: () {
                ref.read(guildRepositoryProvider).updateGuildIcon(guild.id, id);
                Navigator.pop(context);
              },
              child: Container(
                width: 50, height: 50,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.surface),
                child: Icon(_getIconData(id), color: AppColors.textMuted, size: 24),
              ),
            );
          }),
        ),
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

class _GuildXpProgress extends StatelessWidget {
  final int xp;
  final int level;
  const _GuildXpProgress({required this.xp, required this.level});

  @override
  Widget build(BuildContext context) {
    final int xpInCurrentLevel = xp % 1000; // Placeholder logic
    final double progress = xpInCurrentLevel / 1000;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('GUILD XP', style: AppTextStyles.label.copyWith(fontSize: 9)),
            Text('$xpInCurrentLevel / 1000', style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 8),
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
                  const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 20),
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
