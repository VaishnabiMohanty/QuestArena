import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../providers/user_providers.dart';
import '../../providers/streak_providers.dart';
import '../../providers/achievement_providers.dart';
import '../../providers/avatar_providers.dart';
import '../../providers/border_providers.dart';
import '../../core/constants/borders.dart';
import '../../core/errors/result.dart';
import 'tabs/dashboard_tab.dart';
import 'tabs/battle_tab.dart';
import 'tabs/leaderboard_tab.dart';
import 'tabs/profile_tab.dart';
import '../widgets/streak_reward_popup.dart';
import '../widgets/achievement_popup.dart';
import '../widgets/weekly_reward_popup.dart';
import '../../providers/navigation_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _checkedDailyReward = false;
  bool _checkedWeeklyReward = false;
  bool _syncedRetroactive = false;

  final List<Widget> _tabs = [
    const DashboardTab(),
    const BattleTab(),
    const LeaderboardTab(),
    const ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkDailyReward();
      _checkWeeklyReward();
      _syncRetroactiveData();
    });
  }

  void _checkWeeklyReward() async {
    if (_checkedWeeklyReward) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final weeklyRewards = await ref.read(weeklyRewardProvider.future);
    if (weeklyRewards != null && mounted) {
      _checkedWeeklyReward = true;

      final border = AppBorders.getBorderById(weeklyRewards['borderId']);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => WeeklyRewardPopup(
          league: weeklyRewards['league'],
          coins: weeklyRewards['coins'],
          borderName: border.name != 'None' ? border.name : null,
          onClaim: () async {
            await ref.read(borderServiceProvider).claimWeeklyReward(user);
            if (context.mounted) Navigator.pop(context);
          },
        ),
      );
    }
  }

  void _syncRetroactiveData() async {
    if (_syncedRetroactive) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    _syncedRetroactive = true;

    // 1. Sync Achievements (Retroactive)
    await ref.read(achievementServiceProvider).syncAll(user);

    // 2. Sync Avatars (Retroactive based on Rank)
    await ref.read(avatarServiceProvider).checkAndUnlockLeagues(user.uid, user.rank);
  }

  void _checkDailyReward() async {
    if (_checkedDailyReward) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    _checkedDailyReward = true;

    // Check Login Streak
    final streakService = ref.read(streakServiceProvider);
    final streakResult = await streakService.checkAndUpdateLoginStreak(user);

    if (streakResult is Success<int>) {
       if (mounted && streakResult.data > 0) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => StreakRewardPopup(
            title: '7-DAY STREAK',
            message: 'Consistency is key! 🔥',
            reward: streakResult.data,
            icon: Icons.whatshot_rounded,
            color: AppColors.gold,
            onClaim: () => Navigator.pop(context),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(tabIndexProvider);

    // Listen for achievements
    ref.listen(lastUnlockedAchievementProvider, (previous, next) {
      if (next != null) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AchievementPopup(
            achievement: next,
            onDismiss: () {
              Navigator.pop(context);
              ref.read(lastUnlockedAchievementProvider.notifier).state = null;
            },
          ),
        );
      }
    });

    // Listen for user data to trigger daily reward check once loaded
    ref.listen(currentUserProvider, (previous, next) {
      if (next.value != null) {
        if (!_checkedDailyReward) _checkDailyReward();
        if (!_syncedRetroactive) _syncRetroactiveData();
      }
    });

    return Scaffold(
      body: _tabs[selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.divider.withValues(alpha: 0.5), width: 0.5)),
        ),
        child: NavigationBar(
          height: 65,
          elevation: 0,
          backgroundColor: AppColors.bgBase,
          selectedIndex: selectedIndex,
          onDestinationSelected: (index) => ref.read(tabIndexProvider.notifier).state = index,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          indicatorColor: AppColors.neonCyan.withValues(alpha: 0.1),
          destinations: [
            _buildNavItem(0, Icons.dashboard_rounded, Icons.dashboard_outlined, 'HUB'),
            _buildNavItem(1, Icons.bolt_rounded, Icons.bolt_outlined, 'BATTLE'),
            _buildNavItem(2, Icons.leaderboard_rounded, Icons.leaderboard_outlined, 'RANKS'),
            _buildNavItem(3, Icons.person_rounded, Icons.person_outlined, 'PROFILE'),
          ],
        ),
      ),
    );
  }

  NavigationDestination _buildNavItem(int index, IconData activeIcon, IconData icon, String label) {
    return NavigationDestination(
      icon: Icon(icon, color: AppColors.textMuted),
      selectedIcon: Icon(activeIcon, color: AppColors.neonCyan),
      label: label,
    );
  }
}
