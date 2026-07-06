import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/guild_providers.dart';
import '../../../data/models/guild_model.dart';
import '../../../data/models/user_model.dart';
import '../../widgets/smart_avatar.dart';
import '../../widgets/neon_swirl_background.dart';
import '../../widgets/guild_victory_card.dart';
import '../../../providers/navigation_providers.dart';

class GuildResultScreen extends ConsumerStatefulWidget {
  final String matchId;
  const GuildResultScreen({super.key, required this.matchId});

  @override
  ConsumerState<GuildResultScreen> createState() => _GuildResultScreenState();
}

class _GuildResultScreenState extends ConsumerState<GuildResultScreen> {
  late ConfettiController _confettiController;
  final ScreenshotController _screenshotController = ScreenshotController();

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final matchAsync = ref.watch(currentGuildBattleProvider);
    final user = ref.watch(currentUserProvider).value;

    return matchAsync.when(
      data: (match) {
        if (match == null || user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final bool isGuildA = match.guildAId == user.guildId;
        final int myGuildScore = isGuildA ? match.guildAScore : match.guildBScore;
        final int oppGuildScore = isGuildA ? match.guildBScore : match.guildAScore;
        final bool isWin = myGuildScore > oppGuildScore;
        final String myGuildName = isGuildA ? match.guildAName : match.guildBName;
        final String oppGuildName = isGuildA ? match.guildBName : match.guildAName;
        final String myGuildIcon = isGuildA ? match.guildAIcon : match.guildBIcon;

        if (isWin) _confettiController.play();

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          body: NeonSwirlBackground(
            colors: isWin ? const [AppColors.teal, AppColors.neonCyan] : const [AppColors.red, AppColors.bgBase],
            child: Stack(
              children: [
                ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  shouldLoop: false,
                  colors: const [AppColors.gold, AppColors.teal, AppColors.neonCyan],
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Text(
                          isWin ? 'VICTORY' : 'DEFEAT',
                          style: AppTextStyles.display.copyWith(
                            fontSize: 48,
                            color: isWin ? AppColors.gold : AppColors.red,
                          ),
                        ).animate().fadeIn().scale(),
                        
                        const SizedBox(height: 10),
                        Text(
                          'GUILD BATTLE',
                          style: AppTextStyles.label.copyWith(letterSpacing: 4, color: AppColors.textSecondary),
                        ),

                        const SizedBox(height: 40),

                        // GUILD VS GUILD SCORE
                        _buildGuildScoreBoard(myGuildName, myGuildIcon, myGuildScore, oppGuildName, oppGuildScore, isWin),

                        const SizedBox(height: 32),

                        // PLAYER CONTRIBUTION
                        _buildContributionCard(user, match.playerScores[user.uid] ?? 0, isWin),

                        const SizedBox(height: 40),
                        
                        _buildActions(match, user, isWin),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildGuildScoreBoard(String myName, String myIcon, int myScore, String oppName, int oppScore, bool isWin) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isWin ? AppColors.gold : AppColors.surface, width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _GuildScoreColumn(name: myName, score: myScore, iconId: myIcon, color: isWin ? AppColors.gold : AppColors.textSecondary),
              Text('VS', style: AppTextStyles.headline.copyWith(color: AppColors.textMuted)),
              _GuildScoreColumn(name: oppName, score: oppScore, iconId: '0', color: AppColors.red, isOpponent: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContributionCard(UserModel user, int score, bool isWin) {
    final int xp = (score / 10).floor() + (isWin ? 500 : 100);
    final int coins = isWin ? 100 : 20;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        children: [
          Text('YOUR CONTRIBUTION', style: AppTextStyles.label.copyWith(color: AppColors.gold)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatMini(label: 'SCORE', value: '$score', color: Colors.white),
              _StatMini(label: 'GUILD XP', value: '+$xp', color: AppColors.purple),
              _StatMini(label: 'COINS', value: '+$coins', color: AppColors.gold),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _captureAndShare(GuildBattleMatchModel match, UserModel user, bool isWin) async {
    try {
      final bool isGuildA = match.guildAId == user.guildId;
      final int myGuildScore = isGuildA ? match.guildAScore : match.guildBScore;
      final int oppGuildScore = isGuildA ? match.guildBScore : match.guildAScore;
      final String myGuildName = isGuildA ? match.guildAName : match.guildBName;
      final String oppGuildName = isGuildA ? match.guildBName : match.guildAName;
      final String myGuildIcon = isGuildA ? match.guildAIcon : match.guildBIcon;

      final int score = match.playerScores[user.uid] ?? 0;
      final int xp = (score / 10).floor() + (isWin ? 500 : 100);

      final image = await _screenshotController.captureFromWidget(
        Material(
          color: Colors.transparent,
          child: GuildVictoryCard(
            guildName: myGuildName,
            guildIconId: myGuildIcon,
            opponentGuildName: oppGuildName,
            guildScore: myGuildScore,
            opponentScore: oppGuildScore,
            playerName: user.username,
            playerAvatarUrl: user.avatarUrl,
            playerContribution: score,
            xpEarned: xp,
            isMvp: false, // Could be determined
          ),
        ),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
        context: context,
      );

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/guild_victory.png').create();
      await imagePath.writeAsBytes(image);

      const shareMessage = "My guild just dominated in QuestArena! 🛡️🔥\nJoin us and climb the ranks!\n\n🎮 Play now:\nhttps://quest-arena-self.vercel.app/";

      await Share.shareXFiles(
        [XFile(imagePath.path)],
        text: shareMessage,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share victory card: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  Widget _buildActions(GuildBattleMatchModel match, UserModel user, bool isWin) {
    return Column(
      children: [
        if (isWin) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _captureAndShare(match, user, isWin),
              icon: const Icon(Icons.share_rounded, color: Colors.white),
              label: const Text('SHARE VICTORY', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.neonPink,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ref.read(tabIndexProvider.notifier).state = 0;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _GuildScoreColumn extends StatelessWidget {
  final String name;
  final int score;
  final String iconId;
  final Color color;
  final bool isOpponent;

  const _GuildScoreColumn({
    required this.name,
    required this.score,
    required this.iconId,
    required this.color,
    this.isOpponent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(_getGuildIcon(iconId), color: color, size: 40),
        ),
        const SizedBox(height: 12),
        Text(name.toUpperCase(), style: AppTextStyles.label.copyWith(fontSize: 10, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('$score', style: AppTextStyles.display.copyWith(fontSize: 32, color: color)),
      ],
    );
  }

  IconData _getGuildIcon(String id) {
    switch (id) {
      case '1': return Icons.auto_awesome_rounded;
      case '2': return Icons.military_tech_rounded;
      case '3': return Icons.shield_rounded;
      case '4': return Icons.bolt_rounded;
      case '5': return Icons.workspace_premium_rounded;
      case '6': return Icons.pets_rounded;
      default: return Icons.groups_rounded;
    }
  }
}

class _StatMini extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatMini({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 20, color: color)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textSecondary)),
      ],
    );
  }
}
