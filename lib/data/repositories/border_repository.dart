import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/errors/app_error.dart';
import '../../core/errors/result.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class BorderRepository {
  final FirestoreService _service;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  BorderRepository(this._service);

  Future<Result<void>> selectBorder(String uid, String borderId) async {
    try {
      await _service.setData(
        path: 'users/$uid',
        data: {'selectedBorder': borderId},
      );
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  Future<Result<void>> unlockBorder(String uid, String borderId) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'unlockedBorders': FieldValue.arrayUnion([borderId]),
      });
      return const Success(null);
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  Future<Result<void>> claimWeeklyReward({
    required String uid,
    required int coinsReward,
    required String? borderToUnlock,
    required String currentLeague,
  }) async {
    final userRef = _firestore.collection('users').doc(uid);

    try {
      return await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) {
          return const Failure(DatabaseError("User not found"));
        }

        final user = UserModel.fromJson(snapshot.data()!);

        // Prevent duplicate rewards for the same week
        final now = DateTime.now();
        if (user.lastWeeklyRewardDate != null) {
          final lastReward = user.lastWeeklyRewardDate!;
          final isSameWeek = _isSameWeek(now, lastReward);
          if (isSameWeek) {
            return const Failure(DatabaseError("Weekly reward already claimed"));
          }
        }

        Map<String, dynamic> updates = {
          'coins': user.coins + coinsReward,
          'lastWeeklyRewardDate': Timestamp.fromDate(now),
          'weeklyMatchesPlayed': 0, // Reset for next week
          'weeklyLeague': currentLeague,
        };

        if (borderToUnlock != null && !user.unlockedBorders.contains(borderToUnlock)) {
          updates['unlockedBorders'] = FieldValue.arrayUnion([borderToUnlock]);
        }

        transaction.update(userRef, updates);
        return const Success(null);
      });
    } catch (e) {
      return Failure(DatabaseError(e.toString()));
    }
  }

  bool _isSameWeek(DateTime d1, DateTime d2) {
    // Basic week check: if they are in the same year and have the same week number.
    // A more robust check might be needed for edge cases.
    // For now, let's use a simple 7-day difference check or calendar week.
    
    // ISO week number would be best.
    final week1 = _weekNumber(d1);
    final week2 = _weekNumber(d2);
    return d1.year == d2.year && week1 == week2;
  }

  int _weekNumber(DateTime date) {
    int dayOfYear = int.parse(_formatDate(date, 'D'));
    int woy = ((dayOfYear - date.weekday + 10) / 7).floor();
    if (woy < 1) {
      woy = _weeksInYear(date.year - 1);
    } else if (woy > _weeksInYear(date.year)) {
      woy = 1;
    }
    return woy;
  }

  int _weeksInYear(int year) {
    DateTime d = DateTime(year, 12, 28);
    int dayOfYear = int.parse(_formatDate(d, 'D'));
    return ((dayOfYear - d.weekday + 10) / 7).floor();
  }

  String _formatDate(DateTime date, String format) {
    // Simple mock for day of year if needed, or use intl package if available.
    // For simplicity, let's just use a timestamp based check.
    if (format == 'D') {
      return date.difference(DateTime(date.year, 1, 1)).inDays.toString();
    }
    return '';
  }

  // Simplified isSameWeek for production use without external deps
  bool isSameCalendarWeek(DateTime date1, DateTime date2) {
    final diff = date1.difference(date2).inDays.abs();
    if (diff >= 7) return false;
    // Check if they are on different sides of a Sunday
    // In Dart, weekday 7 is Sunday.
    return (date1.weekday >= date2.weekday && diff < 7) || (date1.weekday < date2.weekday && diff < date1.weekday);
  }
}
