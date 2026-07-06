import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../providers/user_providers.dart';
import '../../providers/shop_provider.dart';

import 'guild/guild_home_screen.dart';
import 'guild/guild_dialogs.dart';

// ─── Battle Hub Screen ────────────────────────────────────────────────────────
// Redesigned version of the battle_screen / battle hub
// Four mode cards: Ranked Match, Private Duel, Practice, Guilds
// Each card has a neon icon, animated on-press scale, staggered entrance

class BattleHubScreen extends ConsumerStatefulWidget {
  final VoidCallback onRankedTap;
  final VoidCallback onPrivateTap;
  final VoidCallback onPracticeTap;

  const BattleHubScreen({
    super.key,
    required this.onRankedTap,
    required this.onPrivateTap,
    required this.onPracticeTap,
  });

  @override
  ConsumerState<BattleHubScreen> createState() => _BattleHubScreenState();
}

class _BattleHubScreenState extends ConsumerState<BattleHubScreen>
    with TickerProviderStateMixin {
  late AnimationController _titleAnim;
  late List<AnimationController> _cardAnims;
  late List<Animation<double>> _cardFades;
  late List<Animation<Offset>> _cardSlides;

  static const _modes = [
    _BattleMode(
      title: 'RANKED MATCH',
      subtitle: 'Compete for XP and Rank',
      icon: Icons.bolt_rounded,
      color: AppColors.neonViolet,
      tag: 'COMPETITIVE',
    ),
    _BattleMode(
      title: 'PRIVATE DUEL',
      subtitle: 'Play against a friend',
      icon: Icons.vpn_key_rounded,
      color: AppColors.neonAmber,
      tag: 'INVITE ONLY',
    ),
    _BattleMode(
      title: 'PRACTICE',
      subtitle: 'Sharpen your skills',
      subSubtitle: 'No XP',
      icon: Icons.psychology_rounded,
      color: AppColors.neonCyan,
      tag: 'FREE PLAY',
    ),
    _BattleMode(
      title: 'GUILDS',
      subtitle: 'Team up and battle',
      icon: Icons.groups_rounded,
      color: AppColors.neonPink,
      tag: 'SOCIAL',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _titleAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    
    // ROOT CAUSE FIX: Use _modes.length dynamically
    _cardAnims = List.generate(_modes.length, (_) => AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500)));
        
    _cardFades = _cardAnims.map((c) =>
        CurvedAnimation(parent: c, curve: Curves.easeOut)).toList();
        
    _cardSlides = _cardAnims.map((c) =>
        Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeOutCubic))).toList();

    _runEntrance();
  }

  Future<void> _runEntrance() async {
    await Future.delayed(const Duration(milliseconds: 80));
    _titleAnim.forward();
    for (int i = 0; i < _cardAnims.length; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      _cardAnims[i].forward();
    }
  }

  Future<void> _confirmToggle(bool newValue) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgCard,
        title: Text(
          newValue ? 'ACTIVATE SHIELD?' : 'DEACTIVATE SHIELD?',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          newValue
              ? 'Use 1 rank protection match for the next match?'
              : 'Rank points will be deducted normally if you lose.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCEL', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: newValue ? AppColors.neonViolet : AppColors.red,
            ),
            child: Text(
              newValue ? 'ACTIVATE' : 'DEACTIVATE',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(shopControllerProvider.notifier).toggleRankProtection(newValue);
    }
  }

  @override
  void dispose() {
    _titleAnim.dispose();
    for (final c in _cardAnims) {
      c.dispose();
    }
    super.dispose();
  }

  VoidCallback _callbackFor(int i) {
    switch (i) {
      case 0: return widget.onRankedTap;
      case 1: return widget.onPrivateTap;
      case 2: return widget.onPracticeTap;
      default: return _handleGuildsTap;
    }
  }

  void _handleGuildsTap() {
    final user = ref.read(currentUserProvider).value;
    if (user?.guildId == null) {
      showGuildOptionsDialog(context, ref);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildHomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).value;
    final isProtectionActive = user?.rankProtectionActive ?? false;
    final hasShields = (user?.rankProtectionMatches ?? 0) > 0;

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title + Toggle ──────────────────────────────────────────
              FadeTransition(
                opacity: _titleAnim,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [AppColors.neonCyan, AppColors.neonViolet],
                            stops: [0.3, 1.0],
                          ).createShader(bounds),
                          child: const Text(
                            'BATTLE HUB',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Select your challenge',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    _RankProtectionToggle(
                      isActive: isProtectionActive,
                      onChanged: hasShields ? (val) => _confirmToggle(val) : (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('No rank protection shields available. Purchase one in the Shop!'),
                            backgroundColor: AppColors.neonPink,
                          ),
                        );
                      },
                      isEnabled: hasShields,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Mode cards ───────────────────────────────────────────────
              // ROOT CAUSE FIX: Replaced Column with ListView to allow scrolling and prevent clipping
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _modes.length,
                  itemBuilder: (context, i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: FadeTransition(
                        opacity: _cardFades[i],
                        child: SlideTransition(
                          position: _cardSlides[i],
                          child: _BattleModeCard(
                            mode: _modes[i],
                            onTap: _callbackFor(i),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Rank Protection Toggle ──────────────────────────────────────────────────

class _RankProtectionToggle extends StatelessWidget {
  final bool isActive;
  final ValueChanged<bool> onChanged;
  final bool isEnabled;

  const _RankProtectionToggle({
    required this.isActive,
    required this.onChanged,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(
          opacity: isEnabled ? 1.0 : 0.5,
          child: Switch.adaptive(
            value: isActive,
            onChanged: onChanged,
            activeTrackColor: AppColors.neonViolet,
            inactiveTrackColor: AppColors.neonViolet.withValues(alpha: 0.1),
          ),
        ),
        Text(
          'SHIELD: ${isActive ? 'ON' : 'OFF'}',
          style: TextStyle(
            color: isActive ? AppColors.neonViolet : AppColors.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ─── Battle Mode Card ─────────────────────────────────────────────────────────

class _BattleMode {
  final String title;
  final String subtitle;
  final String? subSubtitle;
  final IconData icon;
  final Color color;
  final String tag;

  const _BattleMode({
    required this.title,
    required this.subtitle,
    this.subSubtitle,
    required this.icon,
    required this.color,
    required this.tag,
  });
}

class _BattleModeCard extends StatefulWidget {
  final _BattleMode mode;
  final VoidCallback onTap;

  const _BattleModeCard({required this.mode, required this.onTap});

  @override
  State<_BattleModeCard> createState() => _BattleModeCardState();
}

class _BattleModeCardState extends State<_BattleModeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scale;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.mode.color;
    return GestureDetector(
      onTapDown: (_) {
        _pressCtrl.forward();
        setState(() => _isPressed = true);
        HapticFeedback.selectionClick();
      },
      onTapUp: (_) {
        _pressCtrl.reverse();
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () {
        _pressCtrl.reverse();
        setState(() => _isPressed = false);
      },
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isPressed ? c.withValues(alpha: 0.08) : AppColors.bgCard,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _isPressed ? c.withValues(alpha: 0.6) : c.withValues(alpha: 0.25),
              width: _isPressed ? 1.2 : 0.6,
            ),
            boxShadow: [
              BoxShadow(
                  color: c.withValues(alpha: _isPressed ? 0.25 : 0.10),
                  blurRadius: _isPressed ? 24 : 12,
                  spreadRadius: _isPressed ? 2 : 0),
            ],
          ),
          child: Row(
            children: [
              // Icon circle
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: c.withValues(alpha: 0.12),
                  border: Border.all(color: c.withValues(alpha: 0.5), width: 1),
                  boxShadow: [
                    BoxShadow(color: c.withValues(alpha: 0.3), blurRadius: 12),
                    BoxShadow(color: c.withValues(alpha: 0.1), blurRadius: 24),
                  ],
                ),
                child: Icon(widget.mode.icon, color: c, size: 26),
              ),
              const SizedBox(width: 18),

              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.mode.title,
                      style: TextStyle(
                        color: _isPressed ? c : AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.mode.subtitle,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (widget.mode.subSubtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '(${widget.mode.subSubtitle})',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Arrow + tag
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.withValues(alpha: 0.3), width: 0.5),
                    ),
                    child: Text(
                      widget.mode.tag,
                      style: TextStyle(
                        color: c,
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right_rounded,
                      color: c.withValues(alpha: 0.5), size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
