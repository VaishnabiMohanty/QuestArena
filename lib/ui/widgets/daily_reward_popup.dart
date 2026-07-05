import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class DailyRewardPopup extends StatelessWidget {
  final int day;
  final int reward;
  final VoidCallback onClaim;

  const DailyRewardPopup({
    super.key,
    required this.day,
    required this.reward,
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
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Coin Burst Animation
            Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(8, (index) => 
                  const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 24)
                    .animate()
                    .move(
                      begin: Offset.zero, 
                      end: Offset(
                        (index % 2 == 0 ? 1 : -1) * (index * 10).toDouble(), 
                        (index < 4 ? 1 : -1) * (index * 15).toDouble()
                      ),
                      duration: 800.ms,
                    )
                    .fadeOut()
                ),
                const Icon(Icons.card_giftcard_rounded, color: AppColors.gold, size: 80)
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut),
              ],
            ),
            
            const SizedBox(height: 24),
            Text('DAILY BONUS', style: AppTextStyles.display.copyWith(fontSize: 24)),
            Text('DAY $day', style: AppTextStyles.headline.copyWith(color: AppColors.gold)),
            
            const SizedBox(height: 32),
            Text(
              '+$reward COINS', 
              style: AppTextStyles.display.copyWith(color: AppColors.gold, fontSize: 32)
            ).animate().slideY(begin: 1, end: 0).fadeIn(),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('CLAIM REWARD', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).animate().scale().fadeIn();
  }
}
