// WHAT THIS FILE DOES:
// Represents an individual achievement and its progress for a player.

import 'package:cloud_firestore/cloud_firestore.dart';

enum AchievementType {
  matchesPlayed,
  matchesWon,
  questionsCorrect,
  perfectScores,
  loginStreak,
  rankReached,
  winStreak,
  levelReached,
  accuracy,
  arenaBreakerWins,
}

class AchievementReward {
  final int coins;
  final int xp;
  final String? avatarId; // Will store the image URL to match existing system
  final String? borderId;

  const AchievementReward({
    this.coins = 0,
    this.xp = 0,
    this.avatarId,
    this.borderId,
  });

  factory AchievementReward.fromJson(Map<String, dynamic> json) {
    return AchievementReward(
      coins: json['coins'] ?? 0,
      xp: json['xp'] ?? 0,
      avatarId: json['avatarId'],
      borderId: json['borderId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'coins': coins,
    'xp': xp,
    if (avatarId != null) 'avatarId': avatarId,
    if (borderId != null) 'borderId': borderId,
  };
}

class Achievement {
  final String id;
  final String title;
  final String description;
  final AchievementType type;
  final int target;
  final int progress;
  final AchievementReward reward;
  final bool isUnlocked;
  final bool isClaimed;
  final DateTime? unlockedAt;
  final DateTime? claimedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    this.progress = 0,
    required this.reward,
    this.isUnlocked = false,
    this.isClaimed = false,
    this.unlockedAt,
    this.claimedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json, Map<String, dynamic> definition) {
    DateTime? parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return Achievement(
      id: json['id'] ?? definition['id'],
      title: definition['title'],
      description: definition['description'],
      type: definition['type'],
      target: definition['target'],
      progress: json['progress'] ?? 0,
      reward: AchievementReward.fromJson(definition['reward'] ?? {}),
      isUnlocked: json['isUnlocked'] ?? false,
      isClaimed: json['isClaimed'] ?? false,
      unlockedAt: parseDateTime(json['unlockedAt']),
      claimedAt: parseDateTime(json['claimedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'progress': progress,
    'isUnlocked': isUnlocked,
    'isClaimed': isClaimed,
    if (unlockedAt != null) 'unlockedAt': Timestamp.fromDate(unlockedAt!),
    if (claimedAt != null) 'claimedAt': Timestamp.fromDate(claimedAt!),
  };

  Achievement copyWith({
    int? progress,
    bool? isUnlocked,
    bool? isClaimed,
    DateTime? unlockedAt,
    DateTime? claimedAt,
  }) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      type: type,
      target: target,
      progress: progress ?? this.progress,
      reward: reward,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isClaimed: isClaimed ?? this.isClaimed,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      claimedAt: claimedAt ?? this.claimedAt,
    );
  }
}

// Global Achievement Definitions
final List<Map<String, dynamic>> achievementDefinitions = [
  {
    'id': 'welcome_back',
    'title': 'Welcome Back',
    'description': 'Login for 2 consecutive days.',
    'type': AchievementType.loginStreak,
    'target': 2,
    'reward': {'coins': 100, 'xp': 50},
  },
  {
    'id': 'first_victory',
    'title': 'First Victory',
    'description': 'Win your first match.',
    'type': AchievementType.matchesWon,
    'target': 1,
    'reward': {'coins': 150},
  },
  {
    'id': 'beginner',
    'title': 'Beginner',
    'description': 'Play 5 matches.',
    'type': AchievementType.matchesPlayed,
    'target': 5,
    'reward': {'xp': 100},
  },
  {
    'id': 'rising_star',
    'title': 'Rising Star',
    'description': 'Reach Bronze League.',
    'type': AchievementType.rankReached,
    'target': 1,
    'reward': {'avatarId': 'https://api.dicebear.com/7.x/avataaars/png?seed=Felix'}, // Felix
  },
  {
    'id': 'consistent_player',
    'title': 'Consistent Player',
    'description': 'Login for 7 consecutive days.',
    'type': AchievementType.loginStreak,
    'target': 7,
    'reward': {'coins': 300},
  },
  {
    'id': 'challenger',
    'title': 'Challenger',
    'description': 'Win 10 matches.',
    'type': AchievementType.matchesWon,
    'target': 10,
    'reward': {'avatarId': 'https://api.dicebear.com/7.x/avataaars/png?seed=Jasper'}, // Jasper
  },
  {
    'id': 'scholar',
    'title': 'Scholar',
    'description': 'Answer 50 questions correctly.',
    'type': AchievementType.questionsCorrect,
    'target': 50,
    'reward': {'coins': 200, 'xp': 150},
  },
  {
    'id': 'unstoppable',
    'title': 'Unstoppable',
    'description': 'Achieve a 5-match win streak.',
    'type': AchievementType.winStreak,
    'target': 5,
    'reward': {'coins': 500, 'xp': 250},
  },
  {
    'id': 'godlike',
    'title': 'Godlike',
    'description': 'Achieve a 10-match win streak.',
    'type': AchievementType.winStreak,
    'target': 10,
    'reward': {'coins': 2000, 'xp': 1000, 'borderId': 'gold_border'},
  },
  {
    'id': 'veteran',
    'title': 'Veteran',
    'description': 'Play 50 matches.',
    'type': AchievementType.matchesPlayed,
    'target': 50,
    'reward': {'coins': 1000, 'xp': 500},
  },
  {
    'id': 'perfectionist',
    'title': 'Perfectionist',
    'description': 'Get a perfect score in 10 matches.',
    'type': AchievementType.perfectScores,
    'target': 10,
    'reward': {'avatarId': 'https://api.dicebear.com/7.x/avataaars/png?seed=Aiden'},
  },
  {
    'id': 'silver_warrior',
    'title': 'Silver Warrior',
    'description': 'Reach Silver League.',
    'type': AchievementType.rankReached,
    'target': 2,
    'reward': {'coins': 400},
  },
  {
    'id': 'gold_conqueror',
    'title': 'Gold Conqueror',
    'description': 'Reach Gold League.',
    'type': AchievementType.rankReached,
    'target': 3,
    'reward': {'avatarId': 'https://api.dicebear.com/7.x/avataaars/png?seed=Zoe'},
  },
  {
    'id': 'elite_master',
    'title': 'Elite Master',
    'description': 'Reach Master League.',
    'type': AchievementType.rankReached,
    'target': 6,
    'reward': {'coins': 2000, 'xp': 1000},
  },
  {
    'id': 'level_10',
    'title': 'Powering Up',
    'description': 'Reach Level 10.',
    'type': AchievementType.levelReached,
    'target': 10,
    'reward': {'coins': 500, 'xp': 200},
  },
  {
    'id': 'level_25',
    'title': 'Expert Explorer',
    'description': 'Reach Level 25.',
    'type': AchievementType.levelReached,
    'target': 25,
    'reward': {'avatarId': 'https://api.dicebear.com/7.x/avataaars/png?seed=Oliver'},
  },
  {
    'id': 'marksman',
    'title': 'Marksman',
    'description': 'Maintain an average accuracy of 80% or higher.',
    'type': AchievementType.accuracy,
    'target': 80,
    'reward': {'coins': 600},
  },
  {
    'id': 'arena_warrior',
    'title': 'Arena Warrior',
    'description': 'Win 5 Arena Breaker matches.',
    'type': AchievementType.arenaBreakerWins,
    'target': 5,
    'reward': {'coins': 1000, 'xp': 500},
  },
];
