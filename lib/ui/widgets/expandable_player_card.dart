import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/utils/rank_system.dart';
import '../../data/models/leaderboard_model.dart';
import '../../data/models/user_model.dart';
import '../../providers/guild_providers.dart';
import '../../providers/user_providers.dart';
import '../../providers/navigation_providers.dart';
import 'smart_avatar.dart';

class ExpandablePlayerCard extends ConsumerWidget {
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
  final Widget? badge;

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
    this.badge,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomingRequests = ref.watch(incomingRequestsProvider).value ?? [];
    final receivedRequest = incomingRequests.where(
      (r) => (r.data() as Map<String, dynamic>)['senderUid'] == uid
    ).firstOrNull;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: isExpanded ? 1.02 : 1.0,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(isExpanded ? 20 : 12),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isExpanded ? Colors.white : (isMe ? AppColors.purple : AppColors.surface),
              width: isExpanded ? 1.5 : (isMe ? 1.5 : 1),
            ),
            boxShadow: isExpanded ? [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.1),
                blurRadius: 15,
                spreadRadius: 2,
              )
            ] : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  if (badge != null)
                    SizedBox(width: 40, child: badge!)
                  else
                    const SizedBox(width: 12),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isExpanded)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ).animate().scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 400.ms),
                      SmartAvatar(
                        avatarUrl: avatarUrl,
                        size: isExpanded ? 65 : 45,
                        showBorder: isExpanded,
                        showGlow: false,
                      ),
                    ],
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headline.copyWith(
                            fontSize: isExpanded ? 22 : 18,
                            color: isExpanded ? AppColors.gold : Colors.white,
                          ),
                        ),
                        Text(
                          'LVL $level • ${RankSystem.getRankName(rank, subRank)}',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          _ActionButton(uid: uid, isMe: isMe),
                        ],
                      ],
                    ),
                  ),

                  if (!isExpanded)
                    receivedRequest != null 
                      ? _RespondRow(requestId: receivedRequest.id, requestData: receivedRequest.data() as Map<String, dynamic>)
                      : trailing ?? Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('$xp', style: AppTextStyles.headline.copyWith(fontSize: 20, color: AppColors.gold)),
                          Text('XP', style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textMuted)),
                        ],
                      ),
                ],
              ),

              AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
                alignment: Alignment.topCenter,
                child: isExpanded
                    ? ExpandedDetails(uid: uid, isMe: isMe)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ExpandedDetails extends ConsumerWidget {
  final String uid;
  final bool isMe;

  const ExpandedDetails({super.key, required this.uid, required this.isMe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));

    return profileAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)),
      ),
      error: (e, s) => Text('Error loading stats', style: AppTextStyles.label.copyWith(color: AppColors.red)),
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        final int xpValue = user.xp;
        final int wins = user.wins;
        final int streak = user.currentWinStreak;
        final int matches = user.matchesPlayed;
        final double winRate = user.winRate;

        final achievements = [
          {'id': 'first_win', 'name': 'First Blood', 'icon': Icons.flash_on_rounded},
          {'id': 'on_fire', 'name': 'On Fire', 'icon': Icons.whatshot},
          {'id': 'veteran', 'name': 'Veteran', 'icon': Icons.military_tech},
          {'id': 'scholar', 'name': 'Scholar', 'icon': Icons.school},
          {'id': 'arena_breaker', 'name': 'Arena Breaker', 'icon': Icons.security},
        ];

        final unlockedIds = user.achievements;
        final unlocked = achievements.where((a) => unlockedIds.contains(a['id'])).toList();

        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatItem(icon: Icons.stars_rounded, value: '$xpValue', label: 'XP', color: AppColors.purple),
                    StatItem(icon: Icons.emoji_events_rounded, value: '$wins', label: 'WINS', color: AppColors.teal),
                    StatItem(icon: Icons.whatshot_rounded, value: '$streak', label: 'STREAK', color: AppColors.red),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              OverviewRow(label: 'Matches Played', value: '$matches'),
              OverviewRow(label: 'Win Rate', value: '${winRate.toStringAsFixed(1)}%'),
              OverviewRow(label: 'Current Rank', value: RankSystem.getRankName(user.rank, user.subRank)),
              OverviewRow(label: 'Total XP', value: '$xpValue'),

              if (user.guildId != null) ...[
                const SizedBox(height: 24),
                const Divider(color: AppColors.surface),
                const SizedBox(height: 16),
                _GuildPreview(guildId: user.guildId!, leaderUid: uid),
              ],

              if (unlocked.isNotEmpty) ...[
                const SizedBox(height: 32),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('ACHIEVEMENTS', style: AppTextStyles.label.copyWith(fontSize: 10, letterSpacing: 1.5, color: AppColors.textMuted)),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: unlocked.map((a) => _AchievementChip(icon: a['icon'] as IconData, name: a['name'] as String)).toList(),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatItem({super.key, required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 10),
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 20, color: Colors.white)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class OverviewRow extends StatelessWidget {
  final String label;
  final String value;

  const OverviewRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted, fontSize: 15)),
          Text(value, style: AppTextStyles.headline.copyWith(fontSize: 16, color: Colors.white)),
        ],
      ),
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
        color: AppColors.gold.withValues(alpha: 0.05),
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

