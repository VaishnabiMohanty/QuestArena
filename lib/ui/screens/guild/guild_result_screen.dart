import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/guild_model.dart';
import '../../../providers/user_providers.dart';
import '../../widgets/smart_avatar.dart';
import '../../widgets/neon_swirl_background.dart';

class GuildResultScreen extends ConsumerStatefulWidget {
  final GuildBattleMatchModel match;
  final String myGuildId;

  const GuildResultScreen({super.key, required this.match, required this.myGuildId});

  @override
  ConsumerState<GuildResultScreen> createState() => _GuildResultScreenState();
}

class _GuildResultScreenState extends ConsumerState<GuildResultScreen> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    
    final bool isGuildA = widget.match.guildAId == widget.myGuildId;
    final int myScore = isGuildA ? widget.match.guildAScore : widget.match.guildBScore;
    final int oppScore = isGuildA ? widget.match.guildBScore : widget.match.guildAScore;
    
    if (myScore > oppScore) {
      _confettiController.play();
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isGuildA = widget.match.guildAId == widget.myGuildId;
    final String myName = isGuildA ? widget.match.guildAName : widget.match.guildBName;
    final String oppName = isGuildA ? widget.match.guildBName : widget.match.guildAName;
    final int myScore = isGuildA ? widget.match.guildAScore : widget.match.guildBScore;
    final int oppScore = isGuildA ? widget.match.guildBScore : widget.match.guildAScore;
    final bool isWin = myScore > oppScore;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: NeonSwirlBackground(
        colors: isWin ? [AppColors.teal, AppColors.neonCyan] : [AppColors.red, AppColors.bgBase],
        child: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Spacer(),
                    
                    // Main Title
                    Text(
                      isWin ? 'VICTORY' : 'DEFEAT',
                      style: AppTextStyles.display.copyWith(
                        fontSize: 48,
                        color: isWin ? AppColors.gold : AppColors.red,
                        letterSpacing: 8,
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 12),
                    Text(
                      'GUILD BATTLE RESULTS',
                      style: AppTextStyles.label.copyWith(color: AppColors.textSecondary, letterSpacing: 2),
                    ),

                    const Spacer(),

                    // Scoreboard
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: isWin ? AppColors.gold : AppColors.surface, width: 2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _GuildScoreColumn(name: myName, score: myScore, color: isWin ? AppColors.gold : AppColors.textPrimary),
                              Text('VS', style: AppTextStyles.headline.copyWith(color: AppColors.textMuted)),
                              _GuildScoreColumn(name: oppName, score: oppScore, color: AppColors.textMuted),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Divider(color: AppColors.surface),
                          ),
                          _RewardsSummary(isWin: isWin, myScore: myScore),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),

                    const Spacer(flex: 2),

                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isWin ? AppColors.gold : AppColors.surface,
                        minimumSize: const Size(double.infinity, 60),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        'CONTINUE',
                        style: TextStyle(
                          color: isWin ? Colors.black : Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [AppColors.gold, AppColors.neonCyan, Colors.white],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GuildScoreColumn extends StatelessWidget {
  final String name;
  final int score;
  final Color color;

  const _GuildScoreColumn({required this.name, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(name.toUpperCase(), style: AppTextStyles.label.copyWith(color: color, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('$score', style: AppTextStyles.display.copyWith(fontSize: 40, color: color)),
      ],
    );
  }
}

class _RewardsSummary extends StatelessWidget {
  final bool isWin;
  final int myScore;

  const _RewardsSummary({required this.isWin, required this.myScore});

  @override
  Widget build(BuildContext context) {
    final int xp = (myScore / 10).floor() + (isWin ? 500 : 100);
    final int coins = isWin ? 100 : 20;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _RewardItem(icon: Icons.auto_awesome_rounded, value: '+$xp XP', label: 'GUILD XP', color: AppColors.neonPink),
        _RewardItem(icon: Icons.monetization_on_rounded, value: '+$coins', label: 'COINS', color: AppColors.gold),
      ],
    );
  }
}

class _RewardItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _RewardItem({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 18)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textMuted)),
      ],
    );
  }
}
