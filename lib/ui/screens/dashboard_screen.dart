import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../widgets/character_avatar.dart';

// ─── Dashboard Screen ─────────────────────────────────────────────────────
// Replaces the existing home_screen.dart visual layer.
// Preserves all data wiring — only UI & animation changed.

class DashboardScreen extends StatefulWidget {
  // Pass in data from your existing Riverpod providers:
  final String username;
  final CharacterData character;
  final String rank;          // e.g. "Bronze"
  final int level;
  final int currentXP;
  final int maxXP;
  final int wins;
  final int losses;
  final List<MatchHistoryItem> recentHistory;
  final VoidCallback onStoreTap;

  const DashboardScreen({
    super.key,
    required this.username,
    required this.character,
    required this.rank,
    required this.level,
    required this.currentXP,
    required this.maxXP,
    required this.wins,
    required this.losses,
    required this.recentHistory,
    required this.onStoreTap,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _heroAnim;
  late AnimationController _xpAnim;
  late AnimationController _statsAnim;
  late AnimationController _historyAnim;
  late Animation<double> _xpFill;

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _xpAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _statsAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _historyAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));

    _xpFill = Tween<double>(begin: 0, end: widget.currentXP / widget.maxXP)
        .animate(CurvedAnimation(parent: _xpAnim, curve: Curves.easeOutCubic));

