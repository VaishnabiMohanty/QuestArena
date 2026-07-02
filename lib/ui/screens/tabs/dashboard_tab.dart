// WHAT THIS FILE DOES:
// Shows the player's summary, stats, and a redesigned premium Recent History section.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../data/models/match_history_model.dart';
import '../../../core/utils/rank_system.dart';
import '../store_screen.dart';
import '../../widgets/rank_badge.dart';
import '../../widgets/rank_progress_bar.dart';
import '../../widgets/xp_progress_bar.dart';
import '../../widgets/smart_avatar.dart';
import '../../widgets/neon_swirl_background.dart';

class DashboardTab extends ConsumerStatefulWidget {
  const DashboardTab({super.key});

  @override
  ConsumerState<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends ConsumerState<DashboardTab> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
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
          body: NeonSwirlBackground(
            colors: const [AppColors.neonCyan, AppColors.purple],
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TOP BAR
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('DASHBOARD', style: AppTextStyles.headline.copyWith(fontSize: 18)),
                          IconButton(
                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen())),
                            icon: const Icon(Icons.shopping_bag_rounded, color: AppColors.gold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // PLAYER HEADER CARD
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: AppColors.surface),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    SmartAvatar(
                                      avatarUrl: user.avatarUrl,
                                      size: 70,
                                      showGlow: true,
                                    ),
                                    Transform.translate(
                                      offset: const Offset(8, 8),
                                      child: RankBadge(rank: user.rank, subRank: user.subRank, size: 32),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 24),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.username.toUpperCase(), style: AppTextStyles.headline.copyWith(letterSpacing: 2)),
                                      Text(
                                        RankSystem.getRankName(user.rank, user.subRank),
                                        style: AppTextStyles.label.copyWith(
                                          color: RankSystem.getRankColor(user.rank),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      XpProgressBar(totalXp: user.xp),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (user.rank != 'Legend' && user.rank != 'Unranked') ...[
                              const SizedBox(height: 16),
                              const Divider(color: AppColors.surface),
                              const SizedBox(height: 8),
                              RankProgressBar(rank: user.rank, subRank: user.subRank, points: user.rankPoints),
                            ],
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                      const SizedBox(height: 32),

                      Text('QUICK STATS', style: AppTextStyles.label),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          _StatCard(label: 'WINS', value: user.wins.toString(), color: AppColors.teal, icon: Icons.emoji_events_rounded),
                          const SizedBox(width: 12),
                          _StatCard(label: 'LOSSES', value: user.losses.toString(), color: AppColors.red, icon: Icons.sentiment_very_dissatisfied_rounded),
                          const SizedBox(width: 12),
                          _StatCard(label: 'DRAWS', value: user.draws.toString(), color: AppColors.gold, icon: Icons.handshake_rounded),
                        ],
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: 32),
                      const RecentHistorySection(),
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
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18)),
            Text(label, style: AppTextStyles.label.copyWith(fontSize: 8)),
          ],
        ),
      ),
    );
  }
}

class RecentHistorySection extends ConsumerStatefulWidget {
  const RecentHistorySection({super.key});

  @override
  ConsumerState<RecentHistorySection> createState() => _RecentHistorySectionState();
}

class _RecentHistorySectionState extends ConsumerState<RecentHistorySection> {
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(matchHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RECENT HISTORY', style: AppTextStyles.label),
        const SizedBox(height: 12),

        // Filter Chips Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Wins', 'Losses', 'Draws'].map((filter) {
              final isSelected = _selectedFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(filter, style: AppTextStyles.label.copyWith(
                    color: isSelected ? Colors.white : AppColors.textMuted,
                    fontSize: 12,
                  )),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedFilter = filter);
                  },
                  backgroundColor: AppColors.surface,
                  selectedColor: AppColors.purple,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  showCheckmark: false,
                  side: BorderSide(color: isSelected ? AppColors.purple : AppColors.surface),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 16),

        historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('History Error: $e'),
          data: (history) {
            final filteredHistory = history.where((match) {
              if (_selectedFilter == 'All') return true;
              if (_selectedFilter == 'Wins') return match.result == MatchResult.win;
              if (_selectedFilter == 'Losses') return match.result == MatchResult.loss;
              if (_selectedFilter == 'Draws') return match.result == MatchResult.draw;
              return true;
            }).toList();

            if (filteredHistory.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'No matches found',
                    style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredHistory.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final match = filteredHistory[index];
                return _MatchHistoryCard(match: match)
                    .animate(key: ValueKey('${match.id}_$_selectedFilter'))
                    .fadeIn(duration: 400.ms, delay: (index * 50).ms)
                    .slideY(begin: 0.2, end: 0);
              },
            );
          },
        ),
      ],
    );
  }
}

class _MatchHistoryCard extends StatelessWidget {
  final MatchModel match;
  const _MatchHistoryCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final result = match.result;

    Color accentColor;
    String statusText;

    switch (result) {
      case MatchResult.win:
        accentColor = AppColors.teal;
        statusText = 'VICTORY';
        break;
      case MatchResult.loss:
        accentColor = AppColors.red;
        statusText = 'DEFEAT';
        break;
      case MatchResult.draw:
        accentColor = AppColors.gold;
        statusText = 'DRAW';
        break;
    }

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface),
      ),
      child: Stack(
        children: [
          // Left accent border
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 6,
            child: Container(color: accentColor),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                // Top Row: Status Badge and XP
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusText,
                        style: AppTextStyles.label.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 10,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.flash_on_rounded, color: AppColors.gold, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '+${match.xpEarned} XP',
                          style: AppTextStyles.label.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Main Info Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'vs ${match.opponentName}',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormat('MMM d • HH:mm').format(match.timestamp),
                            style: AppTextStyles.label.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Score Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${match.playerScore} - ${match.opponentScore}',
                        style: AppTextStyles.display.copyWith(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
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
}
