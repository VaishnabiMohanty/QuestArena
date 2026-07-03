// WHAT THIS FILE DOES:
// Optimized core quiz screen.
// Features: Heartbeat, Robust Reconnect, Independent Match Progression.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/game_providers.dart';
import '../../providers/user_providers.dart';
import '../../data/models/game_room_model.dart';
import '../../core/utils/game_utils.dart';
import '../widgets/smart_avatar.dart';
import '../widgets/neon_swirl_background.dart';
import '../widgets/lifeline_button.dart';
import 'result_screen.dart';

class GameScreen extends ConsumerStatefulWidget {
  final String roomId;
  const GameScreen({super.key, required this.roomId});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _timerController;
  String? _selectedAnswer;
  bool _hasAnswered = false;
  List<String> _shuffledOptions = [];
  List<String> _hiddenOptions = [];
  int _lastQuestionIndex = -1;
  String? _lastABQuestionText;
  int _lastABRound = 0;
  bool _isActivatingShield = false;
  bool _isRevealingTimeoutAnswer = false;
  int? _timeoutRevealQuestionIndex;
  bool _hasUsedOneOptionLifeline = false;
  bool _hasUsedTwoOptionLifeline = false;

  // Heartbeat & Timer state
  Timer? _heartbeatTimer;
  Timer? _syncTimer;
  Timer? _forfeitTimer;
  int _forfeitCountdown = 20;
  bool _isOpponentDisconnected = false;
  bool _showABIntro = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startHeartbeat();
    _updatePresence(true);

    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    // Sync timer every second
    _syncTimer = Timer.periodic(const Duration(seconds: 1), (_) => _syncState());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _syncTimer?.cancel();
    _forfeitTimer?.cancel();
    _updatePresence(false);
    _timerController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _updatePresence(state == AppLifecycleState.resumed);
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) => _updatePresence(true));
  }

  void _updatePresence(bool isOnline) {
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      ref.read(gameRepositoryProvider).updatePresence(widget.roomId, user.uid, isOnline);
    }
  }

  void _syncState() {
    final room = ref.read(gameRoomProvider(widget.roomId)).value;
    if (room == null || (room.status != 'active' && room.status != 'arena_breaker')) return;

    if (room.questionStartedAt != null) {
      final now = DateTime.now();
      final elapsedMs = now.difference(room.questionStartedAt!).inMilliseconds;
      final remainingMs = 15000 - elapsedMs;

      if (remainingMs <= 0) {
        if (!_hasAnswered && _timerController.isAnimating) {
          _timerController.stop();
          if (room.status == 'arena_breaker') {
            _handleABAnswerSelection("TIMEOUT");
          } else {
            _handleTimeout();
          }
        }
        if (room.status == 'active' && !_isRevealingTimeoutAnswer) {
          ref.read(gameRepositoryProvider).forceAdvanceQuestion(widget.roomId, room.currentQuestionIndex);
        }
      } else {
        final targetValue = remainingMs / 15000.0;
        if ((_timerController.value - targetValue).abs() > 0.05 || !_timerController.isAnimating) {
          if (!_hasAnswered) {
            _timerController.duration = Duration(milliseconds: remainingMs);
            _timerController.reverse(from: targetValue);
          }
        }
      }
    }
  }

  void _handleTimeout() async {
    if (_hasAnswered) return;

    final room = ref.read(gameRoomProvider(widget.roomId)).value;
    if (room == null) return;

    final timedOutIndex = room.currentQuestionIndex;

    setState(() {
      _selectedAnswer = "TIMEOUT";
      _hasAnswered = true;
      _isRevealingTimeoutAnswer = true;
      _timeoutRevealQuestionIndex = timedOutIndex;
    });

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final latestRoom = ref.read(gameRoomProvider(widget.roomId)).value;
    if (latestRoom == null ||
        latestRoom.status != 'active' ||
        latestRoom.currentQuestionIndex != timedOutIndex) {
      setState(() {
        _isRevealingTimeoutAnswer = false;
        _timeoutRevealQuestionIndex = null;
      });
      return;
    }

    await _submitAnswer("TIMEOUT");
    if (!mounted) return;

    await ref
        .read(gameRepositoryProvider)
        .forceAdvanceQuestion(widget.roomId, timedOutIndex);

    if (mounted) {
      setState(() {
        _isRevealingTimeoutAnswer = false;
        _timeoutRevealQuestionIndex = null;
      });
    }
  }

  void _onAnswerSelected(String answer) async {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
    });
    _timerController.stop();

    await _submitAnswer(answer);
  }

  Future<void> _submitAnswer(String answer) async {
    final room = ref.read(gameRoomProvider(widget.roomId)).value;
    final user = ref.read(currentUserProvider).value;
    if (room == null || user == null) return;

    final isP1 = user.uid == room.player1['uid'];
    final question = room.questions[room.currentQuestionIndex];
    final isCorrect = answer == question['correct_answer'];

    int score = 0;
    if (isCorrect) {
      final remainingRatio = _timerController.value;
      score = 10 + (remainingRatio * 5).toInt();
    }

    await ref.read(gameRepositoryProvider).submitAnswer(
      roomId: widget.roomId,
      userId: user.uid,
      playerNumber: isP1 ? 1 : 2,
      answer: answer,
      scoreIncrement: score,
    );
  }

  void _handleABAnswerSelection(String answer) async {
    if (_hasAnswered) return;
    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
    });
    _timerController.stop();

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    await ref.read(gameRepositoryProvider).submitArenaBreakerAnswer(
      roomId: widget.roomId,
      userId: user.uid,
      answer: answer,
    );
  }

  void _startForfeitTimer() {
    _forfeitTimer?.cancel();
    setState(() => _forfeitCountdown = 20);
    _forfeitTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_forfeitCountdown > 0) {
        if (mounted) setState(() => _forfeitCountdown--);
      } else {
        _forfeitTimer?.cancel();
        final user = ref.read(currentUserProvider).value;
        if (user != null) ref.read(gameRepositoryProvider).handleForfeit(widget.roomId, user.uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    if (user == null) return const Scaffold();

    ref.listen<AsyncValue<GameRoomModel?>>(gameRoomProvider(widget.roomId), (prev, next) {
      final room = next.value;
      if (room == null) return;

      if (room.status == 'finished') {
        _heartbeatTimer?.cancel();
        _syncTimer?.cancel();
        _forfeitTimer?.cancel();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => ResultScreen(room: room)),
        );
        return;
      }

      if (_lastQuestionIndex != room.currentQuestionIndex) {
        _lastQuestionIndex = room.currentQuestionIndex;
        _prepareOptions(room);
        setState(() {
          _hasAnswered = false;
          _selectedAnswer = null;
          _hiddenOptions = [];
          _isRevealingTimeoutAnswer = false;
          _timeoutRevealQuestionIndex = null;
          _hasUsedOneOptionLifeline = false;
          _hasUsedTwoOptionLifeline = false;
        });
        _syncState();
      }

      if (room.status == 'arena_breaker' && room.arenaBreakerQuestion != null) {
        if (_lastABRound != room.arenaBreakerRound) {
          final isFirstABQuestion = _lastABRound == 0;
          _lastABRound = room.arenaBreakerRound;
          _prepareABOptions(room.arenaBreakerQuestion!);
          setState(() {
            _hasAnswered = false;
            _selectedAnswer = null;
            if (isFirstABQuestion && room.questionStartedAt != null) {
              final elapsed = DateTime.now().difference(room.questionStartedAt!).inSeconds;
              if (elapsed > 2) _showABIntro = false;
            } else if (!isFirstABQuestion) {
              _showABIntro = false;
            }
          });
          _syncState();
        }
      }

      final String p1Uid = room.player1['uid'] ?? '';
      final String? p2Uid = room.player2?['uid'];
      final String? opponentId = user.uid == p1Uid ? p2Uid : p1Uid;

      if (opponentId != null && (room.status == 'active' || room.status == 'arena_breaker')) {
        final presence = room.presence[opponentId];
        final lastSeen = (presence?['lastSeen'] is int) 
            ? DateTime.fromMillisecondsSinceEpoch(presence?['lastSeen'])
            : (presence?['lastSeen'] as DateTime?);
        final isOnline = presence?['isOnline'] ?? true;

        bool disconnected = !isOnline || (lastSeen != null && DateTime.now().difference(lastSeen).inSeconds > 15);

        if (disconnected && !_isOpponentDisconnected) {
          setState(() => _isOpponentDisconnected = true);
          _startForfeitTimer();
        } else if (!disconnected && _isOpponentDisconnected) {
          setState(() => _isOpponentDisconnected = false);
          _forfeitTimer?.cancel();
        }
      }
    });

    final roomAsync = ref.watch(gameRoomProvider(widget.roomId));

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _showLeaveDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: _showLeaveDialog),
          title: _isOpponentDisconnected
              ? Text('OPPONENT DISCONNECTED', style: AppTextStyles.label.copyWith(color: AppColors.red, fontSize: 10))
              : null,
          centerTitle: true,
        ),
        body: roomAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.gold)),
          error: (e, s) => Center(child: Text('Error: $e')),
          data: (room) {
            if (room == null) return const Center(child: Text('Room Error'));
            return NeonSwirlBackground(
              colors: room.status == 'arena_breaker' 
                  ? const [AppColors.red, AppColors.neonViolet]
                  : const [AppColors.neonCyan, AppColors.neonViolet],
              child: Stack(
                children: [
                  _buildMainUI(room),
                  if (_isOpponentDisconnected) _buildDisconnectBanner(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainUI(GameRoomModel room) {
    if (room.status == 'arena_breaker') return _buildArenaBreakerRound(room);
    if (room.questions.isEmpty) return const Center(child: CircularProgressIndicator());

    final question = room.questions[room.currentQuestionIndex];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildHeader(room),
            const SizedBox(height: 24),
            _buildTimerBar(),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildPowerups(room),
                    const SizedBox(height: 24),
                    Text(GameUtils.decodeHtmlEntities(question['question']),
                            style: AppTextStyles.headline, textAlign: TextAlign.center)
                        .animate(key: ValueKey(room.currentQuestionIndex))
                        .fadeIn(),
                    const SizedBox(height: 32),
                    ..._shuffledOptions
                        .where((opt) => !_hiddenOptions.contains(opt))
                        .map((opt) => Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _AnswerButton(
                                text: GameUtils.decodeHtmlEntities(opt),
                                isSelected: _selectedAnswer == opt,
                                isCorrect: _hasAnswered && opt == question['correct_answer'],
                                isWrong: _hasAnswered && _selectedAnswer == opt && opt != question['correct_answer'],
                                onTap: () => _onAnswerSelected(opt),
                              ),
                            )),
                    const SizedBox(height: 16),
                    if (_isRevealingTimeoutAnswer &&
                        _timeoutRevealQuestionIndex == room.currentQuestionIndex)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Time up! Correct answer revealed.',
                          style: AppTextStyles.label.copyWith(color: AppColors.gold),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn().shake(hz: 2),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(GameRoomModel room) {
    final user = ref.read(currentUserProvider).value;
    final isP1 = user?.uid == room.player1['uid'];
    
    final myData = isP1 ? room.player1 : room.player2;
    final opData = isP1 ? room.player2 : room.player1;

    return Row(
      children: [
        _PlayerStat(
          name: myData?['username'] ?? 'Me', 
          avatarUrl: myData?['avatarUrl'],
          score: myData?['score'] ?? 0, 
          isLeft: true
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.bgDeep,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surface),
          ),
          child: Text('${room.currentQuestionIndex + 1}/10', style: AppTextStyles.label.copyWith(color: AppColors.gold)),
        ),
        const Spacer(),
        _PlayerStat(
          name: opData?['username'] ?? '...', 
          avatarUrl: opData?['avatarUrl'],
          score: opData?['score'] ?? 0, 
          isLeft: false
        ),
      ],
    );
  }

  Widget _buildTimerBar() {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _timerController,
        builder: (_, __) => LinearProgressIndicator(
          value: _timerController.value,
          backgroundColor: AppColors.surface,
          color: _timerController.value < 0.3 ? AppColors.red : AppColors.gold,
          minHeight: 10,
        ),
      ),
    );
  }

  Widget _buildPowerups(GameRoomModel room) {
    final user = ref.read(currentUserProvider).value;
    final uid = user?.uid;
    final shieldBlocks = Map<String, dynamic>.from(
      room.powerups['shieldBonusBlocks'] ?? {},
    );
    final shieldState = uid == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(shieldBlocks[uid] ?? {});
    final hasUsedShield = shieldState.isNotEmpty;
    final isShieldActiveThisQuestion =
        shieldState['questionIndex'] == room.currentQuestionIndex;
    final shieldUnlocked = _currentCorrectStreak(room) >= 2;
    final opponentAlreadyAnswered = _opponentHasAnsweredCurrentQuestion(room);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LifelineButton(
          label: 'Remove 1',
          icon: Icons.exposure_minus_1,
          count: user?.oneOptionLifelines ?? 0,
          isUsed: _hasUsedOneOptionLifeline,
          isDisabled: _hasAnswered,
          onTap: () => _useLifeline(room, 'oneOption'),
        ),
        const SizedBox(width: 12),
        LifelineButton(
          label: 'Remove 2',
          icon: Icons.exposure_minus_2,
          count: user?.twoOptionLifelines ?? 0,
          isUsed: _hasUsedTwoOptionLifeline,
          isDisabled: _hasAnswered,
          onTap: () => _useLifeline(room, 'twoOption'),
        ),
        const SizedBox(width: 12),
        _PowerupButton(
          label: isShieldActiveThisQuestion ? 'SHIELD ON' : 'SHIELD',
          icon: Icons.shield_rounded,
          isUsed: hasUsedShield,
          isDisabled: !shieldUnlocked ||
              _hasAnswered ||
              opponentAlreadyAnswered ||
              _isActivatingShield,
          onTap: () => _useShield(room),
        ),
      ],
    );
  }

  Widget _buildDisconnectBanner() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        color: AppColors.red.withValues(alpha: 0.95),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            const Text('Opponent disconnected.', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            Text('Ending in $_forfeitCountdown seconds...', style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ).animate().slideY(begin: -1, end: 0),
    );
  }

  void _showLeaveDialog() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('FORFEIT?', style: AppTextStyles.headline.copyWith(color: AppColors.red)),
        content: const Text('Leaving will grant your opponent an immediate win.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: AppColors.red), child: const Text('LEAVE')),
        ],
      ),
    );

    if (confirm == true) {
      final room = ref.read(gameRoomProvider(widget.roomId)).value;
      final user = ref.read(currentUserProvider).value;
      if (room != null && user != null) {
        final p1Uid = room.player1['uid'];
        final p2Uid = room.player2?['uid'];
        final String? opponentId = user.uid == p1Uid ? p2Uid : p1Uid;
        if (opponentId != null) {
          ref.read(gameRepositoryProvider).leaveMatch(widget.roomId, user.uid, opponentId);
        }
      }
    }
  }

  void _prepareOptions(GameRoomModel room) {
    if (room.currentQuestionIndex >= 0 && room.currentQuestionIndex < room.questions.length) {
      final question = room.questions[room.currentQuestionIndex];
      _shuffledOptions = List<String>.from(question['incorrect_answers'])..add(question['correct_answer'])..shuffle();
    }
  }

  void _prepareABOptions(Map<String, dynamic> question) {
    _shuffledOptions = List<String>.from(question['incorrect_answers'] ?? [])
      ..add(question['correct_answer'] ?? '')
      ..shuffle();
  }

  void _useLifeline(GameRoomModel room, String type) async {
    if (_hasAnswered) return;
    if (type == 'oneOption' && _hasUsedOneOptionLifeline) return;
    if (type == 'twoOption' && _hasUsedTwoOptionLifeline) return;

    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    final count = type == 'oneOption' ? user.oneOptionLifelines : user.twoOptionLifelines;
    if (count <= 0) return;

    try {
      await ref.read(gameRepositoryProvider).useLifeline(
            userId: user.uid,
            lifelineType: type,
          );

      final question = room.questions[room.currentQuestionIndex];
      final availableWrong = _shuffledOptions
          .where((o) => o != question['correct_answer'] && !_hiddenOptions.contains(o))
          .toList()
        ..shuffle();

      setState(() {
        if (type == 'oneOption') {
          _hasUsedOneOptionLifeline = true;
          if (availableWrong.isNotEmpty) {
            _hiddenOptions.add(availableWrong.first);
          }
        } else {
          _hasUsedTwoOptionLifeline = true;
          _hiddenOptions.addAll(availableWrong.take(2));
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error using lifeline: $e')),
        );
      }
    }
  }

  int _currentCorrectStreak(GameRoomModel room) {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return 0;

    final isP1 = user.uid == room.player1['uid'];
    final player = isP1 ? room.player1 : room.player2;
    final answers = List<String>.from(player?['answers'] ?? []);
    final maxIndex = answers.length < room.questions.length
        ? answers.length
        : room.questions.length;

    int streak = 0;
    for (int i = maxIndex - 1; i >= 0; i--) {
      final question = room.questions[i];
      if (answers[i] == question['correct_answer']) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  bool _opponentHasAnsweredCurrentQuestion(GameRoomModel room) {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return false;

    final isP1 = user.uid == room.player1['uid'];
    final opponent = isP1 ? room.player2 : room.player1;
    final answers = List<String>.from(opponent?['answers'] ?? []);
    return answers.length > room.currentQuestionIndex;
  }

  void _useShield(GameRoomModel room) async {
    final user = ref.read(currentUserProvider).value;
    if (user == null ||
        _hasAnswered ||
        _isActivatingShield ||
        _currentCorrectStreak(room) < 2 ||
        _opponentHasAnsweredCurrentQuestion(room)) {
      return;
    }

    setState(() => _isActivatingShield = true);
    await ref.read(gameRepositoryProvider).activateShieldBonusBlock(
          roomId: widget.roomId,
          userId: user.uid,
          questionIndex: room.currentQuestionIndex,
        );

    if (!mounted) return;
    setState(() => _isActivatingShield = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Shield activated! Opponent bonus points blocked.'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildArenaBreakerRound(GameRoomModel room) {
    if (_showABIntro) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('⚔ ARENA BREAKER ⚔', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.red)).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
            const SizedBox(height: 12),
            Text('Scores Tied', style: AppTextStyles.headline),
            const SizedBox(height: 8),
            Text('Next correct answer wins.', style: AppTextStyles.label),
            const SizedBox(height: 48),
            _ABCountdown(onFinished: () => setState(() => _showABIntro = false)),
          ],
        ),
      );
    }

    if (room.arenaBreakerStatusMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.sync_problem_rounded, color: AppColors.red, size: 64).animate(onPlay: (c) => c.repeat()).rotate(duration: 2.seconds),
            const SizedBox(height: 24),
            Text(room.arenaBreakerStatusMessage!, style: AppTextStyles.headline, textAlign: TextAlign.center),
          ],
        ),
      );
    }

    final question = room.arenaBreakerQuestion;
    if (question == null) return const Center(child: CircularProgressIndicator());

    final qTextRaw = question['question']?.toString();
    if (_lastABQuestionText != qTextRaw) {
      _prepareABOptions(question);
      _lastABQuestionText = qTextRaw;
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text('⚔ SUDDEN DEATH ⚔', style: AppTextStyles.label.copyWith(color: AppColors.red)),
            const SizedBox(height: 24),
            _buildTimerBar(),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Text(GameUtils.decodeHtmlEntities(question['question']),
                            style: AppTextStyles.headline, textAlign: TextAlign.center)
                        .animate()
                        .fadeIn(),
                    const SizedBox(height: 32),
                    ..._shuffledOptions.map((opt) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _AnswerButton(
                            text: GameUtils.decodeHtmlEntities(opt),
                            isSelected: _selectedAnswer == opt,
                            onTap: () => _handleABAnswerSelection(opt),
                            isCorrect: false,
                            isWrong: false,
                          ),
                        )),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerStat extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final int score;
  final bool isLeft;
  
  const _PlayerStat({
    required this.name, 
    this.avatarUrl, 
    required this.score, 
    required this.isLeft
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: isLeft ? TextDirection.ltr : TextDirection.rtl,
      children: [
        SmartAvatar(
          avatarUrl: avatarUrl,
          size: 44,
          showBorder: true,
          showGlow: score > 50,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Text(name.toUpperCase(), style: AppTextStyles.label.copyWith(fontSize: 9, letterSpacing: 1)),
            Text('$score', style: AppTextStyles.headline.copyWith(color: AppColors.gold, fontSize: 18, letterSpacing: 0)),
          ],
        ),
      ],
    );
  }
}

