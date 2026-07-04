// WHAT THIS FILE DOES:
// The "Source of Truth" for a live 1v1 match.

import 'package:cloud_firestore/cloud_firestore.dart';

class GameRoomModel {
  final String roomId;
  final String roomCode;
  final String status;
  final Map<String, dynamic> player1;
  final Map<String, dynamic>? player2;
  final List<dynamic> questions;
  final int currentQuestionIndex;
  final DateTime? questionStartedAt;
  final String? winnerId;
  final List<String> claimedRewards;
  final List<String> rematchRequests;
  final String? nextMatchId;
  final int? categoryId;
  final String categoryName;
  final bool isRanked;
  final Map<String, dynamic> powerups;
  
  // Arena Breaker Fields
  final bool isArenaBreaker;
  final int arenaBreakerRound;
  final Map<String, dynamic>? arenaBreakerQuestion;
  final Map<String, dynamic> arenaBreakerSubmissions;
  final bool isArenaBreakerWin;
  final String? arenaBreakerStatusMessage;

  // Disconnect & Forfeit Fields
  final Map<String, dynamic> presence;
  final String? forfeitWinnerId;
  final String? guildBattleId;

  GameRoomModel({
    required this.roomId,
    this.roomCode = '',
    required this.status,
    required this.player1,
    this.player2,
    required this.questions,
    this.currentQuestionIndex = 0,
    this.questionStartedAt,
    this.winnerId,
    this.claimedRewards = const [],
    this.rematchRequests = const [],
    this.nextMatchId,
    this.categoryId,
    this.categoryName = 'Mixed / Random',
    this.isRanked = true,
    this.powerups = const {},
    this.isArenaBreaker = false,
    this.arenaBreakerRound = 0,
    this.arenaBreakerQuestion,
    this.arenaBreakerSubmissions = const {},
    this.isArenaBreakerWin = false,
    this.arenaBreakerStatusMessage,
    this.presence = const {},
    this.forfeitWinnerId,
    this.guildBattleId,
  });

  factory GameRoomModel.fromJson(Map<String, dynamic> json) {
    return GameRoomModel(
      roomId: json['roomId'] ?? '',
      roomCode: json['roomCode'] ?? '',
      status: json['status'] ?? 'waiting',
      player1: Map<String, dynamic>.from(json['player1'] ?? {}),
      player2: json['player2'] != null ? Map<String, dynamic>.from(json['player2']) : null,
      questions: List<dynamic>.from(json['questions'] ?? []),
      currentQuestionIndex: json['currentQuestionIndex'] ?? 0,
      questionStartedAt: json['questionStartedAt'] != null 
          ? (json['questionStartedAt'] is Timestamp 
              ? (json['questionStartedAt'] as Timestamp).toDate() 
              : DateTime.tryParse(json['questionStartedAt'].toString()))
          : null,
      winnerId: json['winnerId'],
      claimedRewards: List<String>.from(json['claimedRewards'] ?? []),
      rematchRequests: List<String>.from(json['rematchRequests'] ?? []),
      nextMatchId: json['nextMatchId'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? 'Mixed / Random',
      isRanked: json['isRanked'] ?? true,
      powerups: Map<String, dynamic>.from(json['powerups'] ?? {}),
      isArenaBreaker: json['isArenaBreaker'] ?? false,
      arenaBreakerRound: json['arenaBreakerRound'] ?? 0,
      arenaBreakerQuestion: json['arenaBreakerQuestion'],
      arenaBreakerSubmissions: Map<String, dynamic>.from(json['arenaBreakerSubmissions'] ?? {}),
      isArenaBreakerWin: json['isArenaBreakerWin'] ?? false,
      arenaBreakerStatusMessage: json['arenaBreakerStatusMessage'],
      presence: Map<String, dynamic>.from(json['presence'] ?? {}),
      forfeitWinnerId: json['forfeitWinnerId'],
      guildBattleId: json['guildBattleId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'roomId': roomId,
    'roomCode': roomCode,
    'status': status,
    'player1': player1,
    'player2': player2,
    'questions': questions,
    'currentQuestionIndex': currentQuestionIndex,
    'questionStartedAt': questionStartedAt != null ? Timestamp.fromDate(questionStartedAt!) : null,
    'winnerId': winnerId,
    'claimedRewards': claimedRewards,
    'rematchRequests': rematchRequests,
    'nextMatchId': nextMatchId,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'isRanked': isRanked,
    'powerups': powerups,
    'isArenaBreaker': isArenaBreaker,
    'arenaBreakerRound': arenaBreakerRound,
    'arenaBreakerQuestion': arenaBreakerQuestion,
    'arenaBreakerSubmissions': arenaBreakerSubmissions,
    'isArenaBreakerWin': isArenaBreakerWin,
    'arenaBreakerStatusMessage': arenaBreakerStatusMessage,
    'presence': presence,
    'forfeitWinnerId': forfeitWinnerId,
    'guildBattleId': guildBattleId,
  };

  GameRoomModel copyWith({
    String? status,
    Map<String, dynamic>? player1,
    Map<String, dynamic>? player2,
    int? currentQuestionIndex,
    DateTime? questionStartedAt,
    String? winnerId,
    bool? isRanked,
    bool? isArenaBreaker,
    int? arenaBreakerRound,
    Map<String, dynamic>? arenaBreakerQuestion,
    Map<String, dynamic>? arenaBreakerSubmissions,
    bool? isArenaBreakerWin,
    Map<String, dynamic>? powerups,
    String? guildBattleId,
  }) {
    return GameRoomModel(
      roomId: roomId,
      roomCode: roomCode,
      status: status ?? this.status,
      player1: player1 ?? this.player1,
      player2: player2 ?? this.player2,
      questions: questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      questionStartedAt: questionStartedAt ?? this.questionStartedAt,
      winnerId: winnerId ?? this.winnerId,
      claimedRewards: claimedRewards,
      rematchRequests: rematchRequests,
      nextMatchId: nextMatchId,
      categoryId: categoryId,
      categoryName: categoryName,
      isRanked: isRanked ?? this.isRanked,
      powerups: powerups ?? this.powerups,
      isArenaBreaker: isArenaBreaker ?? this.isArenaBreaker,
      arenaBreakerRound: arenaBreakerRound ?? this.arenaBreakerRound,
      arenaBreakerQuestion: arenaBreakerQuestion ?? this.arenaBreakerQuestion,
      arenaBreakerSubmissions: arenaBreakerSubmissions ?? this.arenaBreakerSubmissions,
      isArenaBreakerWin: isArenaBreakerWin ?? this.isArenaBreakerWin,
      arenaBreakerStatusMessage: arenaBreakerStatusMessage,
      presence: presence,
      forfeitWinnerId: forfeitWinnerId,
      guildBattleId: guildBattleId ?? this.guildBattleId,
    );
  }
}
