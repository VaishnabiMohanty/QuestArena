import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../data/models/guild_model.dart';
import '../../../data/models/user_model.dart';
import '../../../providers/guild_providers.dart';
import '../../../providers/user_providers.dart';
import '../../widgets/smart_avatar.dart';
import '../../widgets/neon_swirl_background.dart';
import '../game_screen.dart';

class GuildMatchmakingScreen extends ConsumerStatefulWidget {
  const GuildMatchmakingScreen({super.key});

  @override
  ConsumerState<GuildMatchmakingScreen> createState() => _GuildMatchmakingScreenState();
}

class _GuildMatchmakingScreenState extends ConsumerState<GuildMatchmakingScreen> {
  Timer? _countdownTimer;
  Timer? _requirementTimer;
  int _secondsRemaining = 5;
  bool _requirementMet = false;
  int _requirementTimeLeft = 40;

  @override
  void initState() {
    super.initState();
    _startRequirementTimer();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _requirementTimer?.cancel();
    super.dispose();
  }

  void _startRequirementTimer() {
    _requirementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_requirementTimeLeft > 0) {
            _requirementTimeLeft--;
          }
        });
      }
    });
  }

  void _startCountdown(GuildBattleMatchModel match) {
    if (_countdownTimer != null) return;
    
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          final now = DateTime.now();
          final diff = match.startTime.difference(now).inSeconds;
          _secondsRemaining = diff > 0 ? diff : 0;
          if (_secondsRemaining <= 0) {
            timer.cancel();
            _enterMatch();
          }
        });
      }
    });
  }

  Future<void> _enterMatch() async {
    final match = ref.read(currentGuildBattleProvider).value;
    final user = ref.read(currentUserProvider).value;
    if (match == null || user == null) return;

    // Navigate to GameScreen (actual matchmaking pairs created game rooms)
    // Find my room
    final query = await ref.read(guildRepositoryProvider).findMyRoom(match.id, user.uid);
    if (query != null && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GameScreen(roomId: query)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final guildAsync = ref.watch(userGuildProvider);
    final matchAsync = ref.watch(currentGuildBattleProvider);
    final user = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: NeonSwirlBackground(
        colors: const [AppColors.neonPink, AppColors.neonViolet],
        child: SafeArea(
          child: guildAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error: $e')),
            data: (guild) {
              if (guild == null) return const Center(child: Text('No Guild Found'));
              
              final isLeader = user?.uid == guild.leaderUid;
              final isReady = guild.readyPlayerUids.contains(user?.uid);
              final readyCount = guild.readyPlayerUids.length;
              final canStart = readyCount >= 2;

              return Column(
                children: [
                  // Header
                  _buildHeader(guild),
                  
                  Expanded(
                    child: matchAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Center(child: Text('Error: $e')),
                      data: (match) {
                        if (match != null && match.status == GuildBattleStatus.matched) {
                          _startCountdown(match);
                          return _buildMatchFoundView(guild, match);
                        }
                        
                        return _buildLobbyView(guild, isLeader, isReady, canStart);
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(GuildModel guild) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              ),
              const Spacer(),
              Text('MATCHMAKING', style: AppTextStyles.display.copyWith(fontSize: 18, letterSpacing: 2)),
              const Spacer(),
              const SizedBox(width: 40),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'CATEGORY: ${guild.selectedCategoryName?.toUpperCase() ?? 'RANDOM'}',
            style: AppTextStyles.label.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildLobbyView(GuildModel guild, bool isLeader, bool isReady, bool canStart) {
    final membersAsync = ref.watch(guildMembersProvider(guild.memberUids));

    return Column(
      children: [
        Expanded(
          child: membersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, s) => Center(child: Text('Error loading members')),
            data: (members) {
              return GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  final memberReady = guild.readyPlayerUids.contains(member.uid);
                  
                  return _MemberReadyCard(
                    member: member,
                    isReady: memberReady,
                  );
                },
              );
            },
          ),
        ),
        
        // Footer Actions
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(color: AppColors.surface),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!canStart && _requirementTimeLeft <= 0)
                 Padding(
                   padding: const EdgeInsets.only(bottom: 12),
                   child: Text(
                    'Minimum 2 ready members required.',
                    style: AppTextStyles.label.copyWith(color: AppColors.red, fontWeight: FontWeight.bold),
                  ),
                 ),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final user = ref.read(currentUserProvider).value;
                        if (user != null) {
                          ref.read(guildRepositoryProvider).setPlayerReady(guild.id, user.uid, !isReady);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isReady ? AppColors.red.withValues(alpha: 0.2) : AppColors.teal.withValues(alpha: 0.2),
                        side: BorderSide(color: isReady ? AppColors.red : AppColors.teal),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isReady ? 'CANCEL READY' : 'I\'M READY!',
                        style: TextStyle(
                          color: isReady ? AppColors.red : AppColors.teal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (isLeader) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (canStart && guild.battleStatus != GuildBattleStatus.searching && _requirementTimeLeft > 0)
                          ? () => ref.read(guildRepositoryProvider).startMatchmaking(
                              guild.id, 
                              guild.selectedCategoryId ?? 'random',
                              guild.selectedCategoryName ?? 'Random',
                            )
                          : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonPink,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          guild.battleStatus == GuildBattleStatus.searching ? 'SEARCHING...' : 'START BATTLE',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (guild.battleStatus == GuildBattleStatus.searching)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton(
                    onPressed: () => ref.read(guildRepositoryProvider).cancelMatchmaking(guild.id),
                    child: const Text('CANCEL MATCHMAKING', style: TextStyle(color: AppColors.textMuted)),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMatchFoundView(GuildModel guild, GuildBattleMatchModel match) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('MATCH FOUND!', style: AppTextStyles.display.copyWith(color: AppColors.teal, fontSize: 32)).animate().shimmer(),
        const SizedBox(height: 48),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _GuildMatchFoundSide(
              name: match.guildAName, 
              iconId: match.guildAIcon, 
              players: match.guildAPlayers,
              isMe: guild.id == match.guildAId,
            ),
            Text('VS', style: AppTextStyles.headline.copyWith(color: AppColors.textMuted, fontSize: 24)),
            _GuildMatchFoundSide(
              name: match.guildBName, 
              iconId: match.guildBIcon, 
              players: match.guildBPlayers,
              isMe: guild.id == match.guildBId,
            ),
          ],
        ),
        const SizedBox(height: 64),
        Stack(
          alignment: Alignment.center,
          children: [
             Text(
              _secondsRemaining > 0 ? '$_secondsRemaining' : 'GO!',
              style: AppTextStyles.display.copyWith(fontSize: 80, color: Colors.white),
            ).animate(key: ValueKey(_secondsRemaining)).scale(duration: 300.ms, begin: const Offset(0.5, 0.5), end: const Offset(1, 1)).fadeIn(),
          ],
        ),
        const SizedBox(height: 16),
        Text('GET READY TO BATTLE!', style: AppTextStyles.label.copyWith(letterSpacing: 3, color: AppColors.gold)),
      ],
    );
  }
}

class _MemberReadyCard extends StatelessWidget {
  final UserModel member;
  final bool isReady;

  const _MemberReadyCard({required this.member, required this.isReady});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isReady ? AppColors.teal : Colors.transparent,
                  width: 3,
                ),
                boxShadow: isReady ? [
                  BoxShadow(color: AppColors.teal.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
                ] : null,
              ),
              child: SmartAvatar(avatarUrl: member.avatarUrl, size: 60),
            ),
            if (isReady)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 12, color: Colors.white),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          member.username,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.label.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
        ),
        Text(
          isReady ? 'READY' : 'WAITING',
          style: AppTextStyles.label.copyWith(
            fontSize: 8, 
            color: isReady ? AppColors.teal : AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _GuildMatchFoundSide extends ConsumerWidget {
  final String name;
  final String iconId;
  final List<String> players;
  final bool isMe;

  const _GuildMatchFoundSide({required this.name, required this.iconId, required this.players, required this.isMe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(guildMembersProvider(players));

    return Column(
      children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: AppColors.bgCard,
            shape: BoxShape.circle,
            border: Border.all(color: isMe ? AppColors.neonPink : AppColors.neonCyan, width: 2),
            boxShadow: [
              BoxShadow(color: (isMe ? AppColors.neonPink : AppColors.neonCyan).withValues(alpha: 0.3), blurRadius: 15),
            ],
          ),
          child: Icon(_getIconData(iconId), color: isMe ? AppColors.neonPink : AppColors.neonCyan, size: 40),
        ),
        const SizedBox(height: 12),
        Text(name, style: AppTextStyles.headline.copyWith(fontSize: 16, color: Colors.white)),
        const SizedBox(height: 8),
        playersAsync.when(
          data: (list) => Column(
            children: list.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                p.username.toUpperCase(),
                style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
            )).toList(),
          ),
          loading: () => const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          error: (_, __) => Text('${players.length} PLAYERS', style: AppTextStyles.label.copyWith(fontSize: 9)),
        ),
      ],
    );
  }

  IconData _getIconData(String id) {
    switch (id) {
      case '1': return Icons.auto_awesome_rounded;
      case '2': return Icons.military_tech_rounded;
      case '3': return Icons.shield_rounded;
      case '4': return Icons.bolt_rounded;
      case '5': return Icons.workspace_premium_rounded;
      case '6': return Icons.pets_rounded;
      default: return Icons.groups_rounded;
    }
  }
}
