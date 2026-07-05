import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/daily_quest_model.dart';
import '../data/services/daily_quest_service.dart';
import 'auth_providers.dart';
import 'user_providers.dart';

final dailyQuestServiceProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return DailyQuestService(dio);
});

final dailyQuestsProvider = FutureProvider.autoDispose<List<DailyQuest>>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return [];
  
  return ref.watch(dailyQuestServiceProvider).getDailyQuests(authState.uid);
});

final dailyQuestActionProvider = Provider((ref) => DailyQuestAction(ref));

class DailyQuestAction {
  final Ref _ref;
  DailyQuestAction(this._ref);

  Future<void> submitAnswer(String questId, String answer) async {
    final authState = _ref.read(authStateProvider).value;
    if (authState == null) return;

    await _ref.read(dailyQuestServiceProvider).submitQuestAnswer(
      uid: authState.uid,
      questId: questId,
      answer: answer,
    );
    
    // Invalidate the future to reload data
    _ref.invalidate(dailyQuestsProvider);
  }
}
