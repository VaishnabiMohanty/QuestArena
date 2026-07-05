import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/game_providers.dart';
import '../../../data/models/game_room_model.dart';
import '../../../data/models/user_model.dart';
import '../widgets/victory_card.dart';
import '../widgets/smart_avatar.dart';
import '../widgets/neon_swirl_background.dart';
import '../../../providers/navigation_providers.dart';
import '../../../providers/achievement_providers.dart';
import '../../../providers/guild_providers.dart';

class ResultScreen extends ConsumerStatefulWidget {
  final GameRoomModel room;
  const ResultScreen({super.key, required this.room});

  @override
  ConsumerState<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends ConsumerState<ResultScreen> {
  late ConfettiController _confettiController;
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _rewardsClaimed = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserProvider).value;
      if (user != null && widget.room.winnerId == user.uid) {
        _confettiController.play();
      }
      _handleRewards();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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

      final opData = currentUser.uid == widget.room.player1['uid']
          ? widget.room.player2
          : widget.room.player1;

      final myScore = myData?['score'] ?? 0;
      final opponentScore = opData?['score'] ?? 0;
      final rankProtectionActive = myData?['rankProtectionActive'] ?? false;

      // Guild Battle Score Update
      if (widget.room.guildBattleId != null) {
        ref.read(guildRepositoryProvider).updatePlayerScore(widget.room.guildBattleId!, currentUser.uid, myScore);
      }
      
      await ref.read(userRepositoryProvider).processMatchEnd(
        uid: currentUser.uid,
        isWin: isWinner,
        isDraw: isDraw,
        playerScore: myScore,
        opponentScore: opponentScore,
        opponentId: opData?['uid'] ?? 'unknown',
        opponentName: opData?['username'] ?? 'Opponent',
        opponentAvatar: opData?['avatarUrl'],
        isRanked: widget.room.isRanked,
        rankProtectionActive: rankProtectionActive,
        opponentElo: opData?['eloRating'],
        isArenaBreaker: widget.room.isArenaBreaker,
      );

      await ref.read(gameRepositoryProvider).claimRewards(
        widget.room.roomId,
        currentUser.uid,
        isWinner,
      );

      // Update Achievements
      await ref.read(achievementServiceProvider).processMatchEnd(
        uid: currentUser.uid,
        isWin: isWinner,
        correctAnswers: myScore ~/ 10,
        totalQuestions: widget.room.questions.length,
      );

      if (mounted) setState(() => _rewardsClaimed = true);
    } catch (e) {
      debugPrint('Reward Error: $e');
    }
  }

  Future<void> _captureAndShare() async {
    try {
      final user = ref.read(currentUserProvider).value;
      if (user == null) return;

      final isP1 = user.uid == widget.room.player1['uid'];
      final opData = isP1 ? widget.room.player2 : widget.room.player1;
      
      final myScore = (isP1 
          ? widget.room.player1['score'] 
          : (widget.room.player2 != null ? widget.room.player2!['score'] : 0)) ?? 0;
          
      final opScore = (isP1 
          ? (widget.room.player2 != null ? widget.room.player2!['score'] : 0) 
          : widget.room.player1['score']) ?? 0;

      final image = await _screenshotController.captureFromWidget(
        Material(
          color: Colors.transparent,
          child: VictoryCard(
            username: user.username,
            avatarUrl: user.avatarUrl,
            rank: user.rank,
            opponentName: opData?['username'] ?? 'Opponent',
            playerScore: myScore,
            opponentScore: opScore,
            xpEarned: 50, // Approximate
            coinsEarned: 20,
            isMvp: widget.room.winnerId == user.uid,
          ),
        ),
        delay: const Duration(milliseconds: 100),
        pixelRatio: 3.0,
        context: context,
      );

      final directory = await getTemporaryDirectory();
      final imagePath = await File('${directory.path}/victory_card.png').create();
      await imagePath.writeAsBytes(image);

      const shareMessage = "I just played a battle on QuestArena!🏆\n\nThink you can beat me? 🧠\nChallenge me and prove it.\n\n🎮 Play now:\nhttps://quest-arena-self.vercel.app/";

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(imagePath.path)],
          text: shareMessage,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to share victory card: $e'), backgroundColor: AppColors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final isWinner = widget.room.winnerId == user.uid;
    final isDraw = widget.room.winnerId == 'draw';

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: NeonSwirlBackground(
        colors: isWinner ? const [AppColors.teal, AppColors.neonCyan] : const [AppColors.red, AppColors.neonViolet],
        child: Stack(
          children: [
            ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [AppColors.gold, AppColors.teal, AppColors.neonCyan],
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Text(
                      isWinner ? 'VICTORY' : (isDraw ? 'DRAW' : 'DEFEAT'),
                      style: AppTextStyles.display.copyWith(
                        fontSize: 48,
                        color: isWinner ? AppColors.teal : (isDraw ? AppColors.gold : AppColors.red),
                      ),
                    ).animate().fadeIn().scale(),
                    const SizedBox(height: 40),
                    _buildScoreBoard(user),
                    const SizedBox(height: 40),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreBoard(UserModel user) {
    final isP1 = user.uid == widget.room.player1['uid'];
    
    final myScore = (isP1 
        ? widget.room.player1['score'] 
        : (widget.room.player2 != null ? widget.room.player2!['score'] : 0)) ?? 0;
        
    final opScore = (isP1 
        ? (widget.room.player2 != null ? widget.room.player2!['score'] : 0) 
        : widget.room.player1['score']) ?? 0;

    final opData = isP1 ? widget.room.player2 : widget.room.player1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.cardBg.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.surface),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _ScoreItem(name: 'YOU', score: myScore, avatar: user.avatarUrl, color: AppColors.teal),
          Text('VS', style: AppTextStyles.label.copyWith(fontSize: 20, color: AppColors.textMuted)),
          _ScoreItem(name: opData?['username'] ?? 'OPPONENT', score: opScore, avatar: opData?['avatarUrl'], color: AppColors.red),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _captureAndShare,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.purple,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('SHARE RESULT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            ref.read(tabIndexProvider.notifier).state = 0;
            Navigator.of(context).popUntil((route) => route.isFirst);
          },
          child: Text('BACK TO HUB', style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 14)),
        ),
      ],
    );
  }
}

class _ScoreItem extends StatelessWidget {
  final String name;
  final int score;
  final String? avatar;
  final Color color;
  const _ScoreItem({required this.name, required this.score, this.avatar, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SmartAvatar(avatarUrl: avatar, size: 64, showBorder: true),
        const SizedBox(height: 12),
        Text(name, style: AppTextStyles.label.copyWith(fontSize: 10)),
        Text('$score', style: AppTextStyles.display.copyWith(fontSize: 32, color: color)),
      ],
    );
  }
}
