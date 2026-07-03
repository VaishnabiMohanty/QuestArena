// WHAT THIS FILE DOES:
// Displays the final scores, the winner, and rewards (XP/Coins).

import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:confetti/confetti.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/user_providers.dart';
import '../../providers/game_providers.dart';
import '../../providers/leaderboard_providers.dart';
import '../../data/models/game_room_model.dart';
import '../../data/models/match_history_model.dart';
import '../../data/models/user_model.dart';
import '../../data/models/match_end_result.dart';
import '../../data/services/rank_service.dart';
import '../../core/utils/level_system.dart';
import '../widgets/victory_card.dart';
import '../widgets/xp_summary_card.dart';
import '../widgets/rank_badge.dart';
import '../widgets/rank_progress_bar.dart';
import '../widgets/smart_avatar.dart';
import 'home_screen.dart';
import 'game_screen.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final GameRoomModel room;
  final bool isPractice;
  const ResultScreen({super.key, required this.room, this.isPractice = false});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  bool _rewardsClaimed = false;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _rematchRequested = false;
  int _rematchTimer = 30;
  Timer? _timer;
  MatchEndResult? _matchResult;
  bool _leveledUp = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isPractice) {
      _handleRewards();
      _startRematchTimer();
    } else {
      _rewardsClaimed = true;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startRematchTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted && _rematchTimer > 0) {
        setState(() => _rematchTimer--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _handleRewards() async {
    if (_rewardsClaimed) return;

    try {
      final userValue = ref.read(currentUserProvider);
      final currentUser = userValue.value;
      
      if (currentUser == null) {
        debugPrint('Current user is null, retrying reward claim...');
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) _handleRewards();
        return;
      }

      final isWinner = widget.room.winnerId == currentUser.uid;
      final isDraw = widget.room.winnerId == 'draw';

      final myData = currentUser.uid == widget.room.player1['uid'] 
          ? widget.room.player1 
          : widget.room.player2;
      
      final myScore = myData?['score'] ?? 0;
      final rankProtectionActive = myData?['rankProtectionActive'] ?? false;
      
      final correctAnswers = myScore ~/ 10;
      const totalQuestions = 10;
      final oldLevel = currentUser.level;

      final result = await ref.read(userRepositoryProvider).processMatchEnd(
        uid: currentUser.uid,
        isWin: isWinner,
        isDraw: isDraw,
        correctAnswers: correctAnswers,
        totalQuestions: totalQuestions,
        coinsGained: isWinner ? 20 : (isDraw ? 10 : 5),
        isArenaBreakerWin: widget.room.isArenaBreakerWin,
        isRanked: widget.room.isRanked,
        rankProtectionActive: rankProtectionActive,
      );

      final opponentScore = currentUser.uid == widget.room.player1['uid'] 
          ? (widget.room.player2?['score'] ?? 0)
          : widget.room.player1['score'];

      final opponentName = currentUser.uid == widget.room.player1['uid']
          ? (widget.room.player2?['username'] ?? 'Opponent')
          : widget.room.player1['username'];
          
      final opponentAvatar = currentUser.uid == widget.room.player1['uid']
          ? (widget.room.player2?['avatarUrl'])
          : widget.room.player1['avatarUrl'];

      final history = MatchModel(
        id: widget.room.roomId,
        opponentName: opponentName,
        opponentAvatarUrl: opponentAvatar ?? 'f1',
        playerScore: myScore,
        opponentScore: opponentScore,
        xpEarned: result?.xpRewards.total ?? (isWinner ? 50 : (isDraw ? 25 : 15)),
        timestamp: DateTime.now(),
      );

      await Future.wait([
        ref.read(gameRepositoryProvider).claimRewards(
          widget.room.roomId,
          currentUser.uid,
          isWinner,
        ),
        ref.read(userRepositoryProvider).saveMatchHistory(currentUser.uid, history),
      ]).timeout(const Duration(seconds: 10));
      
      if (mounted) {
        setState(() {
          _matchResult = result;
          _rewardsClaimed = true;
          if (result != null) {
            _leveledUp = LevelSystem.getCurrentLevel(currentUser.xp + result.xpRewards.total) > oldLevel;
          }
        });
      }
    } catch (e) {
      debugPrint('Error claiming rewards: $e');
      if (mounted) {
        setState(() => _rewardsClaimed = true);
      }
    }
  }

  void _showVictoryCardPopUp(UserModel user, String opponentName, int myScore, int opponentScore, int xp, int coins, bool isMvp) {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (context) => _VictoryCardModal(
        user: user,
        opponentName: opponentName,
        myScore: myScore,
        opponentScore: opponentScore,
        xpEarned: xp,
        coinsEarned: coins,
        isMvp: isMvp,
        screenshotController: _screenshotController,
      ),
    );
  }

  void _onRematchPressed() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || _rematchRequested) return;

    setState(() => _rematchRequested = true);
    await ref.read(gameRepositoryProvider).requestRematch(widget.room.roomId, user.uid);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).value;
    if (currentUser == null) return const Scaffold();

    final weeklyMvp = ref.watch(weeklyMvpProvider);
    final isMvp = weeklyMvp?.uid == currentUser.uid;

    if (!widget.isPractice) {
      ref.listen<AsyncValue<GameRoomModel?>>(gameRoomProvider(widget.room.roomId), (prev, next) {
        final room = next.value;
        if (room == null) return;

        if (room.nextMatchId != null && mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => GameScreen(roomId: room.nextMatchId!)),
          );
        }

        if (room.rematchRequests.length == 2 && room.nextMatchId == null) {
          if (currentUser.uid == room.player1['uid']) {
            ref.read(gameRepositoryProvider).createRematchGame(
              oldRoomId: room.roomId,
              player1: room.player1,
              player2: room.player2!,
              categoryId: room.categoryId,
              categoryName: room.categoryName,
              isRanked: room.isRanked,
            );
          }
        }
      });
    }

    final roomState = !widget.isPractice 
        ? (ref.watch(gameRoomProvider(widget.room.roomId)).value ?? widget.room)
        : widget.room;

    final otherRequested = !widget.isPractice && roomState.rematchRequests.any((id) => id != currentUser.uid);
    final waitingForOpponent = !widget.isPractice && _rematchRequested && roomState.rematchRequests.length < 2;

    final isWinner = widget.room.winnerId == currentUser.uid;
    final isDraw = widget.room.winnerId == 'draw';
    
    final myScore = currentUser.uid == widget.room.player1['uid'] 
        ? widget.room.player1['score'] 
        : (widget.room.player2?['score'] ?? 0);
        
    final opponentScore = currentUser.uid == widget.room.player1['uid'] 
        ? (widget.room.player2?['score'] ?? 0)
        : widget.room.player1['score'];

    final opponentName = currentUser.uid == widget.room.player1['uid']
        ? (widget.room.player2?['username'] ?? 'Opponent')
        : widget.room.player1['username'];

    final opponentAvatar = currentUser.uid == widget.room.player1['uid']
        ? (widget.room.player2?['avatarUrl'])
        : widget.room.player1['avatarUrl'];

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  isWinner 
                      ? AppColors.teal.withValues(alpha: 0.15) 
                      : (isDraw ? AppColors.gold.withValues(alpha: 0.15) : AppColors.red.withValues(alpha: 0.15)),
                  AppColors.primaryBg,
                ],
                radius: 1.2,
              ),
            ),
          ),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_rounded, color: AppColors.gold, size: 18),
                      const SizedBox(width: 8),
                      Text('QUESTARENA', style: AppTextStyles.label.copyWith(color: AppColors.gold, letterSpacing: 2, fontSize: 10)),
                    ],
                  ).animate().fadeIn(),

                  const SizedBox(height: 16),

                  if (_leveledUp)
                    _buildStatusBanner('LEVEL UP!', AppColors.gold),
                  
                  if (_matchResult?.rankUpdate.promoted == true)
                    _buildStatusBanner('PROMOTED!', AppColors.teal),
                  
                  if (_matchResult?.rankUpdate.demoted == true)
                    _buildStatusBanner('DEMOTED', AppColors.red),

                  SizedBox(
                    height: 100,
                    child: isWinner 
                      ? const Icon(Icons.emoji_events_rounded, size: 80, color: AppColors.gold)
                      : (isDraw ? const Icon(Icons.handshake_rounded, size: 80, color: AppColors.gold) : const Icon(Icons.sentiment_very_dissatisfied_rounded, size: 80, color: AppColors.red)),
                  ).animate().scale(duration: 800.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 24),

                  Text(
                    widget.isPractice 
                        ? 'PRACTICE COMPLETE' 
                        : (isDraw ? "IT'S A DRAW!" : (widget.room.forfeitWinnerId != null ? 'MATCH FORFEITED' : (widget.room.isArenaBreakerWin ? 'WINNER BY ARENA BREAKER ⚡' : (isWinner ? 'VICTORY!' : 'DEFEAT')))),
                    style: AppTextStyles.display.copyWith(
                      fontSize: (widget.room.isArenaBreakerWin || widget.room.forfeitWinnerId != null || widget.isPractice) ? 24 : 32,
                      color: isWinner ? AppColors.teal : (isDraw ? AppColors.gold : AppColors.red),
                    ),
                    textAlign: TextAlign.center,
                  ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                  const SizedBox(height: 8),

                  if (widget.isPractice || isDraw || !isWinner)
                    Text(
                      isWinner ? "Awesome battle!" : (isDraw ? "Well played!" : "Keep practicing!"),
                      style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary, fontSize: 14),
                    ).animate().fadeIn(delay: 400.ms),

                  const SizedBox(height: 32),

                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _PlayerSummary(
                          username: currentUser.username,
                          avatarUrl: currentUser.avatarUrl,
                          rank: currentUser.rank,
                          isWinner: isWinner,
                        ),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Text('$myScore', style: AppTextStyles.display.copyWith(color: AppColors.teal, fontSize: 26, letterSpacing: 0)),
                              const SizedBox(width: 8),
                              Text('-', style: AppTextStyles.display.copyWith(color: AppColors.textMuted, fontSize: 18, letterSpacing: 0)),
                              const SizedBox(width: 8),
                              Text('$opponentScore', style: AppTextStyles.display.copyWith(color: AppColors.red, fontSize: 26, letterSpacing: 0)),
                            ],
                          ),
                        ),

                        _PlayerSummary(
                          username: opponentName,
                          avatarUrl: opponentAvatar,
                          rank: 'Opponent',
                          isWinner: !isWinner && !isDraw,
                        ),
                      ],
                    ),
                  ).animate().slideY(begin: 0.2, end: 0).fadeIn(delay: 600.ms),

                  const SizedBox(height: 32),

                  _buildScoreCard(myScore, opponentScore),

                  const SizedBox(height: 32),

                  if (!widget.isPractice && _matchResult != null) ...[
                    XpSummaryCard(rewards: _matchResult!.xpRewards)
                        .animate()
                        .fadeIn(delay: 400.ms),
                    
                    const SizedBox(height: 24),
                    
                    _buildRankSection(_matchResult!.rankUpdate)
                        .animate()
                        .fadeIn(delay: 600.ms),
                  ] else if (widget.isPractice)
                    Text('No rewards earned in Practice Mode', style: AppTextStyles.label.copyWith(color: AppColors.textMuted))
                  else
                    const CircularProgressIndicator(color: AppColors.purple),

                  const SizedBox(height: 40),

                  if (widget.isPractice)
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.purple,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('CHANGE SETUP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          ),
                          child: Text('BACK TO HUB', style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
                        ),
                      ],
                    )
                  else ...[
                    if (_rematchTimer > 0 && roomState.nextMatchId == null) ...[
                      if (waitingForOpponent)
                        Column(
                          children: [
                            const CircularProgressIndicator(color: AppColors.gold),
                            const SizedBox(height: 12),
                            Text('Waiting for opponent...', style: AppTextStyles.label),
                          ],
                        )
                      else
                        ElevatedButton.icon(
                          onPressed: _onRematchPressed,
                          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                          label: Text(otherRequested ? 'ACCEPT REMATCH' : 'REQUEST REMATCH', style: const TextStyle(color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: otherRequested ? AppColors.teal : AppColors.surface,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                        ).animate(target: otherRequested ? 1 : 0).shimmer(),
                      
                      const SizedBox(height: 12),
                      Text('Offer expires in $_rematchTimer s', style: AppTextStyles.label.copyWith(fontSize: 10)),
                    ],

                    const SizedBox(height: 16),

                    if (isWinner)
                      ElevatedButton(
                        onPressed: () => _showVictoryCardPopUp(
                          currentUser, 
                          opponentName, 
                          myScore, 
                          opponentScore,
                          _matchResult?.xpRewards.total ?? 50,
                          20,
                          isMvp,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purple,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share_rounded, size: 18),
                            SizedBox(width: 12),
                            Text('SHARE YOUR VICTORY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ).animate().fadeIn(delay: 1000.ms).scale(),

                    const SizedBox(height: 12),

                    ElevatedButton(
                      onPressed: !_rewardsClaimed ? null : () => Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const HomeScreen()),
                        (route) => false,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cardBg,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: AppColors.surface)),
                      ),
                      child: const Text('BACK TO HOME', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
      ).animate().shimmer().scale(duration: 500.ms),
    );
  }

  Widget _buildScoreCard(int myScore, int opponentScore) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        children: [
          _ResultRow(label: 'YOUR SCORE', value: '$myScore', color: AppColors.gold),
          const Divider(color: AppColors.surface, height: 24),
          _ResultRow(label: widget.isPractice ? 'AI BOT' : 'OPPONENT', value: '$opponentScore', color: AppColors.textSecondary),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildRankSection(RankUpdateResult rankUpdate) {
    final pointsDiff = rankUpdate.pointsGained;
    final pointsColor = pointsDiff >= 0 ? AppColors.teal : AppColors.red;
    final pointsText = pointsDiff >= 0 ? '+$pointsDiff RP' : '$pointsDiff RP';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surface),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('RANK PROGRESS', style: AppTextStyles.label),
              Text(pointsText, style: AppTextStyles.label.copyWith(color: pointsColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RankBadge(rank: rankUpdate.oldRank, subRank: rankUpdate.oldSubRank, size: 50),
              const SizedBox(width: 16),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.textMuted),
              const SizedBox(width: 16),
              RankBadge(rank: rankUpdate.newRank, subRank: rankUpdate.newSubRank, size: 60)
                  .animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 1000.ms),
            ],
          ),
          const SizedBox(height: 20),
          RankProgressBar(rank: rankUpdate.newRank, subRank: rankUpdate.newSubRank, points: rankUpdate.newPoints),
        ],
      ),
    );
  }
}

