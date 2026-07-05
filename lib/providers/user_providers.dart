import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_providers.dart';
import '../data/services/firestore_service.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/friends_repository.dart';
import '../data/models/user_model.dart';
import '../data/models/match_history_model.dart';
import '../data/models/leaderboard_model.dart';
import '../core/errors/result.dart';

final dioProvider = Provider<Dio>((ref) => Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 5),
  receiveTimeout: const Duration(seconds: 5),
)));

final firestoreServiceProvider = Provider<FirestoreService>((ref) => FirestoreService());

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final service = ref.watch(firestoreServiceProvider);
  return UserRepository(service);
});

final friendsRepositoryProvider = Provider<FriendsRepository>((ref) => FriendsRepository());

final currentUserProvider = StreamProvider.autoDispose<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value(null);

  final repo = ref.watch(userRepositoryProvider);
  return repo.watchUserProfile(authState.uid);
});

final userProfileProvider = FutureProvider.family<UserModel?, String>((ref, uid) async {
  final repo = ref.watch(userRepositoryProvider);
  final result = await repo.getUserProfile(uid);
  return switch (result) {
    Success(data: final user) => user,
    Failure() => null,
  };
});

final matchHistoryProvider = StreamProvider.autoDispose<List<MatchModel>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value([]);
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchMatchHistory(authState.uid, limit: 50);
});

final userMatchHistoryProvider = FutureProvider.family<List<MatchModel>, String>((ref, uid) async {
  final repo = ref.watch(userRepositoryProvider);
  return repo.watchMatchHistory(uid).first;
});

final friendUidsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value([]);
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.watchFriendUids(authState.uid);
});

final friendsProvider = StreamProvider.autoDispose<List<LeaderboardModel>>((ref) {
  final uids = ref.watch(friendUidsProvider).value ?? [];
  if (uids.isEmpty) return Stream.value([]);
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.watchFriendsLive(uids);
});

final incomingRequestsProvider = StreamProvider.autoDispose<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value([]);
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.watchIncomingRequests(authState.uid);
});

final outgoingRequestsProvider = StreamProvider.autoDispose<List<QueryDocumentSnapshot<Map<String, dynamic>>>>((ref) {
  final authState = ref.watch(authStateProvider).value;
  if (authState == null) return Stream.value([]);
  final repo = ref.watch(friendsRepositoryProvider);
  return repo.watchOutgoingRequests(authState.uid);
});
