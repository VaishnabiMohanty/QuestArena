import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';

class LeagueRewardPopup extends StatelessWidget {
  final String league;
  final int reward;
  final VoidCallback onCollect;

  const LeagueRewardPopup({
    super.key,
    required this.league,
    required this.reward,
    required this.onCollect,
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
          border: Border.all(color: AppColors.purple, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Confetti effect via icons
            Stack(
              alignment: Alignment.center,
              children: [
                ...List.generate(12, (index) => 
                  const Icon(Icons.star_rounded, color: AppColors.gold, size: 16)
                    .animate()
                    .move(
                      begin: Offset.zero, 
                      end: Offset((index - 6) * 20.0, (index % 3 == 0 ? -100 : 100).toDouble()),
                      duration: 1.seconds,
                    )
                    .fadeOut()
                ),
                const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 100)
                    .animate()
                    .scale(duration: 600.ms, curve: Curves.elasticOut),
              ],
            ),
            
            const SizedBox(height: 24),
            Text('SEASON REWARD', style: AppTextStyles.display.copyWith(fontSize: 24)),
            Text(league.toUpperCase(), style: AppTextStyles.headline.copyWith(color: AppColors.purple)),
            
            const SizedBox(height: 32),
            Text(
              '+$reward COINS', 
              style: AppTextStyles.display.copyWith(color: AppColors.gold, fontSize: 32)
            ).animate().slideY(begin: 1, end: 0).fadeIn(),

            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: onCollect,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('COLLECT', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).animate().scale().fadeIn();
  }
}
