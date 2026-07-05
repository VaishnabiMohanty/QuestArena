import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/constants/colors.dart';
import '../widgets/character_avatar.dart';

class DashboardScreen extends StatefulWidget {
  final String username;
  final CharacterData character;
  final String rank;
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
    _heroAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _xpAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _statsAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _historyAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _xpFill = Tween<double>(begin: 0, end: widget.currentXP / widget.maxXP)
        .animate(CurvedAnimation(parent: _xpAnim, curve: Curves.easeOutCubic));

    _heroAnim.forward();
    Future.delayed(const Duration(milliseconds: 300), () => _xpAnim.forward());
    Future.delayed(const Duration(milliseconds: 500), () => _statsAnim.forward());
    Future.delayed(const Duration(milliseconds: 650), () => _historyAnim.forward());
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
      case 'gold': return AppColors.rankGold;
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
        title: const Text('DASHBOARD', style: TextStyle(color: AppColors.textPrimary, fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: 3)),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onStoreTap();
            },
            icon: const Icon(Icons.storefront_rounded, color: AppColors.neonAmber),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FadeTransition(opacity: _heroAnim, child: _ProfileHeroCard(username: widget.username, character: widget.character, rank: widget.rank, rankColor: _rankColor, level: widget.level, currentXP: widget.currentXP, maxXP: widget.maxXP, xpFill: _xpFill)),
            const SizedBox(height: 24),
            FadeTransition(opacity: _statsAnim, child: _StatsSection(wins: widget.wins, losses: widget.losses)),
            const SizedBox(height: 24),
            FadeTransition(opacity: _historyAnim, child: _HistorySection(history: widget.recentHistory)),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final String username;
  final CharacterData character;
  final String rank;
  final Color rankColor;
  final int level;
  final int currentXP;
  final int maxXP;
  final Animation<double> xpFill;

  const _ProfileHeroCard({required this.username, required this.character, required this.rank, required this.rankColor, required this.level, required this.currentXP, required this.maxXP, required this.xpFill});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(16), border: Border.all(color: rankColor.withValues(alpha: 0.35))),
      child: Row(
        children: [
          CharacterAvatar(character: character, size: 72, showGlow: true, showBorder: true),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                Text(rank, style: TextStyle(color: rankColor, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: xpFill,
                  builder: (context, _) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(value: xpFill.value, backgroundColor: AppColors.bgInputField, color: rankColor, minHeight: 6),
                      const SizedBox(height: 4),
                      Text('Level $level  –  $currentXP/$maxXP XP', style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
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

class _StatsSection extends StatelessWidget {
  final int wins;
  final int losses;
  const _StatsSection({required this.wins, required this.losses});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCard(label: 'WINS', value: '$wins', color: AppColors.neonCyan, icon: Icons.emoji_events_rounded)),
        const SizedBox(width: 12),
        Expanded(child: _StatCard(label: 'LOSSES', value: '$losses', color: AppColors.neonPink, icon: Icons.close_rounded)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _StatCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 10, letterSpacing: 1.5)),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final List<MatchHistoryItem> history;
  const _HistorySection({required this.history});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('RECENT HISTORY', style: TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 2)),
        const SizedBox(height: 12),
        if (history.isEmpty)
          const Center(child: Text('No matches yet', style: TextStyle(color: AppColors.textMuted)))
        else
          ...history.map((m) => _MatchCard(item: m)),
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final MatchHistoryItem item;
  const _MatchCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.isWin ? AppColors.teal : AppColors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.bgCard, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.surface)),
      child: Row(
        children: [
          Container(width: 4, height: 40, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('vs ${item.opponentName}', style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)), Text(item.timeAgo, style: const TextStyle(color: AppColors.textMuted, fontSize: 11))])),
          Text('+${item.xpGained} XP', style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class MatchHistoryItem {
  final String opponentName;
  final bool isWin;
  final int xpGained;
  final String timeAgo;
  const MatchHistoryItem({required this.opponentName, required this.isWin, required this.xpGained, required this.timeAgo});
}
