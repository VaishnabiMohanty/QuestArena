import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/coin_providers.dart';
import '../../../data/models/user_model.dart';
import '../store_screen.dart';
import '../match_history_screen.dart';
import '../../../core/utils/rank_system.dart';
import '../../widgets/rank_badge.dart';
import '../../widgets/xp_progress_bar.dart';
import '../../widgets/smart_avatar.dart';
import '../../widgets/neon_swirl_background.dart';
import '../../widgets/daily_quests_sheet.dart';

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
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
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
    final coinProgress = ref.watch(dailyCoinLimitProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) return const Center(child: Text('User not found'));

        return Scaffold(
          backgroundColor: Colors.transparent,
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => DailyQuestsSheet.show(context),
            backgroundColor: AppColors.gold,
            icon: const Icon(Icons.bolt_rounded, color: Colors.black),
            label: const Text('QUESTS', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ).animate().slideX(begin: 1, end: 0, delay: 1000.ms, curve: Curves.easeOutBack),
          body: NeonSwirlBackground(
            colors: const [AppColors.neonCyan, AppColors.purple],
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Top Bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('HUB', style: AppTextStyles.headline.copyWith(fontSize: 18, letterSpacing: 4)),
                          Row(
                            children: [
                              IconButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MatchHistoryScreen())),
                                icon: const Icon(Icons.history_rounded, color: Colors.white70),
                              ),
                              IconButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen())),
                                icon: const Icon(Icons.shopping_bag_rounded, color: AppColors.gold),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Player Progress Card
                      _buildProgressCard(user),

                      const SizedBox(height: 32),

                      // Daily Coin Limit
                      _buildCoinLimitCard(user, coinProgress),

                      const SizedBox(height: 32),

                      // Quick Stats
                      Text('STATISTICS', style: AppTextStyles.label.copyWith(letterSpacing: 2)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _StatBox(label: 'WINS', value: '${user.wins}', color: AppColors.teal, icon: Icons.emoji_events_rounded),
                          const SizedBox(width: 12),
                          _StatBox(label: 'STREAK', value: '${user.currentWinStreak}', color: AppColors.red, icon: Icons.whatshot_rounded),
                          const SizedBox(width: 12),
                          _StatBox(label: 'COINS', value: '${user.coins}', color: AppColors.gold, icon: Icons.monetization_on_rounded),
                        ],
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildProgressCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.surface, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                alignment: Alignment.bottomRight,
                children: [
                  SmartAvatar(avatarUrl: user.avatarUrl, size: 70, showGlow: true),
                  RankBadge(rank: user.rank, subRank: user.subRank, size: 28),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.username.toUpperCase(), style: AppTextStyles.headline.copyWith(letterSpacing: 2, fontSize: 20)),
                    Text(
                      RankSystem.getRankName(user.rank, user.subRank),
                      style: AppTextStyles.label.copyWith(color: RankSystem.getRankColor(user.rank), fontWeight: FontWeight.w900, fontSize: 11),
                    ),
                    const SizedBox(height: 12),
                    XpProgressBar(totalXp: user.xp),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.surface),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniStat(label: 'LEVEL', value: '${user.level}'),
              _MiniStat(label: 'RANK XP', value: '${user.rankPoints}'),
              _MiniStat(label: 'MATCHES', value: '${user.matchesPlayed}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCoinLimitCard(UserModel user, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.surface)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('DAILY COIN LIMIT', style: AppTextStyles.label.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
              Text('${user.todayCoinsEarned} / 500', style: AppTextStyles.label.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), backgroundColor: AppColors.surface, color: AppColors.gold, minHeight: 6),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatBox({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: AppColors.cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.3))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18)),
            Text(label, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textSecondary)),
          ],
        ),
      ),
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
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 16)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textSecondary)),
      ],
    );
  }
}
