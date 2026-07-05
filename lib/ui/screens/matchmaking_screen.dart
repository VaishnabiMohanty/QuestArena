import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/matchmaking_providers.dart';
import '../../providers/user_providers.dart';
import '../widgets/smart_avatar.dart';
import 'lobby_screen.dart';

class MatchmakingScreen extends ConsumerStatefulWidget {
  final String? categoryName;
  const MatchmakingScreen({super.key, this.categoryName});

  @override
  ConsumerState<MatchmakingScreen> createState() => _MatchmakingScreenState();
}

class _MatchmakingScreenState extends ConsumerState<MatchmakingScreen> with TickerProviderStateMixin {
  Timer? _expansionTimer;
  Timer? _searchTimer;
  int _secondsElapsed = 0;
  bool _opponentFound = false;
  bool _isTimedOut = false;

  static const int _timeoutLimit = 25;

  @override
  void initState() {
    super.initState();
    _startSearchTimer();
    _startExpansionTimer();
  }

  @override
  void dispose() {
    _expansionTimer?.cancel();
    _searchTimer?.cancel();
    super.dispose();
  }

  void _startSearchTimer() {
    _searchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsElapsed++;
        if (_secondsElapsed >= _timeoutLimit && !_opponentFound) {
          _isTimedOut = true;
          _searchTimer?.cancel();
          _expansionTimer?.cancel();
        }
      });
    });
  }

  void _startExpansionTimer() {
    _expansionTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      final user = ref.read(currentUserProvider).value;
      if (user != null && !_opponentFound && !_isTimedOut) {
        ref.read(matchmakingRepositoryProvider).expandSearch(user.uid);
      }
    });
  }

  void _restartSearch() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null) return;

    setState(() {
      _isTimedOut = false;
      _secondsElapsed = 0;
      _opponentFound = false;
    });

    final ticket = ref.read(matchmakingTicketProvider).value;
    if (ticket != null) {
      await ref.read(matchmakingRepositoryProvider).startSearching(ticket);
    }

    _startSearchTimer();
    _startExpansionTimer();
  }

  String _getStatusMessage() {
    if (_opponentFound) return '✅ OPPONENT FOUND!';
    if (_secondsElapsed < 5) return '🔍 Searching players with similar skill...';
    if (_secondsElapsed < 10) return '🔄 Expanding search range...';
    if (_secondsElapsed < 15) return '⚡ Looking for the best available opponent...';
    if (_secondsElapsed < 20) return '🌐 Searching all available players...';
    return '⌛ Almost there, hold on...';
  }

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
    return '🎲';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final ticket = ref.watch(matchmakingTicketProvider).value;
    final displayCategory = ticket?.categoryName ?? widget.categoryName ?? 'Mixed / Random';

    ref.listen(matchmakingTicketProvider, (previous, next) {
      final ticket = next.value;
      if (ticket != null && ticket.status == 'matched' && ticket.gameRoomId != null) {
        if (_opponentFound) return;

        _searchTimer?.cancel();
        _expansionTimer?.cancel();

        setState(() {
          _opponentFound = true;
        });

        Future.delayed(const Duration(milliseconds: 1500), () {
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => LobbyScreen(roomId: ticket.gameRoomId!)),
            );
          }
        });
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: AppColors.bgDeep,
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [Color(0xFF1A1A2E), AppColors.bgDeep],
              ),
            ),
          ),

          if (!_isTimedOut)
            _buildSearchUI(user, displayCategory)
          else
            _buildTimeoutUI(),
        ],
      ),
    );
  }

  Widget _buildSearchUI(dynamic user, String displayCategory) {
    final userElo = user?.eloRating ?? 1200;
    final stage = (_secondsElapsed / 5).floor().clamp(0, 4);
    final range = 100 + (stage * 100);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (!_opponentFound)
                ...List.generate(4, (index) {
                  return Container(
                    width: 280,
                    height: 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.neonViolet.withValues(alpha: 0.1 * (4 - index)),
                        width: 1,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(
                    duration: 3.seconds,
                    begin: const Offset(0.2, 0.2),
                    end: const Offset(1.3, 1.3),
                    curve: Curves.easeOut,
                    delay: (index * 800).ms,
                  )
                  .fadeOut();
                }),

              if (!_opponentFound)
                RepaintBoundary(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.neonViolet.withValues(alpha: 0.4),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(duration: 4.seconds),
                ),

              SmartAvatar(
                avatarUrl: user?.avatarUrl,
                size: 110,
                showGlow: true,
                showBorder: true,
              ).animate(onPlay: (c) => c.repeat(reverse: true))
               .shimmer(delay: 2.seconds, duration: 2.seconds, color: AppColors.neonViolet.withValues(alpha: 0.3)),
            ],
          ),

          const SizedBox(height: 48),

          Text(
            _getStatusMessage().toUpperCase(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 2,
              fontWeight: FontWeight.w900,
              color: _opponentFound ? AppColors.teal : AppColors.textPrimary
            ),
          ).animate(key: ValueKey(_getStatusMessage()))
           .fadeIn(duration: 400.ms)
           .slideY(begin: 0.2, end: 0),

          const SizedBox(height: 16),

          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.neonAmber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.neonAmber.withValues(alpha: 0.3)),
                ),
                child: Text(
                  'RANK: ${user?.rank.toUpperCase() ?? 'BRONZE'}',
                  style: const TextStyle(color: AppColors.neonAmber, fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 11),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'ELO: ${user?.eloRating ?? 1200}',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          if (!_opponentFound) ...[
            Text(
              'CURRENT SEARCH RANGE',
              style: AppTextStyles.label.copyWith(fontSize: 10, letterSpacing: 1),
            ),
            const SizedBox(height: 8),
            Text(
              '${userElo - range} - ${userElo + range} ELO',
              style: AppTextStyles.headline.copyWith(
                fontSize: 18,
                color: AppColors.neonCyan,
                fontWeight: FontWeight.bold,
              ),
            ).animate(key: ValueKey(range)).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), curve: Curves.elasticOut),

            const SizedBox(height: 32),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: _secondsElapsed / _timeoutLimit,
                  backgroundColor: AppColors.surface,
                  color: AppColors.purple,
                  minHeight: 6,
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),

          if (displayCategory.isNotEmpty) ...[
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
                Text(_getCategoryIcon(displayCategory), style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  displayCategory.toUpperCase(),
                  style: AppTextStyles.label.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],

          if (!_opponentFound)
            Padding(
              padding: const EdgeInsets.only(top: 48),
              child: TextButton.icon(
                onPressed: () async {
                  if (user != null) {
                    await ref.read(matchmakingRepositoryProvider).cancelSearching(user.uid);
                    if (mounted) Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.close_rounded, color: AppColors.neonPink, size: 20),
                label: const Text(
                  'CANCEL SEARCH',
                  style: TextStyle(color: AppColors.neonPink, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                ),
              ).animate().fadeIn(delay: 500.ms),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeoutUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: AppColors.neonPink, size: 80)
                .animate()
                .shake(duration: 500.ms),
            const SizedBox(height: 24),
            Text(
              'NO OPPONENT FOUND',
              style: AppTextStyles.display.copyWith(fontSize: 22, color: AppColors.neonPink),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              "We couldn't find an opponent right now. Try expanding your search or try again later.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _restartSearch,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('RETRY SEARCH', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('BACK TO HOME', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    ).animate().fadeIn();
  }
}
