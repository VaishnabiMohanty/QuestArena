import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../data/models/daily_quest_model.dart';
import '../../providers/daily_quest_provider.dart';

class DailyQuestCard extends ConsumerStatefulWidget {
  final DailyQuest quest;

  const DailyQuestCard({super.key, required this.quest});

  @override
  ConsumerState<DailyQuestCard> createState() => _DailyQuestCardState();
}

class _DailyQuestCardState extends ConsumerState<DailyQuestCard> {
  String? _localSelected;
  bool _isSubmitting = false;
  bool _showResultLocally = false;
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handleOptionTap(String option) async {
    if (widget.quest.isCompleted || _isSubmitting) return;

    setState(() {
      _localSelected = option;
      _isSubmitting = true;
    });

    // Short delay for feedback
    await Future.delayed(const Duration(milliseconds: 300));
    
    final isCorrect = option == widget.quest.correctAnswer;
    if (isCorrect && mounted) {
      _confettiController.play();
    }

    await ref.read(dailyQuestActionProvider).submitAnswer(widget.quest.id, option);
    
    if (mounted) {
      setState(() {
        _isSubmitting = false;
        _showResultLocally = true;
      });
      
      // Auto-return to dashboard after rewards shown
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = _showResultLocally 
        ? (_localSelected == widget.quest.correctAnswer ? DailyQuestStatus.correct : DailyQuestStatus.wrong)
        : widget.quest.status;
    final isCorrect = status == DailyQuestStatus.correct;
    final isWrong = status == DailyQuestStatus.wrong;
    final isCompleted = widget.quest.isCompleted || _showResultLocally;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isCompleted
                  ? (isCorrect ? AppColors.teal : AppColors.red)
                  : AppColors.surface,
              width: 1.5,
            ),
            boxShadow: [
              if (isCompleted && isCorrect)
                BoxShadow(
                  color: AppColors.teal.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.quest.categoryName.toUpperCase(),
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.purple,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (isCompleted)
                    Icon(
                      isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: isCorrect ? AppColors.teal : AppColors.red,
                      size: 20,
                    ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                widget.quest.question,
                style: AppTextStyles.bodyMd.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 18),
              ...widget.quest.options.map((option) {
                final isSelected = _localSelected == option || widget.quest.selectedAnswer == option;
                final isCorrectOption = option == widget.quest.correctAnswer;
                
                Color borderColor = AppColors.surface;
                Color bgColor = AppColors.primaryBg;
                
                if (isCompleted) {
                  if (isCorrectOption) {
                    borderColor = AppColors.teal;
                    bgColor = AppColors.teal.withValues(alpha: 0.1);
                  } else if (isSelected && isWrong) {
                    borderColor = AppColors.red;
                    bgColor = AppColors.red.withValues(alpha: 0.1);
                  }
                } else if (isSelected) {
                  borderColor = AppColors.gold;
                  bgColor = AppColors.gold.withValues(alpha: 0.05);
                }

                return GestureDetector(
                  onTap: () => _handleOptionTap(option),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: borderColor, width: isSelected || (isCompleted && isCorrectOption) ? 2 : 1),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            option,
                            style: AppTextStyles.bodyMd.copyWith(
                              color: isSelected || (isCompleted && isCorrectOption)
                                  ? Colors.white
                                  : AppColors.textSecondary,
                              fontWeight: isSelected || (isCompleted && isCorrectOption) ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (isCompleted && isCorrectOption)
                          const Icon(Icons.check_rounded, color: AppColors.teal, size: 18),
                        if (isCompleted && isWrong && isSelected)
                           const Icon(Icons.close_rounded, color: AppColors.red, size: 18),
                      ],
                    ),
                  ),
                );
              }),
              if (isCompleted) ...[
                 const SizedBox(height: 4),
                 _RewardBadge(isCorrect: isCorrect),
              ],
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
        
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
          shouldLoop: false,
          colors: const [AppColors.gold, AppColors.teal, AppColors.purple],
          numberOfParticles: 15,
        ),
      ],
    );
  }
}

class _RewardBadge extends StatelessWidget {
  final bool isCorrect;
  const _RewardBadge({required this.isCorrect});

  @override
  Widget build(BuildContext context) {
    final isSunday = DateTime.now().weekday == DateTime.sunday;
    final rewardText = isCorrect
        ? (isSunday ? '+20 COINS & +100 XP' : '+10 COINS & +50 XP')
        : (isSunday ? '+15 XP' : '+10 XP');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isCorrect ? Icons.workspace_premium : Icons.stars, color: AppColors.gold, size: 14),
          const SizedBox(width: 8),
          Text(
            'COMPLETED: $rewardText',
            style: AppTextStyles.label.copyWith(
              color: AppColors.gold,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ).animate().scale(delay: 200.ms).fadeIn();
  }
}
