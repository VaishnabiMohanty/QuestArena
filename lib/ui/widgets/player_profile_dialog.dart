import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/utils/rank_system.dart';
import '../../data/models/leaderboard_model.dart';
import '../../data/models/user_model.dart';
import '../../providers/user_providers.dart';
import '../../providers/navigation_providers.dart';
import 'smart_avatar.dart';

class PlayerProfileDialog extends ConsumerWidget {
  final String uid;
  final LeaderboardModel? player;
  final bool isMe;

  const PlayerProfileDialog({
    super.key,
    required this.uid,
    this.player,
    required this.isMe,
  });

  static void show(BuildContext context, {required String uid, LeaderboardModel? player, required bool isMe}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => PlayerProfileDialog(uid: uid, player: player, isMe: isMe),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(uid));

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: profileAsync.when(
        loading: () => Container(
          height: 200,
          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(28)),
          child: const Center(child: CircularProgressIndicator(color: AppColors.gold)),
        ),
        error: (e, s) => Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(28)),
          child: Text('Error: $e', style: const TextStyle(color: Colors.white)),
        ),
        data: (user) {
          final username = user?.username ?? player?.username ?? 'Unknown';
          final avatarUrl = user?.avatarUrl ?? player?.avatarUrl;
          final rank = user?.rank ?? player?.rank ?? 'Unranked';
          final subRank = user?.subRank ?? player?.subRank;
          final level = user?.level ?? player?.level ?? 1;

          return Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: AppColors.surface, width: 1.5),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER: Avatar
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: isMe ? AppColors.purple.withValues(alpha: 0.2) : AppColors.gold.withValues(alpha: 0.15),
                              blurRadius: 30,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                      SmartAvatar(
                        avatarUrl: avatarUrl,
                        size: 100,
                        showBorder: true,
                        showGlow: false,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),

                  // USERNAME
                  Text(
                    username.toUpperCase(),
                    style: AppTextStyles.headline.copyWith(fontSize: 24, letterSpacing: 2),
                    textAlign: TextAlign.center,
                  ),
                  
                  const SizedBox(height: 8),

                  // RANK / LEVEL
                  Text(
                    'LVL $level • ${RankSystem.getRankName(rank, subRank)}',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.gold,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 32),

                  // STATISTICS CARD
                  _buildStatsCard(user, player),

                  const SizedBox(height: 32),

                  // BUTTONS
                  Row(
                    children: [
                      Expanded(
                        child: _FriendActionButton(uid: uid, isMe: isMe, username: username, avatarUrl: avatarUrl),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            minimumSize: const Size(0, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('CLOSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(UserModel? user, LeaderboardModel? player) {
    final xp = user?.xp ?? player?.xp ?? 0;
    final wins = user?.wins ?? player?.wins ?? 0;
    final streak = user?.currentWinStreak ?? player?.currentWinStreak ?? 0;
    final matches = user?.matchesPlayed ?? player?.totalMatches ?? 0;
    final winRate = user?.winRate ?? player?.winRate ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface.withValues(alpha: 0.5)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surface.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(icon: Icons.stars_rounded, value: '$xp', label: 'XP', color: AppColors.purple),
              _StatItem(icon: Icons.emoji_events_rounded, value: '$wins', label: 'WINS', color: AppColors.teal),
              _StatItem(icon: Icons.whatshot_rounded, value: '$streak', label: 'STREAK', color: AppColors.red),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: AppColors.surface, height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(label: 'MATCHES', value: '$matches'),
              _MiniStat(label: 'WIN RATE', value: '${winRate.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatItem({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18, color: Colors.white)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 16, color: Colors.white)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textMuted, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _FriendActionButton extends ConsumerWidget {
  final String uid;
  final bool isMe;
  final String username;
  final String? avatarUrl;

  const _FriendActionButton({required this.uid, required this.isMe, required this.username, this.avatarUrl});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isMe) {
      return ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
          ref.read(tabIndexProvider.notifier).state = 3; // Go to Profile tab
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          minimumSize: const Size(0, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: const Text('PROFILE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      );
    }

    final friends = ref.watch(friendsProvider).value ?? [];
    final isFriend = friends.any((f) => f.uid == uid);
    
    final incomingRequests = ref.watch(incomingRequestsProvider).value ?? [];
    final receivedRequest = incomingRequests.any((r) => (r.data() as Map<String, dynamic>)['senderUid'] == uid);
    
    final outgoingRequests = ref.watch(outgoingRequestsProvider).value ?? [];
    final sentRequest = outgoingRequests.any((r) => (r.data() as Map<String, dynamic>)['receiverUid'] == uid);

    String label = 'ADD FRIEND';
    Color bgColor = AppColors.neonCyan;
    VoidCallback? onPressed;

    if (isFriend) {
      label = 'FRIENDS';
      bgColor = AppColors.teal;
      onPressed = () => _showRemoveFriendDialog(context, ref);
    } else if (sentRequest) {
      label = 'REQUEST SENT';
      bgColor = AppColors.surface;
      onPressed = () => _showCancelRequestDialog(context, ref);
    } else if (receivedRequest) {
      label = 'RESPOND';
      bgColor = AppColors.gold;
      onPressed = () {
        // Find the request to pass data
        final request = incomingRequests.firstWhere((r) => (r.data() as Map<String, dynamic>)['senderUid'] == uid);
        _showRespondOptions(context, ref, request.id, request.data() as Map<String, dynamic>);
      };
    } else {
      onPressed = () async {
        final currentUser = ref.read(currentUserProvider).value;
        if (currentUser == null) return;
        
        await ref.read(friendsRepositoryProvider).sendFriendRequest(
          sender: currentUser,
          receiverUid: uid,
          receiverUsername: username,
          receiverAvatar: avatarUrl,
        );
      };
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        padding: const EdgeInsets.symmetric(horizontal: 8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: bgColor == AppColors.neonCyan ? Colors.black : Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  void _showCancelRequestDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('CANCEL REQUEST?', style: AppTextStyles.headline.copyWith(fontSize: 18)),
        content: const Text('Are you sure you want to cancel this friend request?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('NO')),
          ElevatedButton(
            onPressed: () async {
              final currentUid = ref.read(currentUserProvider).value?.uid;
              if (currentUid != null) {
                // Generate the ID used for friend requests: sort([uid1, uid2]).join('_')
                final ids = [currentUid, uid]..sort();
                final requestId = ids.join('_');
                await ref.read(friendsRepositoryProvider).rejectFriendRequest(requestId);
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('YES, CANCEL', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRemoveFriendDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('REMOVE FRIEND?', style: AppTextStyles.headline.copyWith(fontSize: 18)),
        content: Text('Are you sure you want to remove $username from your friends?', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final currentUid = ref.read(currentUserProvider).value?.uid;
              if (currentUid != null) {
                await ref.read(friendsRepositoryProvider).removeFriend(currentUid, uid);
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red),
            child: const Text('UNFRIEND', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRespondOptions(BuildContext context, WidgetRef ref, String requestId, Map<String, dynamic> requestData) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('FRIEND REQUEST', style: AppTextStyles.headline.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text('from $username', style: AppTextStyles.label),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(friendsRepositoryProvider).acceptFriendRequest(requestId, requestData);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.teal, minimumSize: const Size(0, 56)),
                    child: const Text('ACCEPT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(friendsRepositoryProvider).rejectFriendRequest(requestId);
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.red),
                      minimumSize: const Size(0, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('DECLINE', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
