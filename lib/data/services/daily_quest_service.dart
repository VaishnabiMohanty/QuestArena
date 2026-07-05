import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../../core/models/quiz_category.dart';
import '../../core/utils/game_utils.dart';
import '../../core/utils/level_system.dart';
import '../models/daily_quest_model.dart';

class DailyQuestService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Dio _dio;

  DailyQuestService(this._dio);

  String get _todayStr => DateFormat('yyyy-MM-dd').format(DateTime.now());

  Future<List<DailyQuest>> getDailyQuests(String uid) async {
    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('dailyQuests')
        .doc(_todayStr)
        .get();

    if (doc.exists) {
      final List questsJson = doc.data()?['quests'] ?? [];
      return questsJson.map((q) => DailyQuest.fromJson(q)).toList();
    } else {
      final quests = await _generateQuests(uid);
      
      final batch = _db.batch();
      
      // Save today's quests
      batch.set(
        _db.collection('users').doc(uid).collection('dailyQuests').doc(_todayStr),
        {
          'date': _todayStr,
          'quests': quests.map((q) => q.toJson()).toList(),
          'lastReset': FieldValue.serverTimestamp(),
        },
      );

      // Record in history to prevent future repeats
      for (final quest in quests) {
        batch.set(
          _db.collection('users').doc(uid).collection('dailyQuestHistory').doc(quest.questionId),
          {'assignedAt': FieldValue.serverTimestamp()},
        );
      }

      await batch.commit();
      return quests;
    }
  }

  Future<List<DailyQuest>> _generateQuests(String uid) async {
    final allCategories = List<QuizCategory>.from(QuizCategory.all)
      ..remove(QuizCategory.mixed);
    
    List<DailyQuest> dailyQuests = [];
    Set<String> sessionUsedQuestionIds = {};
    Set<int> sessionUsedCategoryIds = {};

    // Shuffle categories to get a random order
    allCategories.shuffle();

    for (final cat in allCategories) {
      if (dailyQuests.length >= 5) break;

      try {
        // Fetch a pool of questions for this category
        final response = await _dio.get(
          ApiConstants.triviaUrlForCategory(cat.id, amount: 20),
        );
        
        if (response.data['results'] != null) {
          final results = response.data['results'] as List;
          
          for (final qData in results) {
            final questionText = GameUtils.decodeHtmlEntities(qData['question']);
            final qId = GameUtils.generateQuestionId(questionText);

            // Skip if already chosen in this session
            if (sessionUsedQuestionIds.contains(qId)) continue;

            // Check global history in Firestore
            final historyDoc = await _db
                .collection('users')
                .doc(uid)
                .collection('dailyQuestHistory')
                .doc(qId)
                .get();

            if (!historyDoc.exists) {
              // Found a unique question from a unique category
              final quest = DailyQuest(
                id: 'q${dailyQuests.length}',
                questionId: qId,
                question: questionText,
                correctAnswer: GameUtils.decodeHtmlEntities(qData['correct_answer']),
                options: ([
                  qData['correct_answer'],
                  ...List<String>.from(qData['incorrect_answers'])
                ].map((a) => GameUtils.decodeHtmlEntities(a)).toList()..shuffle()),
                categoryName: cat.name,
                categoryId: cat.id ?? 0,
              );
              
              dailyQuests.add(quest);
              sessionUsedQuestionIds.add(qId);
              sessionUsedCategoryIds.add(cat.id ?? 0);
              break; // Successfully got 1 unique question for this category, move to next
            }
          }
        }
      } catch (e) {
        // Skip problematic category
        continue;
      }
    }

    // Fallback logic if we couldn't get 5 unique categories from the API
    if (dailyQuests.length < 5) {
      final fallbacks = GameUtils.getFallbackQuestions();
      int fallbackCatId = 5000; // Large ID to avoid collisions

      for (final f in fallbacks) {
        if (dailyQuests.length >= 5) break;
        
        final qText = f['question'];
        final qId = GameUtils.generateQuestionId(qText);
        
        if (!sessionUsedQuestionIds.contains(qId)) {
          dailyQuests.add(DailyQuest(
            id: 'q${dailyQuests.length}',
            questionId: qId,
            question: qText,
            correctAnswer: f['correct_answer'],
            options: ([f['correct_answer'], ...List<String>.from(f['incorrect_answers'])]..shuffle()),
            categoryName: 'General ${dailyQuests.length + 1}',
            categoryId: fallbackCatId++,
          ));
          sessionUsedQuestionIds.add(qId);
          sessionUsedCategoryIds.add(fallbackCatId - 1);
        }
      }
    }

    // Final Validation
    if (!_validateQuestSet(dailyQuests)) {
      // Regeneration loop if validation fails
      return _generateQuests(uid);
    }

    return dailyQuests;
  }

  bool _validateQuestSet(List<DailyQuest> quests) {
    if (quests.length != 5) return false;
    
    final qIds = quests.map((q) => q.questionId).toSet();
    if (qIds.length != 5) return false;

    final catIds = quests.map((q) => q.categoryId).toSet();
    if (catIds.length != 5) return false;

    return true;
  }

  Future<void> submitQuestAnswer({
    required String uid,
    required String questId,
    required String answer,
  }) async {
    final userRef = _db.collection('users').doc(uid);
    final dailyQuestRef = userRef.collection('dailyQuests').doc(_todayStr);

    await _db.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final dailySnapshot = await transaction.get(dailyQuestRef);

      if (!userSnapshot.exists || !dailySnapshot.exists) return;

      final userData = userSnapshot.data()!;
      final List questsJson = dailySnapshot.data()?['quests'] ?? [];
      final quests = questsJson.map((q) => DailyQuest.fromJson(q)).toList();

      final questIndex = quests.indexWhere((q) => q.id == questId);
      if (questIndex == -1 || quests[questIndex].isCompleted) return;

      final quest = quests[questIndex];
      final isCorrect = quest.correctAnswer == answer;
      final status = isCorrect ? DailyQuestStatus.correct : DailyQuestStatus.wrong;

      final isSunday = DateTime.now().weekday == DateTime.sunday;
      final coinsReward = isCorrect ? (isSunday ? 20 : 10) : 0;
      final xpReward = isCorrect ? (isSunday ? 100 : 50) : (isSunday ? 15 : 10);

      quests[questIndex] = quest.copyWith(
        status: status,
        selectedAnswer: answer,
      );

      transaction.update(dailyQuestRef, {
        'quests': quests.map((q) => q.toJson()).toList(),
      });

      final currentXp = userData['xp'] ?? 0;
      final newXp = currentXp + xpReward;
      final newLevel = LevelSystem.getCurrentLevel(newXp);

      transaction.update(userRef, {
        'coins': (userData['coins'] ?? 0) + coinsReward,
        'xp': newXp,
        'level': newLevel,
      });
    });
  }
}
