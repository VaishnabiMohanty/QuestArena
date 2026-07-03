import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../store_screen.dart';
import '../../../core/utils/rank_system.dart';
import '../../widgets/rank_badge.dart';
import '../../widgets/rank_progress_bar.dart';
import '../../widgets/xp_progress_bar.dart';
import '../../widgets/smart_avatar.dart';
import '../../widgets/neon_swirl_background.dart';
import '../../widgets/daily_quest_box.dart';
import '../../../providers/daily_quest_provider.dart';

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
        if (user == null) {
          return const Center(child: Text('User not found', style: TextStyle(color: AppColors.textSecondary)));
        }

        final totalMatches = user.wins + user.losses;
        final winRate = totalMatches == 0
            ? 0
            : ((user.wins / totalMatches) * 100).round();

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
                          Text(
                            'DASHBOARD',
                            style: AppTextStyles.headline.copyWith(fontSize: 18),
                          ),
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const StoreScreen()),
                            ),
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
                                    RankBadge(rank: user.rank, subRank: user.subRank, size: 28),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.username.toUpperCase(),
                                        style: AppTextStyles.headline.copyWith(
                                          letterSpacing: 2,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        RankSystem.getRankName(user.rank, user.subRank),
                                        style: AppTextStyles.label.copyWith(
                                          color: RankSystem.getRankColor(user.rank),
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.5,
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

                      const _DailyQuestsSection(),

                      const SizedBox(height: 32),

                      Text('QUICK STATS', style: AppTextStyles.label),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          _StatCard(
                            label: 'WINS',
                            value: user.wins.toString(),
                            color: AppColors.teal,
                            icon: Icons.emoji_events_rounded,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            label: 'LOSSES',
                            value: user.losses.toString(),
                            color: AppColors.red,
                            icon: Icons.sentiment_very_dissatisfied_rounded,
                          ),
                          const SizedBox(width: 8),
                          _StatCard(
                            label: 'WIN %',
                            value: '$winRate%',
                            color: AppColors.gold,
                            icon: Icons.auto_graph_rounded,
                          ),
                        ],
                      ).animate().fadeIn(delay: 400.ms),
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

class _DailyQuestsSection extends ConsumerWidget {
  const _DailyQuestsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyQuestsAsync = ref.watch(dailyQuestsProvider);
    final isSunday = DateTime.now().weekday == DateTime.sunday;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 32),
        Text(
          isSunday ? 'WEEKLY REWARDS' : 'DAILY QUESTS',
          style: AppTextStyles.label.copyWith(
            letterSpacing: 2,
            color: isSunday ? AppColors.gold : AppColors.textSecondary,
            fontWeight: isSunday ? FontWeight.w900 : FontWeight.normal,
          ),
        ),
        const SizedBox(height: 12),
        dailyQuestsAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: CircularProgressIndicator(color: AppColors.purple),
            ),
          ),
          error: (e, s) => Center(
            child: Text('Error loading quests', style: AppTextStyles.label.copyWith(color: AppColors.red)),
          ),
          data: (quests) {
            if (quests.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No quests available today.', style: TextStyle(color: AppColors.textMuted)),
                ),
              );
            }
            return Column(
              children: quests.asMap().entries.map((entry) {
                return DailyQuestBox(quest: entry.value, index: entry.key);
              }).toList(),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 300.ms);
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