class _PlayerSummary extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final String rank;
  final bool isWinner;

  const _PlayerSummary({required this.username, this.avatarUrl, required this.rank, required this.isWinner});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SmartAvatar(
          avatarUrl: avatarUrl,
          size: 70,
          showGlow: isWinner,
          showBorder: true,
        ),
        const SizedBox(height: 12),
        Text(username, style: AppTextStyles.headline.copyWith(fontSize: 14)),
        Text(rank, style: AppTextStyles.label.copyWith(color: AppColors.gold, fontSize: 10)),
      ],
    );
  }
}

class _VictoryCardModal extends StatefulWidget {
  final UserModel user;
  final String opponentName;
  final int myScore;
  final int opponentScore;
  final int xpEarned;
  final int coinsEarned;
  final bool isMvp;
  final ScreenshotController screenshotController;

  const _VictoryCardModal({
    required this.user,
    required this.opponentName,
    required this.myScore,
    required this.opponentScore,
    required this.xpEarned,
    required this.coinsEarned,
    required this.isMvp,
    required this.screenshotController,
  });

  @override
  State<_VictoryCardModal> createState() => _VictoryCardModalState();
}

class _VictoryCardModalState extends State<_VictoryCardModal> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _captureAndShare() async {
    try {
      final image = await widget.screenshotController.captureFromWidget(
        Material(
          color: Colors.transparent,
          child: VictoryCard(
            username: widget.user.username,
            avatarUrl: widget.user.avatarUrl,
            rank: widget.user.rank,
            opponentName: widget.opponentName,
            playerScore: widget.myScore,
            opponentScore: widget.opponentScore,
            xpEarned: widget.xpEarned,
            coinsEarned: widget.coinsEarned,
            isMvp: widget.isMvp,
          ),
        ),
        delay: const Duration(milliseconds: 100),
        context: context,
      );

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/victory_card.png').create();
      await imagePath.writeAsBytes(image);

      const shareMessage = "I just won a battle on QuestArena!🏆\n\nThink you can beat me? 🧠\nChallenge me and prove it.\n\n🎮 Play now:\nhttps://quest-arena-self.vercel.app/";

      await Share.share(shareMessage);
    } catch (e) {
      debugPrint('Share Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: true,
            colors: const [AppColors.gold, AppColors.purple, AppColors.teal, Colors.white],
            numberOfParticles: 20,
            gravity: 0.1,
          ),
          
          SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.topRight,
                  children: [
                    Screenshot(
                      controller: widget.screenshotController,
                      child: VictoryCard(
                        username: widget.user.username,
                        avatarUrl: widget.user.avatarUrl,
                        rank: widget.user.rank,
                        opponentName: widget.opponentName,
                        playerScore: widget.myScore,
                        opponentScore: widget.opponentScore,
                        xpEarned: widget.xpEarned,
                        coinsEarned: widget.coinsEarned,
                        isMvp: widget.isMvp,
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).fadeIn(),

                    Positioned(
                      top: 10,
                      right: 10,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surface,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('CLOSE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _captureAndShare,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(0, 56),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.share_rounded, size: 20),
                            SizedBox(width: 8),
                            Text('SHARE', style: TextStyle(fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.5, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _ResultRow({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.label),
        Text(value, style: AppTextStyles.display.copyWith(fontSize: 24, color: color)),
      ],
    );
  }
}
