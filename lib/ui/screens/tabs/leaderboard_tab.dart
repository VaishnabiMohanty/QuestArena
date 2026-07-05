import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/leaderboard_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/leaderboard_providers.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/navigation_providers.dart';
import '../../../core/utils/rank_system.dart';
import '../../widgets/bordered_avatar.dart';

class LeaderboardTab extends ConsumerStatefulWidget {
  const LeaderboardTab({super.key});

  @override
  ConsumerState<LeaderboardTab> createState() => _LeaderboardTabState();
}

class _LeaderboardTabState extends ConsumerState<LeaderboardTab> {
  String? _selectedUid;
  bool _isGlobal = true;

  void _toggleProfile(String uid) {
    setState(() {
      if (_selectedUid == uid) {
        _selectedUid = null;
      } else {
        _selectedUid = uid;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(leaderboardProvider);
    final friendsAsync = ref.watch(friendsProvider);
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text('RANKINGS', style: AppTextStyles.display.copyWith(fontSize: 20)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Tab Toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surface),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isGlobal = true),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isGlobal ? AppColors.purple : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text('GLOBAL', style: AppTextStyles.label.copyWith(
                          color: _isGlobal ? Colors.white : AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                        )),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isGlobal = false),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_isGlobal ? AppColors.purple : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Text('FRIENDS', style: AppTextStyles.label.copyWith(
                          color: !_isGlobal ? Colors.white : AppColors.textMuted,
                          fontWeight: FontWeight.bold,
                        )),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isGlobal
              ? _buildLeaderboard(leaderboardAsync, currentUser)
              : _buildFriendsLeaderboard(friendsAsync, currentUser),
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
        final topPlayer = players.isNotEmpty ? players.first : null;

        return CustomScrollView(
          slivers: [
            if (topPlayer != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: _TopPlayerCard(player: topPlayer),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                child: Text('TOP PLAYERS', style: AppTextStyles.label.copyWith(letterSpacing: 2, color: AppColors.textSecondary)),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final player = players[index];
                    final isMe = player.uid == currentUser?.uid;
                    final isExpanded = _selectedUid == player.uid;

                    return _ExpandablePlayerCard(
                      player: player,
                      isMe: isMe,
                      isExpanded: isExpanded,
                      index: index,
                      onTap: () => _toggleProfile(player.uid),
                    );
                  },
                  childCount: players.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      },
    );
  }

  Widget _buildFriendsLeaderboard(AsyncValue<List<LeaderboardModel>> friendsAsync, UserModel? currentUser) {
    return friendsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (friends) {
        final List<LeaderboardModel> list = [];
        if (currentUser != null) {
          list.add(LeaderboardModel(
            uid: currentUser.uid,
            username: currentUser.username,
            avatarUrl: currentUser.avatarUrl,
            level: currentUser.level,
            xp: currentUser.xp,
            rank: currentUser.rank,
            subRank: currentUser.subRank,
            wins: currentUser.wins,
            losses: currentUser.losses,
            draws: currentUser.draws,
            currentWinStreak: currentUser.currentWinStreak,
            averageAccuracy: currentUser.averageAccuracy,
            eloRating: currentUser.eloRating,
            selectedBorder: currentUser.selectedBorder,
          ));
        }
        list.addAll(friends);
        list.sort((a, b) => b.xp.compareTo(a.xp));

        if (friends.isEmpty && list.length <= 1) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_add_rounded, size: 64, color: AppColors.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'Add friends to compare your progress and compete together.',
                    style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final player = list[index];
                    final isMe = player.uid == currentUser?.uid;
                    final isExpanded = _selectedUid == player.uid;

                    return _ExpandablePlayerCard(
                      player: player,
                      isMe: isMe,
                      isExpanded: isExpanded,
                      index: index,
                      onTap: () => _toggleProfile(player.uid),
                    );
                  },
                  childCount: list.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        );
      },
    );
  }
}

class _ExpandablePlayerCard extends ConsumerWidget {
  final LeaderboardModel player;
  final bool isMe;
  final bool isExpanded;
  final int index;
  final VoidCallback onTap;

  const _ExpandablePlayerCard({
    required this.player,
    required this.isMe,
    required this.isExpanded,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                  SizedBox(
                    width: 40,
                    child: _RankBadge(index: index),
                  ),

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
                      BorderedAvatar(
                        avatarUrl: player.avatarUrl,
                        borderId: player.selectedBorder,
                        size: isExpanded ? 65 : 45,
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
                          player.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.headline.copyWith(
                            fontSize: isExpanded ? 22 : 18,
                            color: isExpanded ? AppColors.gold : Colors.white,
                          ),
                        ),
                        Text(
                          'LVL ${player.level} • ${RankSystem.getRankName(player.rank, player.subRank)}',
                          style: AppTextStyles.label.copyWith(
                            fontSize: 10,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          _ActionButton(uid: player.uid, isMe: isMe),
                        ],
                      ],
                    ),
                  ),

