import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../data/models/daily_quest_model.dart';
import '../widgets/daily_quest_card.dart';
import '../widgets/neon_swirl_background.dart';

class DailyQuestScreen extends ConsumerWidget {
  final DailyQuest quest;

  const DailyQuestScreen({super.key, required this.quest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSunday = DateTime.now().weekday == DateTime.sunday;
    
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isSunday ? 'WEEKLY REWARD' : 'DAILY QUEST',
          style: AppTextStyles.headline.copyWith(
            fontSize: 18, 
            letterSpacing: 2,
            color: isSunday ? AppColors.gold : Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: NeonSwirlBackground(
        colors: isSunday 
            ? const [AppColors.gold, AppColors.purple] 
            : const [AppColors.purple, AppColors.neonViolet],
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DailyQuestCard(quest: quest),
                const SizedBox(height: 24),
                if (quest.isCompleted)
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'BACK TO DASHBOARD',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