class _PowerupButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isUsed;
  final bool isDisabled;
  final VoidCallback onTap;

  const _PowerupButton({required this.label, required this.icon, required this.isUsed, required this.isDisabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = isUsed || isDisabled;
    final buttonText = isUsed && label.endsWith('ON') ? label : (isUsed ? '$label USED' : label);
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        opacity: disabled ? 0.45 : 1,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: isUsed ? AppColors.surface : AppColors.purple, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(isUsed ? Icons.check_circle_rounded : icon, color: isUsed ? AppColors.textMuted : AppColors.purple, size: 18),
              const SizedBox(width: 8),
              Text(buttonText, style: AppTextStyles.label.copyWith(color: isUsed ? AppColors.textMuted : Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ABCountdown extends StatefulWidget {
  final VoidCallback onFinished;
  const _ABCountdown({required this.onFinished});

  @override
  State<_ABCountdown> createState() => _ABCountdownState();
}

class _ABCountdownState extends State<_ABCountdown> {
  int _count = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_count > 1) {
        if (mounted) setState(() => _count--);
      } else {
        _timer?.cancel();
        widget.onFinished();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text('$_count', style: AppTextStyles.display.copyWith(fontSize: 80, color: AppColors.gold))
        .animate(key: ValueKey(_count))
        .scale(duration: 400.ms)
        .fadeOut(delay: 600.ms);
  }
}

class _AnswerButton extends StatelessWidget {
  final String text;
  final bool isSelected;
  final bool isCorrect;
  final bool isWrong;
  final VoidCallback onTap;

  const _AnswerButton({required this.text, required this.isSelected, required this.isCorrect, required this.isWrong, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isCorrect 
              ? Colors.teal.withValues(alpha: 0.1) 
              : isWrong 
                  ? Colors.red.withValues(alpha: 0.1)
                  : AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isCorrect ? Colors.teal : (isWrong ? Colors.red : (isSelected ? AppColors.purple : AppColors.surface)), width: 2),
        ),
        child: Text(text, style: AppTextStyles.bodyMd.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
      ),
    );
  }
}
