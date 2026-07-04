import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

final weeklyStatusProvider = StreamProvider.autoDispose<Map<int, List<DailyQuest>>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value({});

  final now = DateTime.now();
  final monday = now.subtract(Duration(days: now.weekday - 1));
  final startOfWeek = DateTime(monday.year, monday.month, monday.day);
  
  return FirebaseFirestore.instance
      .collection('users')
      .doc(authState.uid)
      .collection('dailyQuests')
      .where('date', isGreaterThanOrEqualTo: DateFormat('yyyy-MM-dd').format(startOfWeek))
      .snapshots()
      .map((snapshot) {
    final Map<int, List<DailyQuest>> status = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final date = DateFormat('yyyy-MM-dd').parse(data['date']);
      final List questsJson = data['quests'] ?? [];
      final quests = questsJson.map((q) => DailyQuest.fromJson(q)).toList();
      status[date.weekday] = quests;
    }
    return status;
  });
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

final dailyCountdownProvider = StreamProvider.autoDispose<String>((ref) async* {
  while (true) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final diff = tomorrow.difference(now);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    yield '${h}h ${m}m';
    
    // Sync to next minute
    final secondsToNextMinute = 60 - now.second;
    await Future.delayed(Duration(seconds: secondsToNextMinute));
  }
});