class _GuildPreview extends ConsumerWidget {
  final String guildId;
  final String leaderUid;
  const _GuildPreview({required this.guildId, required this.leaderUid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guildAsync = ref.watch(guildByIdProvider(guildId));

    return guildAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (guild) {
        if (guild == null) return const SizedBox.shrink();
        final isLeader = guild.leaderUid == leaderUid;

        return Row(
          children: [
            const Icon(Icons.castle_rounded, color: AppColors.neonPink, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(guild.name, style: AppTextStyles.bodyMd.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(
                    isLeader ? 'Guild Leader' : 'Guild Member',
                    style: AppTextStyles.label.copyWith(fontSize: 10, color: AppColors.neonPink),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: AppColors.neonPink.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(_getGuildIcon(guild.iconId), color: AppColors.neonPink, size: 20),
            ),
          ],
        );
      },
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

class _RespondRow extends ConsumerWidget {
  final String requestId;
  final Map<String, dynamic> requestData;
  const _RespondRow({required this.requestId, required this.requestData});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () => _showConfirmDialog(context, ref, true),
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.teal, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: () => _showConfirmDialog(context, ref, false),
          icon: const Icon(Icons.cancel_rounded, color: AppColors.red, size: 24),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ],
    );
  }

  void _showConfirmDialog(BuildContext context, WidgetRef ref, bool isAccept) {
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

class _ActionButton extends ConsumerWidget {
  final String uid;
  final bool isMe;

  const _ActionButton({required this.uid, required this.isMe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isMe) {
      return ElevatedButton(
        onPressed: () => ref.read(tabIndexProvider.notifier).state = 3,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          minimumSize: const Size(110, 36),
          shape: const StadiumBorder(),
          elevation: 0,
        ),
        child: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
      );
    }

    final friendsAsync = ref.watch(friendsProvider);
    final List<LeaderboardModel> friends = friendsAsync.value ?? [];
    final bool isFriend = friends.any((LeaderboardModel f) => f.uid == uid);
    
    final incomingRequests = ref.watch(incomingRequestsProvider).value ?? [];
    final receivedRequest = incomingRequests.where(
      (r) => (r.data() as Map<String, dynamic>)['senderUid'] == uid
    ).firstOrNull;
    
    final outgoingRequests = ref.watch(outgoingRequestsProvider).value ?? [];
    final sentRequest = outgoingRequests.any(
      (r) => (r.data() as Map<String, dynamic>)['receiverUid'] == uid
    );

    String label = '+ Add Friend';
    Color bgColor = AppColors.purple;
    VoidCallback? onPressed;

    if (isFriend) {
      label = 'Friends';
      bgColor = AppColors.teal.withValues(alpha: 0.2);
      onPressed = () => _showRemoveDialog(context, ref);
    } else if (sentRequest) {
      label = 'Sent';
      bgColor = AppColors.surface;
      onPressed = () => _showCancelDialog(context, ref);
    } else if (receivedRequest != null) {
      label = 'Respond';
      bgColor = AppColors.gold;
      onPressed = () => _showRespondOptions(context, ref, receivedRequest.id, receivedRequest.data());
    } else {
      onPressed = () async {
        final currentUser = ref.read(currentUserProvider).value;
        if (currentUser == null) return;
        
        final playerDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (!playerDoc.exists) return;
        final playerData = playerDoc.data()!;

        await ref.read(friendsRepositoryProvider).sendFriendRequest(
          sender: currentUser,
          receiverUid: uid,
          receiverUsername: playerData['username'],
          receiverAvatar: playerData['avatarUrl'],
        );
      };
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        minimumSize: const Size(110, 36),
        shape: const StadiumBorder(),
        side: isFriend ? const BorderSide(color: AppColors.teal, width: 1) : null,
        elevation: 0,
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }

  void _showCancelDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Cancel Request?', style: AppTextStyles.headline.copyWith(fontSize: 18)),
        content: const Text('Are you sure you want to cancel the sent friend request?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('No')),
          TextButton(
            onPressed: () {
              final currentUid = ref.read(currentUserProvider).value?.uid;
              if (currentUid != null) {
                // Generate the same ID used for sending
                final requestId = [currentUid, uid]..sort();
                final idStr = requestId.join('_');
                ref.read(friendsRepositoryProvider).rejectFriendRequest(idStr);
              }
              Navigator.pop(context);
            },
            child: const Text('Cancel sent?', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _showRespondOptions(BuildContext context, WidgetRef ref, String requestId, Map<String, dynamic> requestData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Friend Request from ${requestData['senderUsername']}', style: AppTextStyles.headline.copyWith(fontSize: 18)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(friendsRepositoryProvider).acceptFriendRequest(requestId, requestData);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal),
                    child: const Text('Accept', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      ref.read(friendsRepositoryProvider).rejectFriendRequest(requestId);
                      Navigator.pop(context);
                    },
                    child: const Text('Decline', style: TextStyle(color: AppColors.red)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRemoveDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Remove Friend?', style: AppTextStyles.headline.copyWith(fontSize: 18)),
        content: const Text('Are you sure you want to remove this friend?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final currentUid = ref.read(currentUserProvider).value?.uid;
              if (currentUid != null) {
                ref.read(friendsRepositoryProvider).removeFriend(currentUid, uid);
              }
              Navigator.pop(context);
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}
