// WHAT THIS FILE DOES:
// Represents an individual achievement and its progress for a player.

import 'package:cloud_firestore/cloud_firestore.dart';

enum AchievementType {
  matchesPlayed,
  matchesWon,
  questionsCorrect,
  perfectScores,
  loginStreak,
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final int target;
  final int progress;
  final int rewardCoins;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    this.progress = 0,
    required this.rewardCoins,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json, Map<String, dynamic> definition) {
    return Achievement(
      id: json['id'] ?? definition['id'],
      title: definition['title'],
      description: definition['description'],
      type: definition['type'],
      target: definition['target'],
      progress: json['progress'] ?? 0,
      rewardCoins: definition['rewardCoins'],
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null 
          ? (json['unlockedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'progress': progress,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
  };

  Achievement copyWith({
    int? progress,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      type: type,
      target: target,
      progress: progress ?? this.progress,
      rewardCoins: rewardCoins,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

// Global Achievement Definitions
final List<Map<String, dynamic>> achievementDefinitions = [
  // Match Master
  {
    'id': 'match_master',
    'title': 'Match Master',
    'description': 'Play 50 Matches',
    'type': AchievementType.matchesPlayed,
    'target': 50,
    'rewardCoins': 100,
  },
  {
    'id': 'century_player',
    'title': 'Century Player',
    'description': 'Play 100 Matches',
    'type': AchievementType.matchesPlayed,
    'target': 100,
    'rewardCoins': 250,
  },
  {
    'id': 'warrior',
    'title': 'Warrior',
    'description': 'Win 25 Matches',
    'type': AchievementType.matchesWon,
    'target': 25,
    'rewardCoins': 150,
  },
  {
    'id': 'champion',
    'title': 'Champion',
    'description': 'Win 100 Matches',
    'type': AchievementType.matchesWon,
    'target': 100,
    'rewardCoins': 500,
  },
  {
    'id': 'unstoppable',
    'title': 'Unstoppable',
    'description': 'Win 250 Matches',
    'type': AchievementType.matchesWon,
    'target': 250,
    'rewardCoins': 1000,
  },
  // Accuracy
  {
    'id': 'sharp_shooter',
    'title': 'Sharp Shooter',
    'description': 'Answer 20 Questions Correctly',
    'type': AchievementType.questionsCorrect,
    'target': 20,
    'rewardCoins': 75,
  },
  {
    'id': 'genius',
    'title': 'Genius',
    'description': 'Answer 100 Questions Correctly',
    'type': AchievementType.questionsCorrect,
    'target': 100,
    'rewardCoins': 250,
  },
  {
    'id': 'quiz_master',
    'title': 'Quiz Master',
    'description': 'Answer 500 Questions Correctly',
    'type': AchievementType.questionsCorrect,
    'target': 500,
    'rewardCoins': 750,
  },
  {
    'id': 'professor',
    'title': 'Professor',
    'description': 'Answer 1000 Questions Correctly',
    'type': AchievementType.questionsCorrect,
    'target': 1000,
    'rewardCoins': 1500,
  },
  // Streak
  {
    'id': 'consistent',
    'title': 'Consistent',
    'description': 'Maintain a 3-day login streak',
    'type': AchievementType.loginStreak,
    'target': 3,
    'rewardCoins': 50,
  },
  {
    'id': 'dedicated',
    'title': 'Dedicated',
    'description': 'Maintain a 7-day login streak',
    'type': AchievementType.loginStreak,
    'target': 7,
    'rewardCoins': 200,
  },
  {
    'id': 'hardcore',
    'title': 'Hardcore Player',
    'description': 'Maintain a 30-day login streak',
    'type': AchievementType.loginStreak,
    'target': 30,
    'rewardCoins': 1000,
  },
];
