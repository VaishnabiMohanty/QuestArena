import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/daily_quest_model.dart';
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
import '../../widgets/quest_summary_dialog.dart';
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

                      const SizedBox(height: 32),
                      
                      const _WeeklyQuestsGrid(),
                    ],
                  ),
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

class _WeeklyQuestsGrid extends ConsumerWidget {
  const _WeeklyQuestsGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyStatus = ref.watch(weeklyStatusProvider).value ?? {};
    final today = DateTime.now().weekday;
    final nextDay = (today % 7) + 1;
    final countdownValue = ref.watch(dailyCountdownProvider).value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          today == DateTime.sunday ? 'WEEKLY REWARDS' : 'DAILY QUESTS',
          style: AppTextStyles.label.copyWith(letterSpacing: 2, color: today == DateTime.sunday ? AppColors.gold : Colors.white70),
        ),
        const SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.1,
          ),
          itemCount: 6,
          itemBuilder: (context, index) {
            final day = index + 1; // 1 to 6 (Mon to Sat)
            final quests = weeklyStatus[day] ?? [];
            final completed = quests.isNotEmpty && quests.every((q) => q.isCompleted);
            final isPast = day < today;
            
            return _QuestCard(
              day: day,
              isToday: day == today,
              isCompleted: completed,
              isPast: isPast,
              isLocked: day > today,
              countdown: day == nextDay ? countdownValue : null,
              quests: quests,
            );
          },
        ),
        const SizedBox(height: 8),
        Builder(
          builder: (context) {
            final quests = weeklyStatus[7] ?? [];
            final completed = quests.isNotEmpty && quests.every((q) => q.isCompleted);
            return _QuestCard(
              day: 7,
              isToday: today == 7,
              isCompleted: completed,
              isPast: 7 < today,
              isLocked: 7 > today,
              isLarge: true,
              countdown: 7 == nextDay ? countdownValue : null,
              quests: quests,
            );
          }
        ),
      ],
    );
  }
}

class _QuestCard extends StatelessWidget {
  final int day;
  final bool isToday;
  final bool isCompleted;
  final bool isPast;
  final bool isLocked;
  final bool isLarge;
  final String? countdown;
  final List<DailyQuest> quests;

  const _QuestCard({
    required this.day,
    required this.isToday,
    required this.isCompleted,
    required this.isPast,
    required this.isLocked,
    required this.quests,
    this.isLarge = false,
    this.countdown,
  });

  String get _dayName {
    switch (day) {
      case 1: return 'MON';
      case 2: return 'TUE';
      case 3: return 'WED';
      case 4: return 'THU';
      case 5: return 'FRI';
      case 6: return 'SAT';
      case 7: return 'SUNDAY SPECIAL';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final canOpen = isToday && !isCompleted;
    final isMissed = isPast && !isCompleted;
    
    return GestureDetector(
      onTap: () {
        if (canOpen) {
          DailyQuestsSheet.show(context);
        } else if (isCompleted || isMissed) {
          QuestSummaryDialog.show(context, _dayName, isCompleted, quests);
        }
      },
      child: Container(
        height: isLarge ? 72 : null,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isCompleted 
              ? AppColors.teal.withValues(alpha: 0.1) 
              : (isMissed ? AppColors.red.withValues(alpha: 0.05) : (canOpen ? AppColors.purple.withValues(alpha: 0.2) : AppColors.cardBg.withValues(alpha: 0.5))),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isCompleted 
                ? AppColors.teal.withValues(alpha: 0.5) 
                : (isMissed ? AppColors.red.withValues(alpha: 0.3) : (canOpen ? AppColors.purple : AppColors.surface)),
            width: canOpen ? 2 : 1,
          ),
          boxShadow: canOpen ? [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.2),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ] : null,
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
        child: isLarge 
          ? Row(
              children: [
                _buildIcon(isMissed),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_dayName, style: AppTextStyles.headline.copyWith(fontSize: 13, color: isToday ? AppColors.gold : Colors.white)),
                      Text(
                        isCompleted ? 'Completed' : (isMissed ? 'Missed' : (isToday ? 'Tap to claim rewards' : (countdown != null ? 'Unlocks in $countdown' : 'Locked'))),
                        style: AppTextStyles.label.copyWith(fontSize: 9, color: isCompleted ? AppColors.teal : (isMissed ? AppColors.red : (countdown != null ? AppColors.gold : AppColors.textMuted))),
                      ),
                    ],
                  ),
                ),
                if (canOpen) const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.gold, size: 14),
              ],
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(_dayName, style: AppTextStyles.label.copyWith(fontSize: 9, fontWeight: FontWeight.bold, color: isToday ? Colors.white : AppColors.textMuted)),
                const SizedBox(height: 6),
                _buildIcon(isMissed),
                const SizedBox(height: 4),
                if (isCompleted) 
                  const Text('DONE', style: TextStyle(color: AppColors.teal, fontSize: 7, fontWeight: FontWeight.bold))
                else if (isMissed)
                  const Text('MISSED', style: TextStyle(color: AppColors.red, fontSize: 7, fontWeight: FontWeight.bold))
                else if (countdown != null)
                  Text(countdown!, style: const TextStyle(color: AppColors.gold, fontSize: 7, fontWeight: FontWeight.bold)),
              ],
            ),
      ),
    ).animate(target: canOpen ? 1 : 0).shimmer(delay: 2.seconds, duration: 1.5.seconds);
  }

  Widget _buildIcon(bool isMissed) {
    if (isCompleted) return Icon(Icons.check_circle_rounded, color: AppColors.teal, size: isLarge ? 36 : 28);
    if (isMissed) return Icon(Icons.cancel_rounded, color: AppColors.red.withValues(alpha: 0.5), size: isLarge ? 36 : 28);
    if (isLocked) return Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: isLarge ? 32 : 24);
    return Icon(
      day == 7 ? Icons.workspace_premium_rounded : Icons.bolt_rounded,
      color: day == 7 ? AppColors.gold : AppColors.purple,
      size: isLarge ? 36 : 28,
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
