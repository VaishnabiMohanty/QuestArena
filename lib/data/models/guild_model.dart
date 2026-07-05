import 'package:cloud_firestore/cloud_firestore.dart';

enum GuildBattleStatus { idle, readyCheck, searching, matchmaking, matched, live, completed, cancelled }

class GuildModel {
  final String id;
  final String name;
  final String iconId;
  final String code;
  final String leaderUid;
  final int xp;
  final int level;
  final int totalWins;
  final int totalLosses;
  final List<String> memberUids;
  final DateTime createdAt;
  final int weeklyXp;
  final int weeklyWins;
  final String? currentBattleId;
  final GuildBattleStatus battleStatus;
  final String? selectedCategoryId;
  final String? selectedCategoryName;
  final List<String> readyPlayerUids;

  GuildModel({
    required this.id,
    required this.name,
    required this.iconId,
    required this.code,
    required this.leaderUid,
    this.xp = 0,
    this.level = 1,
    this.totalWins = 0,
    this.totalLosses = 0,
    required this.memberUids,
    required this.createdAt,
    this.weeklyXp = 0,
    this.weeklyWins = 0,
    this.currentBattleId,
    this.battleStatus = GuildBattleStatus.idle,
    this.selectedCategoryId,
    this.selectedCategoryName,
    this.readyPlayerUids = const [],
  });

  factory GuildModel.fromJson(Map<String, dynamic> json) {
    return GuildModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      iconId: json['iconId'] ?? '1',
      code: json['code'] ?? '',
      leaderUid: json['leaderUid'] ?? '',
      xp: json['xp'] ?? 0,
      level: json['level'] ?? 1,
      totalWins: json['totalWins'] ?? 0,
      totalLosses: json['totalLosses'] ?? 0,
      memberUids: List<String>.from(json['memberUids'] ?? []),
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      weeklyXp: json['weeklyXp'] ?? 0,
      weeklyWins: json['weeklyWins'] ?? 0,
      currentBattleId: json['currentBattleId'],
      battleStatus: GuildBattleStatus.values.firstWhere(
        (e) => e.name == json['battleStatus'],
        orElse: () => GuildBattleStatus.idle,
      ),
      selectedCategoryId: json['selectedCategoryId'],
      selectedCategoryName: json['selectedCategoryName'],
      readyPlayerUids: List<String>.from(json['readyPlayerUids'] ?? []),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'iconId': iconId,
        'code': code,
        'leaderUid': leaderUid,
        'xp': xp,
        'level': level,
        'totalWins': totalWins,
        'totalLosses': totalLosses,
        'memberUids': memberUids,
        'createdAt': Timestamp.fromDate(createdAt),
        'weeklyXp': weeklyXp,
        'weeklyWins': weeklyWins,
        'currentBattleId': currentBattleId,
        'battleStatus': battleStatus.name,
        'selectedCategoryId': selectedCategoryId,
        'selectedCategoryName': selectedCategoryName,
        'readyPlayerUids': readyPlayerUids,
      };

  GuildModel copyWith({
    String? name,
    String? iconId,
    String? leaderUid,
    int? xp,
    int? level,
    int? totalWins,
    int? totalLosses,
    List<String>? memberUids,
    int? weeklyXp,
    int? weeklyWins,
    String? currentBattleId,
    bool clearBattleId = false,
    GuildBattleStatus? battleStatus,
    String? selectedCategoryId,
    String? selectedCategoryName,
    List<String>? readyPlayerUids,
  }) {
    return GuildModel(
      id: id,
      name: name ?? this.name,
      iconId: iconId ?? this.iconId,
      code: code,
      leaderUid: leaderUid ?? this.leaderUid,
      xp: xp ?? this.xp,
      level: level ?? this.level,
      totalWins: totalWins ?? this.totalWins,
      totalLosses: totalLosses ?? this.totalLosses,
      memberUids: memberUids ?? this.memberUids,
      createdAt: createdAt,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      weeklyWins: weeklyWins ?? this.weeklyWins,
      currentBattleId: clearBattleId ? null : (currentBattleId ?? this.currentBattleId),
      battleStatus: battleStatus ?? this.battleStatus,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedCategoryName: selectedCategoryName ?? this.selectedCategoryName,
      readyPlayerUids: readyPlayerUids ?? this.readyPlayerUids,
    );
  }
}

