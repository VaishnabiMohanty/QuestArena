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
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(color: AppColors.gold, width: 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard_rounded, color: AppColors.gold, size: 80)
                .animate(onPlay: (c) => c.repeat())
                .scale(duration: 1.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1), curve: Curves.easeInOut)
                .then()
                .scale(duration: 1.seconds, begin: const Offset(1.1, 1.1), end: const Offset(1, 1), curve: Curves.easeInOut),
            
            const SizedBox(height: 24),
            
            Text('DAILY REWARD', style: AppTextStyles.display.copyWith(fontSize: 24, color: AppColors.gold)),
            const SizedBox(height: 8),
            Text('Day $day', style: AppTextStyles.headline.copyWith(fontSize: 18)),
            
            const SizedBox(height: 32),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 28),
                  const SizedBox(width: 12),
                  Text('+$reward Coins', style: AppTextStyles.headline.copyWith(color: AppColors.gold)),
                ],
              ),
            ).animate().scale(delay: 500.ms).fadeIn(),

            const SizedBox(height: 40),
            
            ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 8,
              ),
              child: const Text('CLAIM REWARD', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      ),
    ).animate().scale(curve: Curves.elasticOut, duration: 800.ms).fadeIn();
  }
}

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
            const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 100)
                .animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut)
                .then()
                .shimmer(duration: 2.seconds),
            
            const SizedBox(height: 24),
            
            Text('SEASON REWARD', style: AppTextStyles.display.copyWith(fontSize: 24)),
            const SizedBox(height: 12),
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
