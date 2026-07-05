import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../core/utils/game_utils.dart';
import '../../../data/models/game_room_model.dart';
import '../../../providers/user_providers.dart';
import '../models/practice_models.dart';
import '../providers/practice_controller.dart';

class PracticeGameScreen extends ConsumerStatefulWidget {
  final PracticeSession session;
  const PracticeGameScreen({super.key, required this.session});

  @override
  ConsumerState<PracticeGameScreen> createState() => _PracticeGameScreenState();
}

class _PracticeGameScreenState extends ConsumerState<PracticeGameScreen> with SingleTickerProviderStateMixin {
  late AnimationController _timerController;
  String? _selectedAnswer;
  bool _hasAnswered = false;
  List<String> _shuffledOptions = [];
  int _lastQuestionIndex = -1;
  String? _lastABQuestionText;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && !_hasAnswered) {
        ref.read(practiceControllerProvider(widget.session).notifier).forceAdvance();
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  void _syncTimer(GameRoomModel room) {
    if (room.questionStartedAt == null) return;

    final now = DateTime.now();
    final elapsedMs = now.difference(room.questionStartedAt!).inMilliseconds;
    final remainingMs = 15000 - elapsedMs;

    if (remainingMs <= 0) {
      if (!_hasAnswered && _timerController.isAnimating) {
        _timerController.stop();
      }
      return;
    }

    final targetValue = remainingMs / 15000.0;
    if ((_timerController.value - targetValue).abs() > 0.05 || !_timerController.isAnimating) {
      if (!_hasAnswered) {
        _timerController.duration = Duration(milliseconds: remainingMs);
        _timerController.reverse(from: targetValue);
      }
    }
  }

  void _prepareOptions(GameRoomModel room) {
    if (_lastQuestionIndex != room.currentQuestionIndex) {
      final question = room.questions[room.currentQuestionIndex];
      _shuffledOptions = List<String>.from(question['incorrect_answers'])
        ..add(question['correct_answer'])
        ..shuffle();
      _lastQuestionIndex = room.currentQuestionIndex;
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _hasAnswered = false;
            _selectedAnswer = null;
          });
          _timerController.reverse(from: 1.0);
        }
      });
    }
  }

  void _onAnswerSelected(String answer, GameRoomModel room) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
    });
    _timerController.stop();

    final user = ref.read(currentUserProvider).value;
    final question = room.questions[room.currentQuestionIndex];
    final isCorrect = answer == question['correct_answer'];

    int score = 0;
    if (isCorrect) {
      score = 10 + (_timerController.value * 5).toInt();
    }

    ref.read(practiceControllerProvider(widget.session).notifier)
       .submitAnswer(user?.uid ?? 'local_user', answer, score);
  }

  void _handleABAnswer(String answer, GameRoomModel room) {
    if (_hasAnswered) return;
    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
    });
    _timerController.stop();

    final user = ref.read(currentUserProvider).value;
    ref.read(practiceControllerProvider(widget.session).notifier)
       .submitArenaBreakerAnswer(user?.uid ?? 'local_user', answer);
  }

  bool _resultsShown = false;

  void _showResults(GameRoomModel room) {
    if (_resultsShown) return;
    _resultsShown = true;
    _timerController.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        backgroundColor: Colors.transparent,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.teal.withValues(alpha: 0.95),
                AppColors.primaryBg.withValues(alpha: 0.98),
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: AppColors.teal.withValues(alpha: 0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.teal.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'PRACTICE COMPLETE',
                style: AppTextStyles.headline.copyWith(fontSize: 22, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'You vs ${room.player2?['username'] ?? 'Bot'}',
                style: AppTextStyles.label.copyWith(color: Colors.white.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 32),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ScoreBadge(label: 'YOU', score: room.player1['score'], color: AppColors.teal),
                  Text('VS', style: AppTextStyles.label.copyWith(color: Colors.white.withValues(alpha: 0.3))),
                  _ScoreBadge(label: 'BOT', score: room.player2?['score'] ?? 0, color: AppColors.red),
                ],
              ),

              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Back to Setup
                      },
                      child: Text(
                        'BACK TO HUB',
                        style: AppTextStyles.label.copyWith(color: Colors.white.withValues(alpha: 0.7)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Restart practice
                        ref.invalidate(practiceControllerProvider(widget.session));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.teal,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text('REPLAY', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = ref.watch(practiceControllerProvider(widget.session));

    if (room == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.gold)));
    }

    // Show results dialog on finish
    if (room.status == 'finished') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResults(room);
      });
    }

    _prepareOptions(room);
    _syncTimer(room);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('PRACTICE: ${widget.session.difficulty.label}', style: AppTextStyles.label.copyWith(color: AppColors.gold)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: room.status == 'arena_breaker' 
              ? _buildArenaBreakerUI(room) 
              : _buildGameUI(room),
        ),
      ),
    );
  }

  Widget _buildGameUI(GameRoomModel room) {
    if (room.questions.isEmpty) return const Center(child: CircularProgressIndicator());
    
    final question = room.questions[room.currentQuestionIndex];
    final qText = GameUtils.decodeHtmlEntities(question['question']);

    return Column(
      children: [
        const SizedBox(height: 16),
        _buildScores(room),
        const SizedBox(height: 24),
        _buildTimerBar(),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Text(qText, style: AppTextStyles.headline, textAlign: TextAlign.center)
                    .animate(key: ValueKey(room.currentQuestionIndex))
                    .fadeIn(),
                const SizedBox(height: 32),
                ..._shuffledOptions.map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _AnswerButton(
                    text: GameUtils.decodeHtmlEntities(opt),
                    isSelected: _selectedAnswer == opt,
                    isCorrect: _hasAnswered && opt == question['correct_answer'],
                    isWrong: _hasAnswered && _selectedAnswer == opt && opt != question['correct_answer'],
                    onTap: () => _onAnswerSelected(opt, room),
                  ),
                )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildArenaBreakerUI(GameRoomModel room) {
    final question = room.arenaBreakerQuestion;
    if (question == null) return const Center(child: CircularProgressIndicator());

    // Refresh options if the AB question has changed
    final qTextRaw = question['question']?.toString();
    if (_lastABQuestionText != qTextRaw) {
      _shuffledOptions = List<String>.from(question['incorrect_answers'] ?? [])
        ..add(question['correct_answer'] ?? '')
        ..shuffle();
      _lastABQuestionText = qTextRaw;
    }
    
    final qText = GameUtils.decodeHtmlEntities(question['question']);

    return Column(
      children: [
        const SizedBox(height: 16),
        const Text('⚔ ARENA BREAKER ⚔', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.red)),
        const SizedBox(height: 24),
        _buildTimerBar(),
        const SizedBox(height: 24),
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                Text(qText, style: AppTextStyles.headline, textAlign: TextAlign.center).animate().fadeIn(),
                const SizedBox(height: 32),
                ..._shuffledOptions.map((opt) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _AnswerButton(
                    text: GameUtils.decodeHtmlEntities(opt),
                    isSelected: _selectedAnswer == opt,
                    onTap: () => _handleABAnswer(opt, room),
                    isCorrect: false, isWrong: false,
                  ),
                )),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScores(GameRoomModel room) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: _PlayerStat(name: room.player1['username'], score: room.player1['score'], isLeft: true),
        ),
        const SizedBox(width: 12),
        Text('${room.currentQuestionIndex + 1}/10', style: AppTextStyles.label),
        const SizedBox(width: 12),
        Expanded(
          child: _PlayerStat(
            name: room.player2?['username'] ?? '...',
            score: room.player2?['score'] ?? 0,
            isLeft: false,
            isBot: true,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerBar() {
    return AnimatedBuilder(
      animation: _timerController,
      builder: (_, __) => LinearProgressIndicator(
        value: _timerController.value,
        backgroundColor: AppColors.surface,
        color: _timerController.value < 0.3 ? AppColors.red : AppColors.gold,
        minHeight: 10,
      ),
    );
  }
}

class _PlayerStat extends StatelessWidget {
  final String name;
  final int score;
  final bool isLeft;
  final bool isBot;
  const _PlayerStat({required this.name, required this.score, required this.isLeft, this.isBot = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isLeft ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isLeft && isBot)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(4)),
                child: const Text('BOT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            Flexible(
              child: Text(
                name,
                style: AppTextStyles.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        Text('$score', style: AppTextStyles.headline.copyWith(color: AppColors.gold, fontSize: 20)),
      ],
    );
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
          color: isCorrect ? Colors.teal.withValues(alpha: 0.1) : (isWrong ? Colors.red.withValues(alpha: 0.1) : AppColors.cardBg),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isCorrect ? Colors.teal : (isWrong ? Colors.red : (isSelected ? AppColors.purple : AppColors.surface)), width: 2),
        ),
        child: Text(text, style: AppTextStyles.bodyMd.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), textAlign: TextAlign.center),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  final String label;
  final int score;
  final Color color;
  const _ScoreBadge({required this.label, required this.score, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Text(label, style: AppTextStyles.label.copyWith(fontSize: 10, color: Colors.white.withValues(alpha: 0.5))),
          const SizedBox(height: 4),
          Text('$score', style: AppTextStyles.display.copyWith(color: color, fontSize: 32)),
        ],
      ),
    );
  }
}

