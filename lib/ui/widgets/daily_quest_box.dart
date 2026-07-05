import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../data/models/daily_quest_model.dart';
import '../screens/daily_quest_screen.dart';

class DailyQuestBox extends StatelessWidget {
  final DailyQuest quest;
  final int index;

  const DailyQuestBox({super.key, required this.quest, required this.index});

  @override
  Widget build(BuildContext context) {
    final isCompleted = quest.isCompleted;
    final isCorrect = quest.status == DailyQuestStatus.correct;
    final isSunday = DateTime.now().weekday == DateTime.sunday;
    final primaryThemeColor = isSunday ? AppColors.gold : AppColors.purple;

    return GestureDetector(
      onTap: isCompleted
          ? null
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailyQuestScreen(quest: quest),
                ),
              ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isCompleted
              ? AppColors.cardBg.withValues(alpha: 0.6)
              : AppColors.cardBg.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isCompleted
                ? (isCorrect ? AppColors.teal.withValues(alpha: 0.5) : AppColors.red.withValues(alpha: 0.5))
                : (isSunday ? AppColors.gold.withValues(alpha: 0.3) : AppColors.surface),
            width: 1.5,
          ),
          boxShadow: [
            if (isCompleted)
              BoxShadow(
                color: (isCorrect ? AppColors.teal : AppColors.red)
                    .withValues(alpha: 0.1),
                blurRadius: 10,
                spreadRadius: 1,
              )
            else if (isSunday)
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.05),
                blurRadius: 15,
                spreadRadius: 2,
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: isCompleted
                    ? (isCorrect ? AppColors.teal : AppColors.red).withValues(alpha: 0.1)
                    : primaryThemeColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? (isCorrect ? AppColors.teal : AppColors.red)
                      : primaryThemeColor.withValues(alpha: 0.5),
                  width: 2,
                ),
                boxShadow: [
                  if (!isCompleted)
                    BoxShadow(
                      color: primaryThemeColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                ],
              ),
              child: Icon(
                isCompleted
                    ? (isCorrect ? Icons.check_rounded : Icons.close_rounded)
                    : (isSunday ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded),
                color: isCompleted
                    ? (isCorrect ? AppColors.teal : AppColors.red)
                    : primaryThemeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSunday ? 'WEEKLY QUEST ${index + 1}' : 'QUEST ${index + 1}',
                    style: AppTextStyles.label.copyWith(
                      color: isSunday ? AppColors.gold : AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCompleted 
                      ? (isCorrect ? 'Victory • Rewards Claimed' : (isSunday ? 'Defeat • +15 XP' : 'Defeat • +10 XP'))
                      : 'LOCKED • Tap to unlock',
                    style: AppTextStyles.label.copyWith(
                      color: isCompleted
                          ? (isCorrect ? AppColors.teal : AppColors.red)
                          : AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: isCompleted ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (!isCompleted)
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isSunday ? AppColors.gold.withValues(alpha: 0.5) : AppColors.surface,
                size: 14,
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideX(begin: 0.1, end: 0);
  }
}
