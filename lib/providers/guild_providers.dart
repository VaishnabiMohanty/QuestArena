import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:questarena/data/repositories/guild_repository.dart';
import 'package:questarena/data/models/guild_model.dart';
import 'package:questarena/data/models/user_model.dart';
import 'package:questarena/core/errors/result.dart';
import 'user_providers.dart';

final guildRepositoryProvider = Provider((ref) {
  final dio = ref.watch(dioProvider);
  return GuildRepository(dio);
});

final userGuildProvider = StreamProvider.autoDispose<GuildModel?>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user?.guildId == null) return Stream.value(null);
  
  return ref.watch(guildRepositoryProvider).watchGuild(user!.guildId!);
});

final guildByIdProvider = StreamProvider.family.autoDispose<GuildModel?, String>((ref, id) {
  return ref.watch(guildRepositoryProvider).watchGuild(id);
});

final guildMembersProvider = FutureProvider.family<List<UserModel>, List<String>>((ref, uids) async {
  final userRepo = ref.watch(userRepositoryProvider);
  final members = <UserModel>[];
  for (final uid in uids) {
    final result = await userRepo.getUserProfile(uid);
    if (result is Success<UserModel>) {
      members.add(result.data);
    }
  }
  // Sort by XP
  members.sort((a, b) => b.xp.compareTo(a.xp));
  return members;
});

final currentGuildBattleProvider = StreamProvider.autoDispose<GuildBattleMatchModel?>((ref) {
  final guild = ref.watch(userGuildProvider).value;
  if (guild?.currentBattleId == null) return Stream.value(null);
  
  return ref.watch(guildRepositoryProvider).watchMatch(guild!.currentBattleId!);
});

final guildMvpProvider = FutureProvider.family<UserModel?, List<String>>((ref, uids) async {
  final members = await ref.watch(guildMembersProvider(uids).future);
  if (members.isEmpty) return null;
  
  // Sort by Weekly XP
  members.sort((a, b) => b.weeklyXp.compareTo(a.weeklyXp));
  return members.first;
});
