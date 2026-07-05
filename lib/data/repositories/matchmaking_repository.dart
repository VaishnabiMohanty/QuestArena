// WHAT THIS FILE DOES:
// Manages the player's presence in the matchmaking queue.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/game_utils.dart';
import '../models/matchmaking_model.dart';

class MatchmakingRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final Dio _dio;

  MatchmakingRepository(this._dio);

  // Start searching for a match
  Future<void> startSearching(MatchmakingModel ticket) async {
    // 1. Save our ticket (Overwrites existing to ensure latest category is used)
    await _db.collection('matchmaking').doc(ticket.uid).set(ticket.toJson());

    // 2. Try to find a match
    await _tryMatch(ticket);
  }

  // Expansion method to be called periodically by the client
  Future<void> expandSearch(String uid) async {
    final doc = await _db.collection('matchmaking').doc(uid).get();
    if (!doc.exists || doc.data() == null) return;
    
    final data = doc.data()!;
    if (data['status'] != 'searching') return;

    final currentRange = (data['searchRange'] as num? ?? 100).toInt();
    final newRange = currentRange + 100;

    // Update the ticket
    await _db.collection('matchmaking').doc(uid).update({'searchRange': newRange});
    
    // Try matching again with the new range
    final updatedTicket = MatchmakingModel.fromJson({...data, 'searchRange': newRange});
    await _tryMatch(updatedTicket);
  }

  Future<void> _tryMatch(MatchmakingModel ticket) async {
    // Look for another player who is also searching
    final potentialMatches = await _db.collection('matchmaking')
        .where('status', isEqualTo: 'searching')
        .get();

    QueryDocumentSnapshot<Map<String, dynamic>>? matchDoc;
    int bestEloDiff = 999999;

    for (final doc in potentialMatches.docs) {
      if (doc.id == ticket.uid) continue;

      final data = doc.data();
      
      // 1. Category must match
      if (data['categoryId'] != ticket.categoryId) continue;

      // 2. ELO check
      final int opponentElo = (data['eloRating'] as num? ?? 1200).toInt();
      final int ticketElo = ticket.eloRating;
      final int eloDiff = (ticketElo - opponentElo).abs();
      
      // Match if within search range of EITHER player
      final int opponentRange = (data['searchRange'] as num? ?? 100).toInt();
      final int ticketRange = ticket.searchRange;
      final int maxAllowedDiff = ticketRange > opponentRange ? ticketRange : opponentRange;

      if (eloDiff <= maxAllowedDiff) {
        if (eloDiff < bestEloDiff) {
          bestEloDiff = eloDiff.toInt();
          matchDoc = doc;
        }
      }
    }

    if (matchDoc != null) {
      final opponentUid = matchDoc.id;
      final roomId = _db.collection('gameRooms').doc().id;
      
      final player1Data = ticket.toJson();
      final player2Data = matchDoc.data();

      List<Map<String, dynamic>> questions = [];
      try {
        final response = await _dio.get(
          ApiConstants.triviaUrlForCategory(ticket.categoryId),
        );
        questions = (response.data['results'] as List).map((q) => {
          'question': GameUtils.decodeHtmlEntities(q['question']),
          'correct_answer': GameUtils.decodeHtmlEntities(q['correct_answer']),
          'incorrect_answers': (q['incorrect_answers'] as List)
              .map((a) => GameUtils.decodeHtmlEntities(a))
              .toList(),
        }).toList();
      } catch (e) {
        debugPrint("Trivia API Error: $e");
        questions = GameUtils.getFallbackQuestions();
      }

      await _db.collection('gameRooms').doc(roomId).set({
        'roomId': roomId,
        'roomCode': '',
        'categoryId': ticket.categoryId,
        'categoryName': ticket.categoryName,
        'status': 'waiting',
        'isRanked': true,
        'player1': {...player1Data, 'isReady': false, 'score': 0, 'answers': []},
        'player2': {...player2Data, 'isReady': false, 'score': 0, 'answers': []},
        'createdAt': FieldValue.serverTimestamp(),
        'questions': questions,
      });

      final batch = _db.batch();
      batch.update(_db.collection('matchmaking').doc(ticket.uid), {
        'status': 'matched',
        'matchedWith': opponentUid,
        'gameRoomId': roomId,
      });
      batch.update(_db.collection('matchmaking').doc(opponentUid), {
        'status': 'matched',
        'matchedWith': ticket.uid,
        'gameRoomId': roomId,
      });
      await batch.commit();
    }
  }

  // Cancel searching
  Future<void> cancelSearching(String uid) async {
    await _db.collection('matchmaking').doc(uid).delete();
  }

  // Listen to the matchmaking ticket for updates (e.g., when status becomes 'matched')
  Stream<MatchmakingModel?> watchTicket(String uid) {
    return _db.collection('matchmaking').doc(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return MatchmakingModel.fromJson(doc.data()!);
    });
  }
}
