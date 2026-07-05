import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../../providers/daily_quest_provider.dart';
import 'daily_quest_box.dart';

class DailyQuestsSheet extends ConsumerWidget {
  const DailyQuestsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.primaryBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (context) => const DailyQuestsSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyQuestsAsync = ref.watch(dailyQuestsProvider);
    final isSunday = DateTime.now().weekday == DateTime.sunday;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Icon(
                    isSunday ? Icons.workspace_premium_rounded : Icons.bolt_rounded,
                    color: AppColors.gold,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isSunday ? 'WEEKLY REWARDS' : 'DAILY QUESTS',
                    style: AppTextStyles.headline.copyWith(fontSize: 20),
                  ),
                ],
              ),
            ),
            Expanded(
              child: dailyQuestsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.purple)),
                error: (e, s) => Center(child: Text('Error: $e')),
                data: (quests) {
                  if (quests.isEmpty) {
                    return const Center(
                      child: Text('No quests available today.', style: TextStyle(color: AppColors.textMuted)),
                    );
                  }
                  return ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: quests.length,
                    itemBuilder: (context, index) {
                      return DailyQuestBox(quest: quests[index], index: index);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
