import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/coin_providers.dart';
import '../../../data/models/user_model.dart';
import '../store_screen.dart';
import '../../../core/utils/rank_system.dart';
import '../../widgets/rank_badge.dart';
import '../../widgets/xp_progress_bar.dart';
import '../../widgets/bordered_avatar.dart';
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
    final coinProgress = ref.watch(dailyCoinLimitProvider);

    return userAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
      error: (e, s) => Center(child: Text('Error: $e')),
      data: (user) {
        if (user == null) {
          return const Center(child: Text('User not found', style: TextStyle(color: AppColors.textSecondary)));
        }

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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOP BAR
                    SafeArea(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'DASHBOARD',
                            style: AppTextStyles.headline.copyWith(fontSize: 18, letterSpacing: 2),
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
                    ),

                    const SizedBox(height: 24),

                    // PROFILE CARD
                    _buildProfileCard(user),

                    const SizedBox(height: 32),

                    // Daily Coin Limit Progress
                    _buildDailyCoinProgress(user, coinProgress),

                    const SizedBox(height: 32),

                    // Battle Stats
                    Text('BATTLE STATS', style: AppTextStyles.label),
                    const SizedBox(height: 12),
                    _buildStatsRow(user),

                    const SizedBox(height: 32),
                    const _RecentHistorySection(),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                  BorderedAvatar(
                    avatarUrl: user.avatarUrl,
                    rank: user.rank,
                    size: 80,
                    showGlow: true,
                  ),
                  RankBadge(rank: user.rank, subRank: user.subRank, size: 30),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username.toUpperCase(),
                      style: AppTextStyles.headline.copyWith(
                        letterSpacing: 2,
                        color: AppColors.textPrimary,
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      RankSystem.getRankName(user.rank, user.subRank),
                      style: AppTextStyles.label.copyWith(
                        color: RankSystem.getRankColor(user.rank),
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    XpProgressBar(totalXp: user.xp),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: AppColors.surface, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSimpleStat('LEVEL', '${user.level}', AppColors.purple),
              _buildSimpleStat('COINS', '${user.coins}', AppColors.gold, icon: Icons.monetization_on_rounded),
              _buildSimpleStat('WINS', '${user.wins}', AppColors.teal),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildSimpleStat(String label, String value, Color color, {IconData? icon}) {
    return Column(
      children: [
        Row(
          children: [
            if (icon != null) Icon(icon, color: color, size: 14),
            if (icon != null) const SizedBox(width: 4),
            Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18, color: Colors.white)),
          ],
        ),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildDailyCoinProgress(UserModel user, double coinProgress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Today's Coins", style: AppTextStyles.label),
              Text(
                user.todayCoinsEarned >= 500 ? "Limit Reached" : "${user.todayCoinsEarned} / 500",
                style: AppTextStyles.label.copyWith(
                  color: user.todayCoinsEarned >= 500 ? AppColors.red : AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: coinProgress,
              backgroundColor: AppColors.surface,
              color: AppColors.gold,
              minHeight: 8,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildStatsRow(UserModel user) {
    return Row(
      children: [
        _StatCard(
          label: 'WIN STREAK',
          value: '${user.currentWinStreak}',
          color: AppColors.teal,
          icon: Icons.bolt_rounded,
        ),
        const SizedBox(width: 16),
        _StatCard(
          label: 'LOGIN STREAK',
          value: '${user.loginStreak}D',
          color: AppColors.gold,
          icon: Icons.whatshot_rounded,
        ),
      ],
    ).animate().fadeIn(delay: 400.ms);
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
            Text(value, style: AppTextStyles.headline.copyWith(fontSize: 20)),
            Text(label, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _RecentHistorySection extends ConsumerWidget {
  const _RecentHistorySection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(matchHistoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('RECENT MATCHES', style: AppTextStyles.label),
            TextButton(
              onPressed: () {},
              child: const Text('View All', style: TextStyle(fontSize: 10, color: AppColors.gold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Text('Error: $e'),
          data: (history) {
            if (history.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('No matches played yet.', style: TextStyle(color: AppColors.textMuted)),
              ));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: history.length > 5 ? 5 : history.length,
              itemBuilder: (context, index) {
                final match = history[index];
                final isWin = match.playerScore > match.opponentScore;
                final isDraw = match.playerScore == match.opponentScore;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surface),
                  ),
                  child: Row(
                    children: [
                      SmartAvatar(
                        avatarUrl: match.opponentAvatarUrl,
                        size: 44,
                        showBorder: true,
                        showGlow: false,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(match.opponentName, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                            Text(
                              isWin ? 'Victory' : (isDraw ? 'Draw' : 'Defeat'),
                              style: AppTextStyles.label.copyWith(
                                fontSize: 10,
                                color: isWin ? AppColors.teal : (isDraw ? AppColors.gold : AppColors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${match.playerScore} - ${match.opponentScore}',
                        style: AppTextStyles.headline.copyWith(fontSize: 16),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
