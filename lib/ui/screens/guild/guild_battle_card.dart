import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/guild_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/guild_providers.dart';
import '../../../providers/user_providers.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../game_screen.dart';
import '../../widgets/category_picker_sheet.dart';
import 'guild_matchmaking_screen.dart';
import 'guild_result_screen.dart';

class GuildBattleCard extends ConsumerStatefulWidget {
  final GuildModel guild;
  const GuildBattleCard({super.key, required this.guild});

  @override
  ConsumerState<GuildBattleCard> createState() => _GuildBattleCardState();
}

class _GuildBattleCardState extends ConsumerState<GuildBattleCard> {
  @override
  Widget build(BuildContext context) {
    final guildAsync = ref.watch(userGuildProvider);
    final user = ref.watch(currentUserProvider).value;

    return guildAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Battle Error: $e'),
      data: (guild) {
        if (guild == null) return const SizedBox.shrink();

        if (guild.battleStatus == GuildBattleStatus.completed) {
           return _buildCompletedView(guild, user);
        }

        switch (guild.battleStatus) {
          case GuildBattleStatus.idle:
            return _buildLobbyView(user);
          case GuildBattleStatus.readyCheck:
          case GuildBattleStatus.searching:
          case GuildBattleStatus.matchmaking:
          case GuildBattleStatus.matched:
            return _buildMatchmakingInProgressView();
          case GuildBattleStatus.live:
            return _buildLiveBattleView(guild);
          default:
            return _buildLobbyView(user);
        }
      },
    );
  }

  Widget _buildMatchmakingInProgressView() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(strokeWidth: 2, color: AppColors.neonCyan),
              const SizedBox(width: 16),
              Text('MATCHMAKING...', style: AppTextStyles.headline.copyWith(fontSize: 18, color: AppColors.neonCyan)),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildMatchmakingScreen())),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface, shape: const StadiumBorder()),
            child: const Text('VIEW STATUS', style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildLobbyView(UserModel? user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: AppColors.neonPink.withValues(alpha: 0.1), blurRadius: 20, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const FaIcon(
                FontAwesomeIcons.shield,
                color: AppColors.neonPink,
                size: 32,
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('GUILD BATTLE', style: AppTextStyles.headline.copyWith(color: Colors.white, fontSize: 18)),
                  const Text('Team up and crush your rivals!', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              final user = ref.read(currentUserProvider).value;
              if (user != null && user.uid == widget.guild.leaderUid) {
                final category = await CategoryPickerSheet.show(context);
                if (category != null) {
                  await ref.read(guildRepositoryProvider).updateSelectedCategory(
                    widget.guild.id, 
                    category.id.toString(), 
                    category.name,
                  );
                }
              }
              if (mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildMatchmakingScreen()));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.neonPink,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('⚔ GUILD BATTLE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveBattleView(GuildModel guild) {
    final matchAsync = ref.watch(currentGuildBattleProvider);
    final user = ref.read(currentUserProvider).value;

    return matchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
      data: (match) {
        if (match == null) return _buildLobbyView(user);
        
        final bool isGuildA = match.guildAId == guild.id;
        final String opponentName = isGuildA ? match.guildBName : match.guildAName;
        final int myScore = isGuildA ? match.guildAScore : match.guildBScore;
        final int oppScore = isGuildA ? match.guildBScore : match.guildAScore;
        final bool isParticipant = match.guildAPlayers.contains(user?.uid) || match.guildBPlayers.contains(user?.uid);

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.neonViolet),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(guild.name, style: AppTextStyles.label.copyWith(color: AppColors.neonPink)),
                      Text('$myScore', style: AppTextStyles.display.copyWith(fontSize: 32)),
                    ],
                  ),
                  const Text('VS', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                  Column(
                    children: [
                      Text(opponentName, style: AppTextStyles.label.copyWith(color: AppColors.neonCyan)),
                      Text('$oppScore', style: AppTextStyles.display.copyWith(fontSize: 32)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const LinearProgressIndicator(backgroundColor: AppColors.surface, valueColor: AlwaysStoppedAnimation(AppColors.neonViolet)),
              const SizedBox(height: 12),
              const Text('BATTLE IN PROGRESS', style: TextStyle(color: AppColors.neonViolet, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
              if (isParticipant && match.playerStatus[user?.uid] != 'finished') ...[
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => _enterGuildMatch(match, user!.uid),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonViolet, shape: const StadiumBorder(), padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12)),
                  child: const Text('JOIN YOUR MATCH', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        );
      }
    );
  }

  Future<void> _enterGuildMatch(GuildBattleMatchModel match, String uid) async {
     final roomId = await ref.read(guildRepositoryProvider).findMyRoom(match.id, uid);
     if (roomId != null && mounted) {
       Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(roomId: roomId)));
     }
  }

  Widget _buildCompletedView(GuildModel guild, UserModel? user) {
    final matchAsync = ref.watch(currentGuildBattleProvider);

    return matchAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
      data: (match) {
        if (match == null) return _buildLobbyView(user);

        final bool isGuildA = match.guildAId == guild.id;
        final int myScore = isGuildA ? match.guildAScore : match.guildBScore;
        final int oppScore = isGuildA ? match.guildBScore : match.guildAScore;
        final bool isWin = myScore > oppScore;
        final bool isDraw = myScore == oppScore;

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isWin ? AppColors.teal : (isDraw ? AppColors.gold : AppColors.red),
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Icon(
                isWin ? Icons.emoji_events_rounded : (isDraw ? Icons.handshake_rounded : Icons.sentiment_very_dissatisfied_rounded), 
                color: isWin ? AppColors.gold : (isDraw ? AppColors.gold : AppColors.red), 
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                isWin ? 'GUILD VICTORY!' : (isDraw ? 'GUILD DRAW!' : 'GUILD DEFEAT'), 
                style: AppTextStyles.headline.copyWith(color: isWin ? AppColors.gold : (isDraw ? AppColors.gold : AppColors.red), fontSize: 22),
              ),
              const SizedBox(height: 8),
              Text('$myScore - $oppScore', style: AppTextStyles.display.copyWith(fontSize: 24)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => GuildResultScreen(match: match, myGuildId: guild.id)));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.surface, shape: const StadiumBorder()),
                child: const Text('VIEW RESULTS', style: TextStyle(color: Colors.white, fontSize: 10)),
              ),
            ],
          ),
        );
      },
    );
  }
}
