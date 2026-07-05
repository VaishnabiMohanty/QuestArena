import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import 'smart_avatar.dart';

class VictoryCard extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final String rank;
  final String opponentName;
  final int playerScore;
  final int opponentScore;
  final int xpEarned;
  final int coinsEarned;
  final int winStreak;
  final bool isCompact;
  final bool isMvp;

  const VictoryCard({
    super.key,
    required this.username,
    this.avatarUrl,
    required this.rank,
    required this.opponentName,
    required this.playerScore,
    required this.opponentScore,
    required this.xpEarned,
    required this.coinsEarned,
    this.winStreak = 1,
    this.isCompact = false,
    this.isMvp = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCompact) return _buildCompactCard();
    final winMargin = (playerScore - opponentScore).abs();

    return Container(
      width: 320,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Confetti Particles
          ...List.generate(15, (index) {
            final double top = (index * 23) % 400.0;
            final double left = (index * 37) % 320.0;
            final colors = [AppColors.gold, AppColors.purple, AppColors.teal, Colors.white];
            final color = colors[index % colors.length].withValues(alpha: 0.3);
            
            return Positioned(
              top: top,
              left: left,
              child: Icon(
                index % 2 == 0 ? Icons.star_rounded : Icons.circle,
                size: 6 + (index % 10).toDouble(),
                color: color,
              ),
            );
          }),
          
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              // Header: Logo + VICTORY
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_rounded, color: AppColors.gold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'QUESTARENA',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.gold,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'VICTORY',
                style: AppTextStyles.display.copyWith(
                  fontSize: 32,
                  color: Colors.white,
                  letterSpacing: 4,
                ),
              ),
              
              const SizedBox(height: 12),

              // MVP Badge if applicable
              if (isMvp)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.gold, width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 14),
                      const SizedBox(width: 4),
                      Text('WEEKLY MVP', style: AppTextStyles.label.copyWith(color: AppColors.gold, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),

              // Avatar section with Ribbon
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Avatar Glow
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gold.withValues(alpha: 0.4),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                  ),
                  // Avatar
                  SmartAvatar(
                    avatarUrl: avatarUrl,
                    rank: rank,
                    size: 90,
                    showGlow: true,
                    showBorder: true,
                  ),
                  // Crown
                  const Positioned(
                    top: -15,
                    child: Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 30),
                  ),
                  // Name Ribbon
                  Positioned(
                    bottom: -15,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.purple,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        username.toUpperCase(),
                        style: AppTextStyles.headline.copyWith(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              
              // Rank Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars_rounded, color: AppColors.gold, size: 14),
                    const SizedBox(width: 4),
                    Text(rank.toUpperCase(), style: AppTextStyles.label.copyWith(color: AppColors.gold, fontSize: 10)),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              
              Text('VS', style: AppTextStyles.label.copyWith(color: AppColors.textMuted, fontSize: 10)),
              Text(opponentName, style: AppTextStyles.bodyMd.copyWith(color: AppColors.textSecondary)),
              
              const SizedBox(height: 12),
              
              // Score
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('$playerScore', style: AppTextStyles.display.copyWith(color: AppColors.teal, fontSize: 36)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('-', style: AppTextStyles.display.copyWith(color: AppColors.textMuted, fontSize: 36)),
                  ),
                  Text('$opponentScore', style: AppTextStyles.display.copyWith(color: AppColors.red, fontSize: 36)),
                ],
              ),

              const SizedBox(height: 24),

              // Reward Icons Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatIcon(icon: Icons.stars_rounded, label: '+$xpEarned', subLabel: 'XP', color: AppColors.purple),
                    _StatIcon(icon: Icons.monetization_on_rounded, label: '+$coinsEarned', subLabel: 'COINS', color: AppColors.gold),
                    _StatIcon(icon: Icons.whatshot_rounded, label: '$winStreak', subLabel: 'STREAK', color: AppColors.red),
                    _StatIcon(icon: Icons.emoji_events_rounded, label: '$winMargin', subLabel: 'MARGIN', color: AppColors.teal),
                  ],
                ),
              ),

              if (isMvp) ...[
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Congratulations!', style: AppTextStyles.headline.copyWith(fontSize: 14, color: AppColors.gold)),
                            Text('You are this week\'s top player!', style: AppTextStyles.label.copyWith(fontSize: 10, color: Colors.white70)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),
              
              // Footer message
              Text(
                'Think you can beat me?',
                style: AppTextStyles.bodyMd.copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
              ),
              Text(
                'Challenge me on QuestArena!',
                style: AppTextStyles.label.copyWith(color: Colors.white70),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCard() {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purple, AppColors.primaryBg],
        ),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SmartAvatar(
            avatarUrl: avatarUrl,
            rank: rank,
            size: 40,
            showBorder: false,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(username, style: AppTextStyles.headline.copyWith(fontSize: 14), overflow: TextOverflow.ellipsis),
                Text('VICTORY vs $opponentName', style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.gold)),
              ],
            ),
          ),
          Text(
            '$playerScore-$opponentScore',
            style: AppTextStyles.headline.copyWith(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _StatIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subLabel;
  final Color color;

  const _StatIcon({required this.icon, required this.label, required this.subLabel, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.headline.copyWith(fontSize: 12, color: Colors.white)),
        Text(subLabel, style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textMuted)),
      ],
    );
  }
}