    _runEntrance();
  }

  Future<void> _runEntrance() async {
    _heroAnim.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _xpAnim.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _statsAnim.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    _historyAnim.forward();
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    _xpAnim.dispose();
    _statsAnim.dispose();
    _historyAnim.dispose();
    super.dispose();
  }

  Color get _rankColor {
    switch (widget.rank.toLowerCase()) {
      case 'bronze': return AppColors.rankBronze;
      case 'silver': return AppColors.rankSilver;
      case 'gold':   return AppColors.rankGold;
      case 'platinum': return AppColors.rankPlatinum;
      default: return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: AppColors.bgBase,
        title: const Text(
          'DASHBOARD',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                widget.onStoreTap();
              },
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.neonAmber.withValues(alpha: 0.3), width: 0.5),
                  boxShadow: [BoxShadow(
                      color: AppColors.neonAmber.withValues(alpha: 0.15),
                      blurRadius: 8)],
                ),
                child: const Icon(Icons.storefront_rounded,
                    color: AppColors.neonAmber, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero card (profile) ─────────────────────────────────────────
            FadeTransition(
              opacity: _heroAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                    begin: const Offset(0, -0.15), end: Offset.zero)
                    .animate(CurvedAnimation(
                    parent: _heroAnim, curve: Curves.easeOutCubic)),
                child: _ProfileHeroCard(
                  username: widget.username,
                  character: widget.character,
                  rank: widget.rank,
                  rankColor: _rankColor,
                  level: widget.level,
                  currentXP: widget.currentXP,
                  maxXP: widget.maxXP,
                  xpFill: _xpFill,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Quick stats ────────────────────────────────────────────────
            FadeTransition(
              opacity: _statsAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                    begin: const Offset(0, 0.15), end: Offset.zero)
                    .animate(CurvedAnimation(
                    parent: _statsAnim, curve: Curves.easeOutCubic)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionHeader(label: 'QUICK STATS'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            value: widget.wins.toString(),
                            label: 'WINS',
                            color: AppColors.neonCyan,
                            icon: Icons.emoji_events_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            value: widget.losses.toString(),
                            label: 'LOSSES',
                            color: AppColors.neonPink,
                            icon: Icons.close_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── Recent history ─────────────────────────────────────────────
            FadeTransition(
              opacity: _historyAnim,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(label: 'RECENT HISTORY'),
                  const SizedBox(height: 10),
                  widget.recentHistory.isEmpty
                      ? const _EmptyHistory()
                      : Column(
                    children: widget.recentHistory
                        .map((m) => _MatchHistoryCard(match: m))
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Profile Hero Card ───────────────────────────────────────────────────────

class _ProfileHeroCard extends StatelessWidget {
  final String username;
  final CharacterData character;
  final String rank;
  final Color rankColor;
  final int level;
  final int currentXP;
  final int maxXP;
  final Animation<double> xpFill;

  const _ProfileHeroCard({
    required this.username,
    required this.character,
    required this.rank,
    required this.rankColor,
    required this.level,
    required this.currentXP,
    required this.maxXP,
    required this.xpFill,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: rankColor.withValues(alpha: 0.35), width: 0.8),
        boxShadow: [
          BoxShadow(
              color: rankColor.withValues(alpha: 0.10),
              blurRadius: 20,
              spreadRadius: 2),
          BoxShadow(
              color: AppColors.neonViolet.withValues(alpha: 0.05),
              blurRadius: 40),
        ],
      ),
      child: Row(
        children: [
          // Avatar with rank ring
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              CharacterAvatar(
                character: character,
                size: 72,
                showGlow: true,
                showBorder: true,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.bgDeep,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: rankColor.withValues(alpha: 0.6), width: 0.5),
                ),
                child: Text(
                  rank.isNotEmpty ? rank.toUpperCase()[0] : 'U', 
                  style: TextStyle(
                    color: rankColor,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Text(
                      'Rank: ',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    Text(
                      rank,
                      style: TextStyle(
                        color: rankColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // XP bar
                AnimatedBuilder(
                  animation: xpFill,
                  builder: (_, __) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          // Track
                          Container(
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.bgInputField,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          // Fill
                          FractionallySizedBox(
                            widthFactor: xpFill.value.clamp(0.0, 1.0),
                            child: Container(
                              height: 5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [
                                  rankColor,
                                  rankColor.withValues(alpha: 0.6),
                                ]),
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                      color: rankColor.withValues(alpha: 0.6),
                                      blurRadius: 6),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Level $level  –  $currentXP/$maxXP XP',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Stat Card ───────────────────────────────────────────────────────────────

class _StatCard extends StatefulWidget {
  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.value,
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: widget.color.withValues(alpha: 0.2), width: 0.5),
        boxShadow: [
          BoxShadow(
              color: widget.color.withValues(alpha: 0.08), blurRadius: 12),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Neon ring icon
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withValues(alpha: 0.1),
              border: Border.all(
                  color: widget.color.withValues(alpha: 0.5), width: 1.5),
              boxShadow: [BoxShadow(
                  color: widget.color.withValues(alpha: 0.3), blurRadius: 8)],
            ),
            child: Icon(widget.icon, color: widget.color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            widget.value,
            style: TextStyle(
              color: widget.color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            widget.label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Match History ────────────────────────────────────────────────────────────

class MatchHistoryItem {
  final String opponentName;
  final bool isWin;
  final int xpGained;
  final String timeAgo;
  const MatchHistoryItem({
    required this.opponentName,
    required this.isWin,
    required this.xpGained,
    required this.timeAgo,
  });
}

class _MatchHistoryCard extends StatelessWidget {
  final MatchHistoryItem match;
  const _MatchHistoryCard({required this.match});

  @override
  Widget build(BuildContext context) {
    final color = match.isWin ? AppColors.neonCyan : AppColors.neonPink;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
            ),
            child: Icon(
                match.isWin ? Icons.check_rounded : Icons.close_rounded,
                color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('vs ${match.opponentName}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(match.timeAgo,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                match.isWin ? 'WIN' : 'LOSS',
                style: TextStyle(
                    color: color, fontSize: 11,
                    fontWeight: FontWeight.w800, letterSpacing: 1.5),
              ),
              Text('+${match.xpGained} XP',
                  style: const TextStyle(
                      color: AppColors.neonAmber,
                      fontSize: 11, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 0.5),
      ),
      child: Column(
        children: [
          Icon(Icons.history_rounded,
              color: AppColors.textMuted.withValues(alpha: 0.4), size: 36),
          const SizedBox(height: 12),
          const Text('No match history yet.',
              style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          const Text('Start a battle to see your results!',
              style: TextStyle(
                  color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppColors.textMuted,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 2.5,
      ),
    );
  }
}
