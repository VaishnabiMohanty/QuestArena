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
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final match = history[index];
                final isWin = match.playerScore > match.opponentScore;
                final isDraw = match.playerScore == match.opponentScore;
                
                final Color accentColor = isWin 
                    ? AppColors.teal 
                    : (isDraw ? AppColors.gold : AppColors.red);
                
                final String statusText = isWin ? 'VICTORY' : (isDraw ? 'DRAW' : 'DEFEAT');

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.1),
                      width: 0.5,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Left Status Bar
                        Container(
                          width: 5,
                          color: accentColor,
                        ),
                        
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              children: [
                                SmartAvatar(
                                  avatarUrl: match.opponentAvatarUrl,
                                  size: 46,
                                  showBorder: true,
                                  showGlow: false,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        match.opponentName,
                                        style: AppTextStyles.headline.copyWith(
                                          fontSize: 16,
                                          color: Colors.white,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        statusText,
                                        style: AppTextStyles.label.copyWith(
                                          color: accentColor,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 10,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '${match.playerScore} - ${match.opponentScore}',
                                        style: AppTextStyles.display.copyWith(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.flash_on_rounded, color: AppColors.gold, size: 12),
                                        const SizedBox(width: 2),
                                        Text(
                                          '+${match.xpEarned} XP',
                                          style: AppTextStyles.label.copyWith(
                                            color: AppColors.gold,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.1, end: 0);
              },
            );
          },
        ),
      ),
    );
  }
}
