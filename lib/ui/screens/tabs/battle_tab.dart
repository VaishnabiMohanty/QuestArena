import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/matchmaking_providers.dart';
import '../../../providers/shop_provider.dart';
import '../../../data/models/matchmaking_model.dart';
import '../matchmaking_screen.dart';
import '../private_room_screen.dart';
import '../../../features/practice/screens/practice_setup_screen.dart';
import '../guild/guild_home_screen.dart';
import '../guild/guild_dialogs.dart';
import '../../widgets/neon_swirl_background.dart';
import '../../widgets/category_picker_sheet.dart';

class BattleTab extends ConsumerStatefulWidget {
  const BattleTab({super.key});

  @override
  ConsumerState<BattleTab> createState() => _BattleTabState();
}

class _BattleTabState extends ConsumerState<BattleTab> {
  bool _isStartingMatch = false;

  Future<void> _startRankedMatch() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final category = await CategoryPickerSheet.show(context);
    if (category == null || !mounted) return;

    setState(() => _isStartingMatch = true);
    try {
      final ticket = MatchmakingModel(
        uid: user.uid,
        username: user.username,
        avatarUrl: user.avatarUrl,
        rank: user.rank,
        categoryId: category.id,
        categoryName: category.name,
        searchStartedAt: DateTime.now(),
      );
      await ref.read(matchmakingRepositoryProvider).startSearching(ticket);
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => MatchmakingScreen(categoryName: category.name)));
      }
    } finally {
      if (mounted) setState(() => _isStartingMatch = false);
    }
  }

  Future<void> _confirmToggle(bool newValue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text(
          newValue ? 'ACTIVATE SHIELD?' : 'DEACTIVATE SHIELD?',
          style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          newValue
              ? 'Use 1 rank protection match for the next match?'
              : 'Rank points will be deducted normally if you lose.',
          style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('CANCEL', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newValue ? AppColors.neonViolet : AppColors.red,
            ),
            child: Text(
              newValue ? 'ACTIVATE' : 'DEACTIVATE',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(shopControllerProvider.notifier).toggleRankProtection(newValue);
    }
  }

  void _handleGuildsTap() {
    final user = ref.read(currentUserProvider).value;
    if (user?.guildId == null) {
      showGuildOptionsDialog(context, ref);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildHomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final isProtectionActive = user?.rankProtectionActive ?? false;
    final hasShields = (user?.rankProtectionMatches ?? 0) > 0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: NeonSwirlBackground(
        colors: const [AppColors.neonViolet, AppColors.neonCyan],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('BATTLE HUB', style: AppTextStyles.display),
                        Text('Select your challenge', style: AppTextStyles.label),
                      ],
                    ),
                    _RankProtectionToggle(
                      isActive: isProtectionActive,
                      onChanged: hasShields
                          ? (val) => _confirmToggle(val)
                          : (_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No rank protection shields available. Purchase one in the Shop!'),
                                  backgroundColor: AppColors.neonPink,
                                ),
                              );
                            },
                      isEnabled: hasShields,
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                _BattleModeCard(
                  title: 'RANKED MATCH',
                  subtitle: _isStartingMatch ? 'Starting...' : 'Compete for XP and Rank',
                  icon: _isStartingMatch ? Icons.hourglass_bottom_rounded : Icons.flash_on_rounded,
                  color: AppColors.purple,
                  onTap: _isStartingMatch ? () {} : _startRankedMatch,
                ),

                const SizedBox(height: 16),

                _BattleModeCard(
                  title: 'PRIVATE DUEL',
                  subtitle: 'Play against a friend',
                  icon: Icons.vpn_key_rounded,
                  color: AppColors.gold,
                  onTap: _isStartingMatch ? () {} : () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivateRoomScreen()));
                  },
                ),

                const SizedBox(height: 16),

                _BattleModeCard(
                  title: 'PRACTICE',
                  subtitle: 'Sharpen your skills (No XP)',
                  icon: Icons.psychology_rounded,
                  color: AppColors.teal,
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const PracticeSetupScreen()));
                  },
                ),

                const SizedBox(height: 16),

                _BattleModeCard(
                  title: 'GUILDS',
                  subtitle: 'Team up and battle',
                  icon: Icons.groups_rounded,
                  color: AppColors.neonPink,
                  onTap: _handleGuildsTap,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BattleModeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _BattleModeCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.surface),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.headline.copyWith(fontSize: 18)),
                  Text(subtitle, style: AppTextStyles.label),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _RankProtectionToggle extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;
  final bool isEnabled;

  const _RankProtectionToggle({
    required this.isActive,
    required this.onChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Switch.adaptive(
            value: isActive,
            onChanged: onChanged,
            activeTrackColor: AppColors.neonViolet,
            inactiveTrackColor: AppColors.neonViolet.withValues(alpha: 0.1),
          ),
        ),
        Text(
          'SHIELD: ${isActive ? 'ON' : 'OFF'}',
          style: AppTextStyles.label.copyWith(
            color: isActive ? AppColors.neonViolet : AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}
