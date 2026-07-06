import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import 'smart_avatar.dart';

class UnlockPopup extends StatelessWidget {
  final String title;
  final String name;
  final String? image;
  final String? borderId;
  final VoidCallback onDismiss;

  const UnlockPopup({
    super.key,
    required this.title,
    required this.name,
    this.image,
    this.borderId,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.3),
              blurRadius: 40,
              spreadRadius: 10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NEW UNLOCK!',
              style: AppTextStyles.label.copyWith(color: AppColors.gold, letterSpacing: 4, fontWeight: FontWeight.w900),
            ).animate().shimmer(duration: 2.seconds),
            
            const SizedBox(height: 24),
            
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 2.seconds, curve: Curves.easeInOut),
                
                SmartAvatar(
                  avatarUrl: image,
                  borderId: borderId,
                  size: 100,
                  showGlow: true,
                ),
              ],
            ).animate().scale(delay: 200.ms, curve: Curves.elasticOut, duration: 1.seconds),
            
            const SizedBox(height: 24),
            
            Text(
              title.toUpperCase(),
              style: AppTextStyles.headline.copyWith(color: Colors.white70, fontSize: 14),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              name,
              style: AppTextStyles.display.copyWith(fontSize: 32, color: AppColors.gold),
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onDismiss,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('COLLECT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ),
            ),
          ],
        ),
      ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),
    );
  }
}
