import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../data/models/daily_quest_model.dart';

class QuestSummaryDialog extends StatelessWidget {
  final String dayName;
  final bool isCompleted;
  final List<DailyQuest> quests;

  const QuestSummaryDialog({
    super.key,
    required this.dayName,
    required this.isCompleted,
    required this.quests,
  });

  static void show(BuildContext context, String dayName, bool isCompleted, List<DailyQuest> quests) {
    showDialog(
      context: context,
      builder: (context) => QuestSummaryDialog(
        dayName: dayName,
        isCompleted: isCompleted,
        quests: quests,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSunday = dayName.toUpperCase().contains('SUNDAY');
    
    int correctCount = 0;
    int wrongCount = 0;
    int coinsEarned = 0;
    int xpEarned = 0;

    if (isCompleted) {
      for (var quest in quests) {
        if (quest.status == DailyQuestStatus.correct) {
          correctCount++;
          coinsEarned += isSunday ? 20 : 10;
          xpEarned += isSunday ? 100 : 50;
        } else if (quest.status == DailyQuestStatus.wrong) {
          wrongCount++;
          xpEarned += isSunday ? 15 : 10;
        }
      }
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: isCompleted ? AppColors.teal.withValues(alpha: 0.5) : AppColors.red.withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (isCompleted ? AppColors.teal : AppColors.red).withValues(alpha: 0.1),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isCompleted ? Icons.verified_rounded : Icons.event_busy_rounded,
                  color: isCompleted ? AppColors.teal : AppColors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  dayName.toUpperCase(),
                  style: AppTextStyles.headline.copyWith(fontSize: 18, letterSpacing: 2),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isCompleted ? 'QUEST COMPLETED' : 'QUEST MISSED',
              style: AppTextStyles.label.copyWith(
                color: isCompleted ? AppColors.teal : AppColors.red,
                fontWeight: FontWeight.w900,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 32),
            
            if (!isCompleted)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'This quest was not attempted.',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
              )
            else ...[
               _buildStatRow('Questions Correct', '$correctCount/5', AppColors.teal),
               const Divider(color: AppColors.surface, height: 24),
               _buildStatRow('Questions Wrong', '$wrongCount/5', AppColors.red),
               const Divider(color: AppColors.surface, height: 24),
               _buildStatRow('Coins Earned', '+$coinsEarned', AppColors.gold),
               const Divider(color: AppColors.surface, height: 24),
               _buildStatRow('XP Earned', '+$xpEarned', AppColors.purple),

            ],

            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('CLOSE', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack).fadeIn(),
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
        Text(
          value,
          style: AppTextStyles.headline.copyWith(fontSize: 16, color: color),
        ),
      ],
    );
  }
}