                  if (!isExpanded)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${player.xp}', style: AppTextStyles.headline.copyWith(fontSize: 20, color: AppColors.gold)),
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
                    ? ExpandedDetails(uid: player.uid, player: player, isMe: isMe)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 30)).slideX(begin: 0.05, end: 0);
  }
}

class ExpandedDetails extends ConsumerWidget {
  final String uid;
  final LeaderboardModel player;
  final bool isMe;

  const ExpandedDetails({super.key, required this.uid, required this.player, required this.isMe});

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

        final int xp = user.xp;
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
                    StatItem(icon: Icons.stars_rounded, value: '$xp', label: 'XP', color: AppColors.purple),
                    StatItem(icon: Icons.emoji_events_rounded, value: '$wins', label: 'WINS', color: AppColors.teal),
                    StatItem(icon: Icons.whatshot_rounded, value: '$streak', label: 'STREAK', color: AppColors.red),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              OverviewRow(label: 'Matches Played', value: '$matches'),
              OverviewRow(label: 'Win Rate', value: '${winRate.toStringAsFixed(1)}%'),
              OverviewRow(label: 'Current Rank', value: RankSystem.getRankName(user.rank, user.subRank)),
              OverviewRow(label: 'Total XP', value: '$xp'),

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
                    children: unlocked.map((a) => AchievementChip(icon: a['icon'] as IconData, name: a['name'] as String)).toList(),
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
      (r) => r.data()['senderUid'] == uid
    ).firstOrNull;

    final outgoingRequests = ref.watch(outgoingRequestsProvider).value ?? [];
    final sentRequest = outgoingRequests.any(
      (r) => r.data()['receiverUid'] == uid
    );

    String label = '+ Add Friend';
    Color bgColor = AppColors.purple;
    VoidCallback? onPressed;

    if (isFriend) {
      label = 'Friends';
      bgColor = AppColors.teal.withValues(alpha: 0.2);
      onPressed = () => _showRemoveDialog(context, ref);
    } else if (sentRequest) {
      label = 'Request Sent';
      bgColor = AppColors.surface;
      onPressed = null;
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

class AchievementChip extends StatelessWidget {
  final IconData icon;
  final String name;

  const AchievementChip({super.key, required this.icon, required this.name});

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

class _RankBadge extends StatelessWidget {
  final int index;
  const _RankBadge({required this.index});

  @override
  Widget build(BuildContext context) {
    if (index == 0) return const Icon(Icons.workspace_premium, color: AppColors.gold, size: 28);
    if (index == 1) return const Icon(Icons.workspace_premium, color: AppColors.rankSilver, size: 24);
    if (index == 2) return const Icon(Icons.workspace_premium, color: AppColors.rankBronze, size: 24);

    return Text(
      '${index + 1}',
      style: AppTextStyles.headline.copyWith(fontSize: 18, color: AppColors.textMuted),
      textAlign: TextAlign.center,
    );
  }
}

class _TopPlayerCard extends StatelessWidget {
  final LeaderboardModel player;
  const _TopPlayerCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 2),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.purple.withValues(alpha: 0.2),
            AppColors.cardBg,
            Colors.black.withValues(alpha: 0.2),
          ],
        ),
      ),
      child: Stack(
        children: [
          ...List.generate(12, (index) {
            final double top = (index * 45) % 150.0 + 20;
            final double left = (index * 65) % 300.0 + 10;
            final isCircle = index % 2 == 0;
            return Positioned(
              top: top,
              left: left,
              child: Opacity(
                opacity: 0.2,
                child: Icon(
                  isCircle ? Icons.circle : Icons.star_rounded,
                  size: 4 + (index % 4).toDouble(),
                  color: index % 3 == 0 ? AppColors.gold : Colors.white70,
                ),
              ),
            );
          }),

          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
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
                        'TOP PLAYER',
                        style: AppTextStyles.label.copyWith(
                          color: AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.gold.withValues(alpha: 0.3),
                            AppColors.gold.withValues(alpha: 0.1),
                            Colors.transparent,
                          ],
                          stops: const [0.4, 0.7, 1.0],
                        ),
                      ),
                    ).animate(onPlay: (c) => c.repeat(reverse: true))
                     .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1), duration: 2.seconds),

                    BorderedAvatar(
                      avatarUrl: player.avatarUrl,
                      borderId: player.selectedBorder,
                      size: 85,
                      showGlow: false,
                    ),
                    const Positioned(
                      top: -5,
                      child: Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 24),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(player.username, style: AppTextStyles.headline.copyWith(fontSize: 24, color: Colors.white)),
                Text(
                  RankSystem.getRankName(player.rank, player.subRank),
                  style: AppTextStyles.label.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MvpStat(icon: Icons.stars_rounded, label: 'XP', value: '${player.xp}', color: AppColors.purple),
                    _MvpStat(icon: Icons.emoji_events_rounded, label: 'WINS', value: '${player.wins}', color: AppColors.teal),
                    _MvpStat(icon: Icons.whatshot_rounded, label: 'STREAK', value: '${player.currentWinStreak}', color: AppColors.red),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MvpStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MvpStat({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18, color: Colors.white)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.textMuted)),
      ],
    );
  }
}
