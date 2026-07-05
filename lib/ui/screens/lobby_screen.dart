import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../providers/game_providers.dart';
import '../../providers/user_providers.dart';
import '../../core/constants/text_styles.dart';
import '../widgets/smart_avatar.dart';
import 'game_screen.dart';

class LobbyScreen extends ConsumerStatefulWidget {
  final String roomId;
  const LobbyScreen({super.key, required this.roomId});

  @override
  ConsumerState<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends ConsumerState<LobbyScreen> {
  int _countdown = 3;
  Timer? _timer;
  bool _isStartingGame = false;

  String _getCategoryIcon(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('computers')) return '💻';
    if (lowerCategory.contains('music')) return '🎵';
    if (lowerCategory.contains('film')) return '🎬';
    if (lowerCategory.contains('books')) return '📚';
    if (lowerCategory.contains('geography')) return '🌍';
    if (lowerCategory.contains('sports')) return '⚽';
    if (lowerCategory.contains('mathematics')) return '🧮';
    if (lowerCategory.contains('animals')) return '🐾';
    if (lowerCategory.contains('video games')) return '🎮';
    if (lowerCategory.contains('general knowledge')) return '📖';
    if (lowerCategory.contains('mixed') || lowerCategory.contains('random')) return '🎲';
    return '🎯';
  }

  Future<void> _enterGame() async {
    if (_isStartingGame || !mounted) return;
    _isStartingGame = true;

    await ref.read(gameRepositoryProvider).startGame(widget.roomId);
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => GameScreen(roomId: widget.roomId)),
    );
  }

  void _startCountdown() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          _timer?.cancel();
          _enterGame();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(gameRoomProvider(widget.roomId));
    final currentUser = ref.watch(currentUserProvider).value;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: roomAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.neonCyan)),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (room) {
          if (room == null) return const Center(child: Text('Room not found'));

          final p1 = room.player1;
          final p2 = room.player2;
          
          if (p1['isReady'] == true && p2 != null && p2['isReady'] == true) {
            _startCountdown();
          }

          return Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: AppColors.neonViolet.withValues(alpha: 0.05),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SmartAvatar(
                            avatarUrl: p1['avatarUrl'],
                            rank: p1['rank'],
                            size: 120,
                            showGlow: true,
                            showBorder: true,
                          ),
                          const SizedBox(height: 16),
                          Text(p1['username'], style: AppTextStyles.headline.copyWith(color: AppColors.textPrimary)),
                          _ReadyBadge(isReady: p1['isReady'] ?? false, color: AppColors.neonViolet),
                        ],
                      ),
                    ),
                  ),
                  
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      color: AppColors.neonAmber.withValues(alpha: 0.05),
                      child: p2 == null 
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(color: AppColors.neonAmber, strokeWidth: 2),
                              const SizedBox(height: 24),
                              Text('WAITING FOR OPPONENT', style: AppTextStyles.label.copyWith(letterSpacing: 2)),
                              const SizedBox(height: 8),
                              Text('ROOM CODE:', style: AppTextStyles.label.copyWith(fontSize: 10, letterSpacing: 1)),
                              Text(room.roomCode, style: AppTextStyles.display.copyWith(color: AppColors.neonAmber, fontSize: 32, letterSpacing: 4)),
                              
                              if (room.roomCode.isNotEmpty) ...[
                                const SizedBox(height: 32),
                                Text(
                                  'MATCH TOPIC',
                                  style: AppTextStyles.label.copyWith(
                                    fontSize: 9,
                                    color: AppColors.textSecondary,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      room.categoryName == 'Loading' 
                                        ? '⏳' 
                                        : room.categoryName.isEmpty 
                                          ? '❓' 
                                          : _getCategoryIcon(room.categoryName),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      room.categoryName == 'Loading'
                                        ? 'LOADING...'
                                        : room.categoryName.isEmpty
                                          ? 'NOT SELECTED'
                                          : room.categoryName.toUpperCase(),
                                      style: AppTextStyles.label.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ReadyBadge(isReady: p2['isReady'] ?? false, color: AppColors.neonAmber),
                              const SizedBox(height: 16),
                              Text(p2['username'], style: AppTextStyles.headline.copyWith(color: AppColors.textPrimary)),
                              const SizedBox(height: 16),
                              SmartAvatar(
                                avatarUrl: p2['avatarUrl'],
                                rank: p2['rank'],
                                size: 120,
                                showGlow: true,
                                showBorder: true,
                              ),
                            ],
                          ),
                    ),
                  ),
                ],
              ),
              
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(color: AppColors.bgDeep, shape: BoxShape.circle),
                  child: Text('VS', style: AppTextStyles.display.copyWith(color: AppColors.neonAmber, fontSize: 24)),
                ).animate().scale(delay: 400.ms, curve: Curves.elasticOut),
              ),

              if (p1['isReady'] == true && p2 != null && p2['isReady'] == true)
                Container(
                  color: Colors.black87,
                  child: Center(
                    child: Text('$_countdown', style: AppTextStyles.display.copyWith(fontSize: 120, color: AppColors.neonCyan))
                        .animate(key: ValueKey(_countdown))
                        .scale(duration: 500.ms)
                        .fadeOut(delay: 500.ms),
                  ),
                ),

              if (p2 != null && !(p1['isReady'] == true && p2['isReady'] == true))
                Positioned(
                  bottom: 40,
                  left: 40,
                  right: 40,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (currentUser == null) return;
                        
                        final isP1 = currentUser.uid == p1['uid'];
                        final playerNum = isP1 ? 1 : 2;

                        // Rely solely on the toggle from Battle Hub
                        final bool activateProtection = currentUser.rankProtectionActive;
                        
                        await ref.read(gameRepositoryProvider).activateRankProtectionForMatch(
                          widget.roomId,
                          playerNum,
                          activateProtection,
                        );
                        
                        await ref.read(gameRepositoryProvider).setPlayerReady(
                          widget.roomId,
                          playerNum,
                          currentUser.uid,
                        );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.neonViolet,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('I AM READY!', style: AppTextStyles.bodyLg.copyWith(fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _ReadyBadge extends StatelessWidget {
  final bool isReady;
  final Color color;
  const _ReadyBadge({required this.isReady, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isReady ? color.withValues(alpha: 0.2) : AppColors.bgInputField,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isReady ? color : AppColors.divider),
      ),
      child: Text(
        isReady ? 'READY' : 'WAITING...',
        style: TextStyle(color: isReady ? color : AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }
}
