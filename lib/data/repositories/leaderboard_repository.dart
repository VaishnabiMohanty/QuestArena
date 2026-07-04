// WHAT THIS FILE DOES:
// Fetches the global rankings from Firestore.
//
// KEY CONCEPTS IN THIS FILE:
// • Querying: Using .orderBy() and .limit() to get specific data.
// • Mapping: Converting a list of Firestore documents into a list of Models.

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leaderboard_model.dart';
import '../../core/errors/result.dart';
import '../../core/errors/app_error.dart';

class LeaderboardRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<Result<List<LeaderboardModel>>> getTopPlayers() async {
    try {
      // Use single orderBy to avoid composite index requirement
      final snapshot = await _db
          .collection('users')
          .orderBy('xp', descending: true)
          .limit(100)
          .get();

      final players = snapshot.docs
          .map((doc) => LeaderboardModel.fromJson(doc.data()))
          .toList();

      // Perform secondary sorting in memory
      players.sort((a, b) {
        int cmp = b.xp.compareTo(a.xp);
        if (cmp == 0) cmp = b.level.compareTo(a.level);
        return cmp;
      });

      return Success(players);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  Stream<List<LeaderboardModel>> watchTopPlayers() {
    return _db
        .collection('users')
        .orderBy('xp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      final players = snapshot.docs
          .map((doc) => LeaderboardModel.fromJson(doc.data()))
          .toList();

      // Perform secondary sorting in memory to avoid "Failed Precondition" index errors
      players.sort((a, b) {
        int cmp = b.xp.compareTo(a.xp);
        if (cmp == 0) cmp = b.level.compareTo(a.level);
        return cmp;
      });

      return players;
    });
  }
}
