import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  final String? avatarUrl;
  final int level;
  final int xp;
  final int coins;
  final String rank;
  final int? subRank;
  final int rankPoints;
  final int wins;
  final int losses;
  final int draws;
  final int eloRating;
  final int currentWinStreak;
  final int highestWinStreak;
  final DateTime? lastDailyBonusDate;
  final List<String> achievements;
  final int arenaBreakerWins;
  final int arenaBreakerLosses;
  final double averageAccuracy;
  final int oneOptionLifelines;
  final int twoOptionLifelines;
  final int rankProtectionMatches;
  final bool rankProtectionActive;
  final int ownedShieldPackage;

  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    this.avatarUrl,
    this.level = 1,
    this.xp = 0,
    this.coins = 0,
    this.rank = 'Unranked',
    this.subRank,
    this.rankPoints = 0,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.eloRating = 1200,
    this.currentWinStreak = 0,
    this.highestWinStreak = 0,
    this.lastDailyBonusDate,
    this.achievements = const [],
    this.arenaBreakerWins = 0,
    this.arenaBreakerLosses = 0,
    this.averageAccuracy = 0.0,
    this.oneOptionLifelines = 0,
    this.twoOptionLifelines = 0,
    this.rankProtectionMatches = 0,
    this.rankProtectionActive = false,
    this.ownedShieldPackage = 0,
  });

  // Calculated getters (Single source of truth)
  int get matchesPlayed => wins + losses + draws;

  double get winRate {
    if (matchesPlayed == 0) return 0.0;
    return (wins / matchesPlayed) * 100;
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rankVal = json['rank'] ?? 'Unranked';
    int? subRankVal = json['subRank'];

    if (subRankVal == null && rankVal != 'Unranked' && rankVal != 'Legend') {
      subRankVal = 3;
    }

    return UserModel(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      avatarUrl: json['avatarUrl'],
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      coins: json['coins'] ?? 0,
      rank: rankVal,
      subRank: subRankVal,
      rankPoints: json['rankPoints'] ?? 0,
      // Handle legacy naming
      wins: json['wins'] ?? json['totalWins'] ?? 0,
      losses: json['losses'] ?? json['totalLosses'] ?? 0,
      draws: json['draws'] ?? json['totalDraws'] ?? 0,
      eloRating: json['eloRating'] ?? 1200,
      currentWinStreak: json['currentWinStreak'] ?? json['currentStreak'] ?? 0,
      highestWinStreak: json['highestWinStreak'] ?? 0,
      lastDailyBonusDate: json['lastDailyBonusDate'] != null
          ? (json['lastDailyBonusDate'] is Timestamp
              ? (json['lastDailyBonusDate'] as Timestamp).toDate()
              : DateTime.tryParse(json['lastDailyBonusDate'].toString()))
          : null,
      achievements: List<String>.from(json['achievements'] ?? []),
      arenaBreakerWins: json['arenaBreakerWins'] ?? 0,
      arenaBreakerLosses: json['arenaBreakerLosses'] ?? 0,
      averageAccuracy: (json['averageAccuracy'] ?? 0.0).toDouble(),
      oneOptionLifelines: json['oneOptionLifelines'] ?? 0,
      twoOptionLifelines: json['twoOptionLifelines'] ?? 0,
      rankProtectionMatches: json['rankProtectionMatches'] ?? 0,
      rankProtectionActive: json['rankProtectionActive'] ?? false,
      ownedShieldPackage: json['ownedShieldPackage'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'username': username,
        'email': email,
        'avatarUrl': avatarUrl,
        'level': level,
        'xp': xp,
        'coins': coins,
        'rank': rank,
        'subRank': subRank,
        'rankPoints': rankPoints,
        'wins': wins,
        'losses': losses,
        'draws': draws,
        'matchesPlayed': matchesPlayed,
        'eloRating': eloRating,
        'currentWinStreak': currentWinStreak,
        'highestWinStreak': highestWinStreak,
        'lastDailyBonusDate': lastDailyBonusDate != null
            ? Timestamp.fromDate(lastDailyBonusDate!)
            : null,
        'achievements': achievements,
        'arenaBreakerWins': arenaBreakerWins,
        'arenaBreakerLosses': arenaBreakerLosses,
        'averageAccuracy': averageAccuracy,
        'oneOptionLifelines': oneOptionLifelines,
        'twoOptionLifelines': twoOptionLifelines,
        'rankProtectionMatches': rankProtectionMatches,
        'rankProtectionActive': rankProtectionActive,
        'ownedShieldPackage': ownedShieldPackage,
      };

  UserModel copyWith({
    String? username,
    String? avatarUrl,
    int? level,
    int? xp,
    int? coins,
    String? rank,
    int? subRank,
    int? rankPoints,
    int? wins,
    int? losses,
    int? draws,
    int? eloRating,
    int? currentWinStreak,
    int? highestWinStreak,
    DateTime? lastDailyBonusDate,
    List<String>? achievements,
    int? arenaBreakerWins,
    int? arenaBreakerLosses,
    double? averageAccuracy,
    bool clearSubRank = false,
    int? oneOptionLifelines,
    int? twoOptionLifelines,
    int? rankProtectionMatches,
    bool? rankProtectionActive,
    int? ownedShieldPackage,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      rank: rank ?? this.rank,
      subRank: clearSubRank ? null : (subRank ?? this.subRank),
      rankPoints: rankPoints ?? this.rankPoints,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      eloRating: eloRating ?? this.eloRating,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      highestWinStreak: highestWinStreak ?? this.highestWinStreak,
      lastDailyBonusDate: lastDailyBonusDate ?? this.lastDailyBonusDate,
      achievements: achievements ?? this.achievements,
      arenaBreakerWins: arenaBreakerWins ?? this.arenaBreakerWins,
      arenaBreakerLosses: arenaBreakerLosses ?? this.arenaBreakerLosses,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      oneOptionLifelines: oneOptionLifelines ?? this.oneOptionLifelines,
      twoOptionLifelines: twoOptionLifelines ?? this.twoOptionLifelines,
      rankProtectionMatches:
          rankProtectionMatches ?? this.rankProtectionMatches,
      rankProtectionActive: rankProtectionActive ?? this.rankProtectionActive,
      ownedShieldPackage: ownedShieldPackage ?? this.ownedShieldPackage,
    );
  }
}
