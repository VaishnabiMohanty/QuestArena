// WHAT THIS FILE DOES:
// A lightweight model for showing players in the global rankings.
// Now derived from the same source of truth as UserModel.

class LeaderboardModel {
  final String uid;
  final String username;
  final String? avatarUrl;
  final int level;
  final int xp;
  final String rank;
  final int? subRank;
  final int wins;
  final int losses;
  final int draws;
  final int currentWinStreak;
  final double averageAccuracy;
  final int eloRating;
  final String? selectedBorder;
  final String? guildId;

  LeaderboardModel({
    required this.uid,
    required this.username,
    this.avatarUrl,
    required this.level,
    required this.xp,
    required this.rank,
    this.subRank,
    this.wins = 0,
    this.losses = 0,
    this.draws = 0,
    this.currentWinStreak = 0,
    this.averageAccuracy = 0.0,
    this.eloRating = 1200,
    this.selectedBorder,
    this.guildId,
  });

  // Calculated values
  int get totalMatches => wins + losses + draws;

  double get winRate {
    if (totalMatches == 0) return 0.0;
    return (wins / totalMatches) * 100;
  }

  // MVP Score for ranking logic
  double get mvpScore => (xp / 10) + (wins * 10) + (averageAccuracy * 2) + (currentWinStreak * 5);

  factory LeaderboardModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardModel(
      uid: json['uid'] ?? json['friendUid'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'],
      level: json['level'] ?? 1,
      xp: json['xp'] ?? 0,
      rank: json['rank'] ?? 'Unranked',
      subRank: json['subRank'],
      wins: json['wins'] ?? json['totalWins'] ?? 0,
      losses: json['losses'] ?? json['totalLosses'] ?? 0,
      draws: json['draws'] ?? json['totalDraws'] ?? 0,
      currentWinStreak: json['currentWinStreak'] ?? json['currentStreak'] ?? 0,
      averageAccuracy: (json['averageAccuracy'] ?? 0).toDouble(),
      eloRating: json['eloRating'] ?? 1200,
      selectedBorder: json['selectedBorder'],
      guildId: json['guildId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'username': username,
    'avatarUrl': avatarUrl,
    'level': level,
    'xp': xp,
    'rank': rank,
    'subRank': subRank,
    'wins': wins,
    'losses': losses,
    'draws': draws,
    'currentWinStreak': currentWinStreak,
    'averageAccuracy': averageAccuracy,
    'eloRating': eloRating,
    'selectedBorder': selectedBorder,
    'guildId': guildId,
  };
}
