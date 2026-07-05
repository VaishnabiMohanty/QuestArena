// WHAT THIS FILE DOES:
// An animated overlay that celebrates an achievement unlock.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../data/models/achievement_model.dart';

class AchievementPopup extends StatelessWidget {
  final Achievement achievement;
  final VoidCallback onDismiss;

  const AchievementPopup({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.3),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Floating Trophy Icon
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 60),
            ).animate(onPlay: (c) => c.repeat())
             .shimmer(duration: 2.seconds)
             .scale(duration: 1.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1), curve: Curves.easeInOut)
             .then()
             .scale(duration: 1.seconds, begin: const Offset(1.1, 1.1), end: const Offset(1, 1), curve: Curves.easeInOut),

            const SizedBox(height: 24),

            Text(
              'ACHIEVEMENT UNLOCKED!',
              style: AppTextStyles.label.copyWith(color: AppColors.gold, letterSpacing: 2),
            ).animate().fadeIn().slideY(begin: 0.5, end: 0),

            const SizedBox(height: 12),

            Text(
              achievement.title.toUpperCase(),
              style: AppTextStyles.display.copyWith(fontSize: 28),
              textAlign: TextAlign.center,
            ).animate().scale(delay: 200.ms),

            const SizedBox(height: 8),

            Text(
              achievement.description,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Reward Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    '+${achievement.rewardCoins} COINS',
                    style: AppTextStyles.headline.copyWith(color: AppColors.gold, fontSize: 20),
                  ),
                ],
              ),
            ).animate().scale(delay: 600.ms, curve: Curves.elasticOut),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: onDismiss,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('AWESOME!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ).animate().scale(curve: Curves.elasticOut, duration: 800.ms).fadeIn(),
    );
  }
}
