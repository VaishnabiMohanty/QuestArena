// WHAT THIS FILE DOES:
// Represents a player waiting in the queue to find an opponent.

class MatchmakingModel {
  final String uid;
  final String username;
  final String? avatarUrl;
  final String rank;
  final String status;
  final String? matchedWith;
  final String? gameRoomId;
  final int? categoryId;
  final String categoryName;
  final int eloRating;
  final int searchRange;
  final DateTime searchStartedAt;

  MatchmakingModel({
    required this.uid,
    required this.username,
    this.avatarUrl,
    required this.rank,
    this.status = 'searching',
    this.matchedWith,
    this.gameRoomId,
    this.categoryId,
    this.categoryName = 'Mixed / Random',
    this.eloRating = 1200,
    this.searchRange = 100,
    required this.searchStartedAt,
  });

  factory MatchmakingModel.fromJson(Map<String, dynamic> json) {
    return MatchmakingModel(
      uid: json['uid'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatarUrl'],
      rank: json['rank'] ?? 'Bronze',
      status: json['status'] ?? 'searching',
      matchedWith: json['matchedWith'],
      gameRoomId: json['gameRoomId'],
      categoryId: json['categoryId'],
      categoryName: json['categoryName'] ?? 'Mixed / Random',
      eloRating: json['eloRating'] ?? 1200,
      searchRange: json['searchRange'] ?? 100,
      searchStartedAt: json['searchStartedAt'] != null 
          ? DateTime.parse(json['searchStartedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'username': username,
    'avatarUrl': avatarUrl,
    'rank': rank,
    'status': status,
    'matchedWith': matchedWith,
    'gameRoomId': gameRoomId,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'eloRating': eloRating,
    'searchRange': searchRange,
    'searchStartedAt': searchStartedAt.toIso8601String(),
  };
}
