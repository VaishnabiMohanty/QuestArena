// WHAT THIS FILE DOES:
// Displays the global rankings with an interactive expandable profile card system.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:questarena/core/constants/colors.dart';
import 'package:questarena/core/constants/text_styles.dart';
import 'package:questarena/data/models/leaderboard_model.dart';
import 'package:questarena/data/models/user_model.dart';
import 'package:questarena/providers/leaderboard_providers.dart';
import 'package:questarena/providers/user_providers.dart';
import 'package:questarena/providers/navigation_providers.dart';
import 'package:questarena/core/utils/rank_system.dart';
import 'package:questarena/ui/widgets/smart_avatar.dart';
import 'package:questarena/ui/widgets/expandable_player_card.dart';

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

                    return ExpandablePlayerCard(
                      uid: player.uid,
                      username: player.username,
                      avatarUrl: player.avatarUrl,
                      level: player.level,
                      xp: player.xp,
                      rank: player.rank,
                      subRank: player.subRank,
                      isMe: isMe,
                      isExpanded: isExpanded,
                      index: index,
                      onTap: () => _toggleProfile(player.uid),
                      badge: _RankBadge(index: index),
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
          ));
        }
        list.addAll(friends);
        
        // Sort by XP descending (Primary), then Level descending (Secondary)
        list.sort((a, b) {
          int cmp = b.xp.compareTo(a.xp);
          if (cmp == 0) cmp = b.level.compareTo(a.level);
          return cmp;
        });

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

                    return ExpandablePlayerCard(
                      uid: player.uid,
                      username: player.username,
                      avatarUrl: player.avatarUrl,
                      level: player.level,
                      xp: player.xp,
                      rank: player.rank,
                      subRank: player.subRank,
                      isMe: isMe,
                      isExpanded: isExpanded,
                      index: index,
                      onTap: () => _toggleProfile(player.uid),
                      badge: _RankBadge(index: index),
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
          // Ambient Sparkles / Confetti
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
                // Badge
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

                // Profile Image with circular radial glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Circular Radial Glow
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
                    
                    SmartAvatar(
                      avatarUrl: player.avatarUrl,
                      size: 85,
                      showBorder: true,
                      showGlow: false,
                    ),
                    Positioned(
                      top: -5,
                      child: const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 24),
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

                // Stats Row
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

          // Vignette effect
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                    ],
                    stops: const [0.7, 1.0],
                  ),
                ),
              ),
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
