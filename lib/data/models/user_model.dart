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
  final List<String> achievements;
  final List<String> unlockedAvatars;
  final List<String> unlockedBorders;
  final String? selectedBorder;
  final int weeklyMatchesPlayed;
  final DateTime? lastWeeklyRewardDate;
  final String? weeklyLeague;
  final Map<String, int> powerUps;

  // Coin & Streak System Fields
  final int todayCoinsEarned;
  final DateTime lastCoinResetDate;
  final DateTime lastDailyLoginRewardDate;
  final int loginStreak;
  final DateTime lastLoginDate;
  final String? lastRewardedMatchId;
  final String? lastLeagueRewardClaimed; // e.g., 'Gold_Season_1'

  // Additional stats
  final int arenaBreakerWins;
  final int arenaBreakerLosses;
  final double averageAccuracy;
  final int oneOptionLifelines;
  final int twoOptionLifelines;
  final int rankProtectionMatches;
  final bool rankProtectionActive;
  final int ownedShieldPackage;
  final String? guildId;
  final int weeklyXp;
  final int weeklyWins;
  final int guildBattlesPlayed;
  final int guildBattlesWon;
  final int totalGuildXpContributed;
  final DateTime? lastDailyBonusDate;
  final int totalQuestionsCorrect;
  final int totalPerfectScores;

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
    this.achievements = const [],
    this.unlockedAvatars = const [],
    this.unlockedBorders = const [],
    this.selectedBorder,
    this.weeklyMatchesPlayed = 0,
    this.lastWeeklyRewardDate,
    this.weeklyLeague,
    this.powerUps = const {'fiftyFifty': 5, 'timeFreeze': 5},
    this.todayCoinsEarned = 0,
    DateTime? lastCoinResetDate,
    DateTime? lastDailyLoginRewardDate,
    this.loginStreak = 0,
    DateTime? lastLoginDate,
    this.lastRewardedMatchId,
    this.lastLeagueRewardClaimed,
    this.arenaBreakerWins = 0,
    this.arenaBreakerLosses = 0,
    this.averageAccuracy = 0.0,
    this.oneOptionLifelines = 0,
    this.twoOptionLifelines = 0,
    this.rankProtectionMatches = 0,
    this.rankProtectionActive = false,
    this.ownedShieldPackage = 0,
    this.guildId,
    this.weeklyXp = 0,
    this.weeklyWins = 0,
    this.guildBattlesPlayed = 0,
    this.guildBattlesWon = 0,
    this.totalGuildXpContributed = 0,
    this.lastDailyBonusDate,
    this.totalQuestionsCorrect = 0,
    this.totalPerfectScores = 0,
  })  : lastCoinResetDate = lastCoinResetDate ?? DateTime(2000, 1, 1),
        lastDailyLoginRewardDate = lastDailyLoginRewardDate ?? DateTime(2000, 1, 1),
        lastLoginDate = lastLoginDate ?? DateTime(2000, 1, 1);

  // Calculated getters
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

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
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
      wins: json['wins'] ?? json['totalWins'] ?? 0,
      losses: json['losses'] ?? json['totalLosses'] ?? 0,
      draws: json['draws'] ?? json['totalDraws'] ?? 0,
      eloRating: json['eloRating'] ?? 1200,
      currentWinStreak: json['currentWinStreak'] ?? json['currentStreak'] ?? 0,
      highestWinStreak: json['highestWinStreak'] ?? 0,
      achievements: List<String>.from(json['achievements'] ?? []),
      unlockedAvatars: List<String>.from(json['unlockedAvatars'] ?? []),
      unlockedBorders: List<String>.from(json['unlockedBorders'] ?? []),
      selectedBorder: json['selectedBorder'],
      weeklyMatchesPlayed: json['weeklyMatchesPlayed'] ?? 0,
      lastWeeklyRewardDate: parseDate(json['lastWeeklyRewardDate']),
      weeklyLeague: json['weeklyLeague'],
      powerUps: Map<String, int>.from(json['powerUps'] ?? {'fiftyFifty': 5, 'timeFreeze': 5}),
      todayCoinsEarned: json['todayCoinsEarned'] ?? 0,
      lastCoinResetDate: parseDate(json['lastCoinResetDate']),
      lastDailyLoginRewardDate: parseDate(json['lastDailyLoginRewardDate']),
      loginStreak: json['loginStreak'] ?? 0,
      lastLoginDate: parseDate(json['lastLoginDate']),
      lastRewardedMatchId: json['lastRewardedMatchId'],
      lastLeagueRewardClaimed: json['lastLeagueRewardClaimed'],
      arenaBreakerWins: json['arenaBreakerWins'] ?? 0,
      arenaBreakerLosses: json['arenaBreakerLosses'] ?? 0,
      averageAccuracy: (json['averageAccuracy'] ?? 0.0).toDouble(),
      oneOptionLifelines: json['oneOptionLifelines'] ?? 0,
      twoOptionLifelines: json['twoOptionLifelines'] ?? 0,
      rankProtectionMatches: json['rankProtectionMatches'] ?? 0,
      rankProtectionActive: json['rankProtectionActive'] ?? false,
      ownedShieldPackage: json['ownedShieldPackage'] ?? 0,
      guildId: json['guildId'],
      weeklyXp: json['weeklyXp'] ?? 0,
      weeklyWins: json['weeklyWins'] ?? 0,
      guildBattlesPlayed: json['guildBattlesPlayed'] ?? 0,
      guildBattlesWon: json['guildBattlesWon'] ?? 0,
      totalGuildXpContributed: json['totalGuildXpContributed'] ?? 0,
      lastDailyBonusDate: parseDate(json['lastDailyBonusDate']),
      totalQuestionsCorrect: json['totalQuestionsCorrect'] ?? 0,
      totalPerfectScores: json['totalPerfectScores'] ?? 0,
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
        'eloRating': eloRating,
        'currentWinStreak': currentWinStreak,
        'highestWinStreak': highestWinStreak,
        'achievements': achievements,
        'unlockedAvatars': unlockedAvatars,
        'unlockedBorders': unlockedBorders,
        'selectedBorder': selectedBorder,
        'weeklyMatchesPlayed': weeklyMatchesPlayed,
        'lastWeeklyRewardDate': lastWeeklyRewardDate != null ? Timestamp.fromDate(lastWeeklyRewardDate!) : null,
        'weeklyLeague': weeklyLeague,
        'powerUps': powerUps,
        'todayCoinsEarned': todayCoinsEarned,
        'lastCoinResetDate': Timestamp.fromDate(lastCoinResetDate),
        'lastDailyLoginRewardDate': Timestamp.fromDate(lastDailyLoginRewardDate),
        'loginStreak': loginStreak,
        'lastLoginDate': Timestamp.fromDate(lastLoginDate),
        'lastRewardedMatchId': lastRewardedMatchId,
        'lastLeagueRewardClaimed': lastLeagueRewardClaimed,
        'arenaBreakerWins': arenaBreakerWins,
        'arenaBreakerLosses': arenaBreakerLosses,
        'averageAccuracy': averageAccuracy,
        'oneOptionLifelines': oneOptionLifelines,
        'twoOptionLifelines': twoOptionLifelines,
        'rankProtectionMatches': rankProtectionMatches,
        'rankProtectionActive': rankProtectionActive,
        'ownedShieldPackage': ownedShieldPackage,
        'guildId': guildId,
        'weeklyXp': weeklyXp,
        'weeklyWins': weeklyWins,
        'guildBattlesPlayed': guildBattlesPlayed,
        'guildBattlesWon': guildBattlesWon,
        'totalGuildXpContributed': totalGuildXpContributed,
        'lastDailyBonusDate': lastDailyBonusDate != null ? Timestamp.fromDate(lastDailyBonusDate!) : null,
        'matchesPlayed': matchesPlayed,
        'totalQuestionsCorrect': totalQuestionsCorrect,
        'totalPerfectScores': totalPerfectScores,
      };

  UserModel copyWith({
    String? username,
    String? avatarUrl,
    int? level,
    int? xp,
    int? coins,
    int? todayCoinsEarned,
    DateTime? lastCoinResetDate,
    DateTime? lastDailyLoginRewardDate,
    int? loginStreak,
    DateTime? lastLoginDate,
    int? currentWinStreak,
    int? highestWinStreak,
    String? lastRewardedMatchId,
    String? lastLeagueRewardClaimed,
    String? rank,
    int? subRank,
    int? rankPoints,
    int? wins,
    int? losses,
    int? draws,
    int? eloRating,
    DateTime? lastDailyBonusDate,
    List<String>? achievements,
    List<String>? unlockedAvatars,
    List<String>? unlockedBorders,
    String? selectedBorder,
    int? weeklyMatchesPlayed,
    DateTime? lastWeeklyRewardDate,
    String? weeklyLeague,
    Map<String, int>? powerUps,
    int? arenaBreakerWins,
    int? arenaBreakerLosses,
    double? averageAccuracy,
    bool clearSubRank = false,
    int? oneOptionLifelines,
    int? twoOptionLifelines,
    int? rankProtectionMatches,
    bool? rankProtectionActive,
    int? ownedShieldPackage,
    String? guildId,
    bool clearGuildId = false,
    int? weeklyXp,
    int? weeklyWins,
    int? guildBattlesPlayed,
    int? guildBattlesWon,
    int? totalGuildXpContributed,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      coins: coins ?? this.coins,
      todayCoinsEarned: todayCoinsEarned ?? this.todayCoinsEarned,
      lastCoinResetDate: lastCoinResetDate ?? this.lastCoinResetDate,
      lastDailyLoginRewardDate: lastDailyLoginRewardDate ?? this.lastDailyLoginRewardDate,
      loginStreak: loginStreak ?? this.loginStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      currentWinStreak: currentWinStreak ?? this.currentWinStreak,
      highestWinStreak: highestWinStreak ?? this.highestWinStreak,
      lastRewardedMatchId: lastRewardedMatchId ?? this.lastRewardedMatchId,
      lastLeagueRewardClaimed: lastLeagueRewardClaimed ?? this.lastLeagueRewardClaimed,
      rank: rank ?? this.rank,
      subRank: clearSubRank ? null : (subRank ?? this.subRank),
      rankPoints: rankPoints ?? this.rankPoints,
      wins: wins ?? this.wins,
      losses: losses ?? this.losses,
      draws: draws ?? this.draws,
      eloRating: eloRating ?? this.eloRating,
      lastDailyBonusDate: lastDailyBonusDate ?? this.lastDailyBonusDate,
      achievements: achievements ?? this.achievements,
      unlockedAvatars: unlockedAvatars ?? this.unlockedAvatars,
      unlockedBorders: unlockedBorders ?? this.unlockedBorders,
      selectedBorder: selectedBorder ?? this.selectedBorder,
      weeklyMatchesPlayed: weeklyMatchesPlayed ?? this.weeklyMatchesPlayed,
      lastWeeklyRewardDate: lastWeeklyRewardDate ?? this.lastWeeklyRewardDate,
      weeklyLeague: weeklyLeague ?? this.weeklyLeague,
      powerUps: powerUps ?? this.powerUps,
      arenaBreakerWins: arenaBreakerWins ?? this.arenaBreakerWins,
      arenaBreakerLosses: arenaBreakerLosses ?? this.arenaBreakerLosses,
      averageAccuracy: averageAccuracy ?? this.averageAccuracy,
      oneOptionLifelines: oneOptionLifelines ?? this.oneOptionLifelines,
      twoOptionLifelines: twoOptionLifelines ?? this.twoOptionLifelines,
      rankProtectionMatches: rankProtectionMatches ?? this.rankProtectionMatches,
      rankProtectionActive: rankProtectionActive ?? this.rankProtectionActive,
      ownedShieldPackage: ownedShieldPackage ?? this.ownedShieldPackage,
      guildId: clearGuildId ? null : (guildId ?? this.guildId),
      weeklyXp: weeklyXp ?? this.weeklyXp,
      weeklyWins: weeklyWins ?? this.weeklyWins,
      guildBattlesPlayed: guildBattlesPlayed ?? this.guildBattlesPlayed,
      guildBattlesWon: guildBattlesWon ?? this.guildBattlesWon,
      totalGuildXpContributed: totalGuildXpContributed ?? this.totalGuildXpContributed,
    );
  }
}
