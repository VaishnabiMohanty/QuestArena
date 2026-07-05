import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class StreakRewardPopup extends StatelessWidget {
  final String title;
  final String message;
  final int reward;
  final IconData icon;
  final Color color;
  final VoidCallback onClaim;

  const StreakRewardPopup({
    super.key,
    required this.title,
    required this.message,
    required this.reward,
    required this.icon,
    required this.color,
    required this.onClaim,
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
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(8, (index) => 
                  const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 24)
                    .animate()
                    .move(
                      begin: Offset.zero, 
                      end: Offset(
                        (index % 2 == 0 ? 1 : -1) * (index * 12).toDouble(), 
                        (index < 4 ? 1 : -1) * (index * 18).toDouble()
                      ),
                      duration: 800.ms,
                    )
                    .fadeOut()
                ),
                Icon(icon, color: color, size: 80)
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut),
              ],
            ),
            
            const SizedBox(height: 24),
            Text(title, style: AppTextStyles.display.copyWith(fontSize: 22, color: color)),
            const SizedBox(height: 8),
            Text(message, style: AppTextStyles.label.copyWith(color: AppColors.textPrimary)),
            
            const SizedBox(height: 32),
            Text(
              '+$reward COINS', 
              style: AppTextStyles.display.copyWith(color: AppColors.gold, fontSize: 32)
            ).animate().slideY(begin: 1, end: 0).fadeIn(),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('AWESOME!', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).animate().scale().fadeIn();
  }
}