class GuildBattleQueueModel {
  final String guildId;
  final String guildName;
  final String guildIconId;
  final int guildXp;
  final int averageRankPoints;
  final List<String> readyPlayerUids;
  final DateTime joinedAt;

  GuildBattleQueueModel({
    required this.guildId,
    required this.guildName,
    required this.guildIconId,
    required this.guildXp,
    required this.averageRankPoints,
    required this.readyPlayerUids,
    required this.joinedAt,
  });

  factory GuildBattleQueueModel.fromJson(Map<String, dynamic> json) {
    return GuildBattleQueueModel(
      guildId: json['guildId'] ?? '',
      guildName: json['guildName'] ?? '',
      guildIconId: json['guildIconId'] ?? '1',
      guildXp: json['guildXp'] ?? 0,
      averageRankPoints: json['averageRankPoints'] ?? 0,
      readyPlayerUids: List<String>.from(json['readyPlayerUids'] ?? []),
      joinedAt: (json['joinedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() => {
        'guildId': guildId,
        'guildName': guildName,
        'guildIconId': guildIconId,
        'guildXp': guildXp,
        'averageRankPoints': averageRankPoints,
        'readyPlayerUids': readyPlayerUids,
        'joinedAt': Timestamp.fromDate(joinedAt),
      };
}

class GuildBattleMatchModel {
  final String id;
  final String guildAId;
  final String guildBId;
  final String guildAName;
  final String guildBName;
  final String guildAIcon;
  final String guildBIcon;
  final List<String> guildAPlayers;
  final List<String> guildBPlayers;
  final Map<String, int> playerScores; // uid -> score
  final Map<String, String> playerStatus; // uid -> status (playing, finished)
  final int guildAScore;
  final int guildBScore;
  final GuildBattleStatus status;
  final DateTime startTime;
  final DateTime? endedAt;
  final Map<String, bool> readyStatus; // uid -> ready
  final int readyTimerSeconds;

  GuildBattleMatchModel({
    required this.id,
    required this.guildAId,
    required this.guildBId,
    required this.guildAName,
    required this.guildBName,
    required this.guildAIcon,
    required this.guildBIcon,
    required this.guildAPlayers,
    required this.guildBPlayers,
    this.playerScores = const {},
    this.playerStatus = const {},
    this.guildAScore = 0,
    this.guildBScore = 0,
    this.status = GuildBattleStatus.idle,
    required this.startTime,
    this.endedAt,
    this.readyStatus = const {},
    this.readyTimerSeconds = 20,
  });

  factory GuildBattleMatchModel.fromJson(Map<String, dynamic> json) {
    return GuildBattleMatchModel(
      id: json['id'] ?? '',
      guildAId: json['guildAId'] ?? '',
      guildBId: json['guildBId'] ?? '',
      guildAName: json['guildAName'] ?? '',
      guildBName: json['guildBName'] ?? '',
      guildAIcon: json['guildAIcon'] ?? '1',
      guildBIcon: json['guildBIcon'] ?? '1',
      guildAPlayers: List<String>.from(json['guildAPlayers'] ?? []),
      guildBPlayers: List<String>.from(json['guildBPlayers'] ?? []),
      playerScores: Map<String, int>.from(json['playerScores'] ?? {}),
      playerStatus: Map<String, String>.from(json['playerStatus'] ?? {}),
      guildAScore: json['guildAScore'] ?? 0,
      guildBScore: json['guildBScore'] ?? 0,
      status: GuildBattleStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => GuildBattleStatus.idle,
      ),
      startTime: (json['startTime'] as Timestamp).toDate(),
      endedAt: json['endedAt'] != null ? (json['endedAt'] as Timestamp).toDate() : null,
      readyStatus: Map<String, bool>.from(json['readyStatus'] ?? {}),
      readyTimerSeconds: json['readyTimerSeconds'] ?? 20,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'guildAId': guildAId,
        'guildBId': guildBId,
        'guildAName': guildAName,
        'guildBName': guildBName,
        'guildAIcon': guildAIcon,
        'guildBIcon': guildBIcon,
        'guildAPlayers': guildAPlayers,
        'guildBPlayers': guildBPlayers,
        'playerScores': playerScores,
        'playerStatus': playerStatus,
        'guildAScore': guildAScore,
        'guildBScore': guildBScore,
        'status': status.name,
        'startTime': Timestamp.fromDate(startTime),
        'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
        'readyStatus': readyStatus,
        'readyTimerSeconds': readyTimerSeconds,
      };
}
