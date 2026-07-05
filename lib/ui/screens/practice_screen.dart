import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/game_providers.dart';
import '../../core/utils/game_utils.dart';

class PracticeScreen extends ConsumerStatefulWidget {
  const PracticeScreen({super.key});

  @override
  ConsumerState<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends ConsumerState<PracticeScreen> with SingleTickerProviderStateMixin {
  bool _hasStarted = false;
  bool _isLoading = false;
  List<Map<String, dynamic>> _questions = [];
  int _currentIndex = 0;
  int _score = 0;
  String? _selectedAnswer;
  bool _hasAnswered = false;
  List<String> _shuffledOptions = [];
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );
    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && _hasStarted && !_hasAnswered) {
        _handleAnswerSelection("TIMEOUT");
      }
    });
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  Future<void> _startPractice() async {
    setState(() => _isLoading = true);
    try {
      final questions = await ref.read(gameRepositoryProvider).fetchQuestions(10);
      if (mounted) {
        setState(() {
          _questions = questions;
          _hasStarted = true;
          _isLoading = false;
        });
        _nextQuestion();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load questions: $e')),
        );
      }
    }
  }

  void _nextQuestion() {
    if (_currentIndex >= _questions.length) {
      _showResults();
      return;
    }

    final question = _questions[_currentIndex];
    _shuffledOptions = List<String>.from(question['incorrect_answers'])
      ..add(question['correct_answer'])
      ..shuffle();

    setState(() {
      _selectedAnswer = null;
      _hasAnswered = false;
    });

    _timerController.reverse(from: 1.0);
  }

  void _handleAnswerSelection(String answer) {
    if (_hasAnswered) return;

    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
    });
    _timerController.stop();

    final isCorrect = answer == _questions[_currentIndex]['correct_answer'];
    if (isCorrect) {
      _score += 10 + (_timerController.value * 5).toInt();
    }

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentIndex++;
        });
        _nextQuestion();
      }
    });
  }

  void _showResults() {
    if (!mounted) return;
    
    _timerController.stop();
    setState(() => _hasStarted = false);

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
              // Practice Specific Badge
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
                'Keep it up! You\'re getting better.', 
                style: AppTextStyles.label.copyWith(color: Colors.white.withValues(alpha: 0.7)),
              ),
              
              const SizedBox(height: 40),
              
              // Score Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    Text(
                      'SCORE', 
                      style: AppTextStyles.label.copyWith(letterSpacing: 3, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$_score', 
                      style: AppTextStyles.display.copyWith(color: AppColors.teal, fontSize: 56),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Back to Battle Hub
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
                        setState(() {
                          _currentIndex = 0;
                          _score = 0;
                          _questions = [];
                        });
                        _startPractice();
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
    if (!_hasStarted || _questions.isEmpty || _currentIndex >= _questions.length) {
      return Scaffold(
        appBar: AppBar(
          title: Text('PRACTICE MODE', style: AppTextStyles.display.copyWith(fontSize: 18)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.psychology_rounded, size: 100, color: AppColors.teal)
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(duration: 2.seconds, curve: Curves.easeInOut),
                const SizedBox(height: 32),
                Text(
                  'Master your knowledge with no pressure. Practice matches do not affect your rank or XP.',
                  style: AppTextStyles.bodyMd.copyWith(color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _startPractice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text('START PRACTICE NOW', style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final question = _questions[_currentIndex];
    final qText = GameUtils.decodeHtmlEntities(question['question']);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMuted),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text('${_currentIndex + 1}/${_questions.length}', style: AppTextStyles.label),
                    Text('Score: $_score', style: AppTextStyles.label.copyWith(color: AppColors.gold)),
                  ],
                ),
                const SizedBox(height: 24),
                
                RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _timerController,
                    builder: (context, child) => LinearProgressIndicator(
                      value: _timerController.value,
                      backgroundColor: AppColors.surface,
                      color: _timerController.value < 0.3 ? AppColors.red : AppColors.gold,
                      minHeight: 10,
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                Text(
                  qText,
                  style: AppTextStyles.headline,
                  textAlign: TextAlign.center,
                ).animate(key: ValueKey(_currentIndex)).fadeIn().scale(),
                
                const SizedBox(height: 40),

                ..._shuffledOptions.map((option) {
                  final decodedOption = GameUtils.decodeHtmlEntities(option);
                  final isCorrect = option == question['correct_answer'];
                  final isSelected = _selectedAnswer == option;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: () => _handleAnswerSelection(option),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _hasAnswered
                              ? (isCorrect 
                                  ? AppColors.teal.withValues(alpha: 0.1) 
                                  : (isSelected ? AppColors.red.withValues(alpha: 0.1) : AppColors.cardBg))
                              : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _hasAnswered
                                ? (isCorrect 
                                    ? AppColors.teal 
                                    : (isSelected ? AppColors.red : AppColors.surface))
                                : (isSelected ? AppColors.purple : AppColors.surface), 
                            width: 2
                          ),
                        ),
                        child: Text(
                          decodedOption,
                          style: AppTextStyles.bodyMd.copyWith(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
