// WHAT THIS FILE DOES:
// Utility functions for game logic.

import 'dart:math';
import 'dart:convert';
import '../../data/models/match_history_model.dart';

class GameUtils {
  // Decodes common HTML entities from the Open Trivia Database
  static String decodeHtmlEntities(String text) {
    return text
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"')
        .replaceAll('&hellip;', '...')
        .replaceAll('&deg;', '°');
  }

  // Generates a unique ID for a question based on its text
  static String generateQuestionId(String question) {
    final clean = question.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final bytes = utf8.encode(clean);
    return base64Encode(bytes).replaceAll('=', '').substring(0, min(28, base64Encode(bytes).length));
  }

  // Generates a random 6-character uppercase alphanumeric code
  static String generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Removed confusing chars like O, 0, I, 1
    return List.generate(6, (index) => chars[Random().nextInt(chars.length)]).join();
  }

  // Calculates daily play streak from match history
  static int calculateDailyStreak(List<MatchModel> history) {
    if (history.isEmpty) return 0;

    // Get unique days played, sorted descending
    final dates = history.map((m) {
      final d = m.timestamp.toLocal();
      return DateTime(d.year, d.month, d.day);
    }).toSet().toList()
      ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    // If the most recent play wasn't today or yesterday, streak is broken
    // We use !isAfter(yesterday.subtract(1ms)) to include yesterday exactly
    if (dates.first.isBefore(yesterday)) {
      return 0;
    }

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      // Check if dates[i] and dates[i+1] are consecutive days
      final diff = dates[i].difference(dates[i+1]).inDays;
      if (diff == 1) {
        streak++;
      } else if (diff > 1) {
        // Gap found, streak ends here
        break;
      }
      // if diff == 0, it's the same day, continue
    }

    return streak;
  }

  // Emergency Fallback questions in case Cloud Function fails
  static List<Map<String, dynamic>> getFallbackQuestions() {
    final questions = [
      {
        'question': 'Which planet is known as the Red Planet?',
        'correct_answer': 'Mars',
        'incorrect_answers': ['Venus', 'Jupiter', 'Saturn'],
      },
      {
        'question': 'What is the capital of France?',
        'correct_answer': 'Paris',
        'incorrect_answers': ['London', 'Berlin', 'Madrid'],
      },
      {
        'question': 'Which is the largest ocean on Earth?',
        'correct_answer': 'Pacific Ocean',
        'incorrect_answers': ['Atlantic Ocean', 'Indian Ocean', 'Arctic Ocean'],
      },
      {
        'question': 'Who painted the Mona Lisa?',
        'correct_answer': 'Leonardo da Vinci',
        'incorrect_answers': ['Pablo Picasso', 'Vincent van Gogh', 'Claude Monet'],
      },
      {
        'question': 'What is the chemical symbol for gold?',
        'correct_answer': 'Au',
        'incorrect_answers': ['Ag', 'Fe', 'Cu'],
      },
      {
        'question': 'Which country is home to the kangaroo?',
        'correct_answer': 'Australia',
        'incorrect_answers': ['South Africa', 'Brazil', 'India'],
      },
      {
        'question': 'What is the hardest natural substance on Earth?',
        'correct_answer': 'Diamond',
        'incorrect_answers': ['Gold', 'Iron', 'Quartz'],
      },
      {
        'question': 'Which element has the atomic number 1?',
        'correct_answer': 'Hydrogen',
        'incorrect_answers': ['Helium', 'Oxygen', 'Carbon'],
      },
      {
        'question': 'What is the smallest prime number?',
        'correct_answer': '2',
        'incorrect_answers': ['1', '3', '5'],
      },
      {
        'question': 'In which year did the Titanic sink?',
        'correct_answer': '1912',
        'incorrect_answers': ['1905', '1920', '1915'],
      },
      {
        'question': 'Which language is used for Android development?',
        'correct_answer': 'Kotlin',
        'incorrect_answers': ['Swift', 'Ruby', 'PHP'],
      },
      {
        'question': 'What is the capital of Japan?',
        'correct_answer': 'Tokyo',
        'incorrect_answers': ['Kyoto', 'Osaka', 'Seoul'],
      },
    ];
    return (questions..shuffle()).toList();
  }
}
//A private code generated for the game... private room