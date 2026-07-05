import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/user_providers.dart';
import '../widgets/smart_avatar.dart';
import '../widgets/neon_swirl_background.dart';

class MatchHistoryScreen extends ConsumerWidget {
  const MatchHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(matchHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text('BATTLE HISTORY', style: AppTextStyles.display.copyWith(fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: NeonSwirlBackground(
        colors: const [AppColors.neonCyan, AppColors.purple],
        child: historyAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
          error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.red))),
          data: (history) {
            if (history.isEmpty) {
              return const Center(
                child: Text('No matches recorded yet.', style: TextStyle(color: AppColors.textMuted)),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final match = history[index];
                final isWin = match.playerScore > match.opponentScore;
                final isDraw = match.playerScore == match.opponentScore;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isWin ? AppColors.teal.withValues(alpha: 0.3) : AppColors.surface,
                    ),
                  ),
                  child: Row(
                    children: [
                      SmartAvatar(
                        avatarUrl: match.opponentAvatarUrl,
                        size: 50,
                        showBorder: true,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              match.opponentName,
                              style: AppTextStyles.headline.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isWin ? 'VICTORY' : (isDraw ? 'DRAW' : 'DEFEAT'),
                              style: AppTextStyles.label.copyWith(
                                fontSize: 10,
                                color: isWin ? AppColors.teal : (isDraw ? AppColors.gold : AppColors.red),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${match.playerScore} - ${match.opponentScore}',
                            style: AppTextStyles.display.copyWith(fontSize: 20),
                          ),
                          Text(
                            '+${match.xpEarned} XP',
                            style: AppTextStyles.label.copyWith(color: AppColors.gold, fontSize: 10),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
              },
            );
          },
        ),
      ),
    );
  }
}
