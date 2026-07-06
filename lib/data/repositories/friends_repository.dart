import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/leaderboard_model.dart';

class FriendsRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Send a friend request
  Future<void> sendFriendRequest({
    required UserModel sender,
    required String receiverUid,
    required String receiverUsername,
    required String? receiverAvatar,
  }) async {
    final requestId = _generateRequestId(sender.uid, receiverUid);
    
    await _db.collection('friendRequests').doc(requestId).set({
      'senderUid': sender.uid,
      'receiverUid': receiverUid,
      'senderUsername': sender.username,
      'receiverUsername': receiverUsername,
      'senderAvatar': sender.avatarUrl,
      'senderBorder': sender.selectedBorder,
      'receiverAvatar': receiverAvatar,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Accept a friend request
  Future<void> acceptFriendRequest(String requestId, Map<String, dynamic> requestData) async {
    final senderUid = requestData['senderUid'];
    final receiverUid = requestData['receiverUid'];

    final batch = _db.batch();

    // 1. Remove the request
    batch.delete(_db.collection('friendRequests').doc(requestId));

    // 2. Add to both users' friends subcollection
    final senderDoc = await _db.collection('users').doc(senderUid).get();
    final receiverDoc = await _db.collection('users').doc(receiverUid).get();

    if (senderDoc.exists && receiverDoc.exists) {
      final senderData = senderDoc.data()!;
      final receiverData = receiverDoc.data()!;

      batch.set(_db.collection('users').doc(receiverUid).collection('friends').doc(senderUid), {
        'friendUid': senderUid,
        'username': senderData['username'],
        'avatarUrl': senderData['avatarUrl'],
        'level': senderData['level'],
        'rank': senderData['rank'],
        'subRank': senderData['subRank'],
        'xp': senderData['xp'],
        'addedAt': FieldValue.serverTimestamp(),
      });

      batch.set(_db.collection('users').doc(senderUid).collection('friends').doc(receiverUid), {
        'friendUid': receiverUid,
        'username': receiverData['username'],
        'avatarUrl': receiverData['avatarUrl'],
        'level': receiverData['level'],
        'rank': receiverData['rank'],
        'subRank': receiverData['subRank'],
        'xp': receiverData['xp'],
        'addedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  // Reject a friend request
  Future<void> rejectFriendRequest(String requestId) async {
    await _db.collection('friendRequests').doc(requestId).delete();
  }

  // Remove a friend
  Future<void> removeFriend(String uid, String friendUid) async {
    final batch = _db.batch();
    batch.delete(_db.collection('users').doc(uid).collection('friends').doc(friendUid));
    batch.delete(_db.collection('users').doc(friendUid).collection('friends').doc(uid));
    
    // Also clear any previous request docs to allow re-sending
    batch.delete(_db.collection('friendRequests').doc(_generateRequestId(uid, friendUid)));
    
    await batch.commit();
  }

  // Real-time listener for incoming friend requests
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchIncomingRequests(String uid) {
    return _db.collection('friendRequests')
        .where('receiverUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Real-time listener for outgoing requests (to show "Request Sent" state)
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> watchOutgoingRequests(String uid) {
    return _db.collection('friendRequests')
        .where('senderUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Real-time listener for friends list UIDs
  Stream<List<String>> watchFriendUids(String uid) {
    return _db.collection('users').doc(uid).collection('friends')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Real-time listener for friends list (Live from users collection)
  Stream<List<LeaderboardModel>> watchFriendsLive(List<String> uids) {
    if (uids.isEmpty) return Stream.value([]);
    
    // Firestore whereIn has a limit of 30. 
    return _db.collection('users')
        .where(FieldPath.documentId, whereIn: uids.take(30).toList())
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => LeaderboardModel.fromJson(doc.data())).toList());
  }

  String _generateRequestId(String uid1, String uid2) {
    final uids = [uid1, uid2]..sort();
    return uids.join('_');
  }
}
