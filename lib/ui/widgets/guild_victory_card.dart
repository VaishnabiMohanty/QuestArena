import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import 'smart_avatar.dart';

class GuildVictoryCard extends StatelessWidget {
  final String guildName;
  final String guildIconId;
  final String opponentGuildName;
  final int guildScore;
  final int opponentScore;
  final String playerName;
  final String? playerAvatarUrl;
  final int playerContribution;
  final int xpEarned;
  final bool isMvp;

  const GuildVictoryCard({
    super.key,
    required this.guildName,
    required this.guildIconId,
    required this.opponentGuildName,
    required this.guildScore,
    required this.opponentScore,
    required this.playerName,
    this.playerAvatarUrl,
    required this.playerContribution,
    required this.xpEarned,
    this.isMvp = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonPink.withValues(alpha: 0.2),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative Particles
          ...List.generate(15, (index) {
            final double top = (index * 23) % 400.0;
            final double left = (index * 37) % 320.0;
            return Positioned(
              top: top,
              left: left,
              child: Icon(
                Icons.castle_rounded,
                size: 6 + (index % 10).toDouble(),
                color: AppColors.neonPink.withValues(alpha: 0.2),
              ),
            );
          }),
          
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.groups_rounded, color: AppColors.neonPink, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'GUILD BATTLE',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.neonPink,
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

              // Guild Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.neonPink.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.neonPink.withValues(alpha: 0.3)),
                ),
                child: Icon(_getGuildIcon(guildIconId), color: AppColors.neonPink, size: 48),
              ),

              const SizedBox(height: 12),
              Text(guildName.toUpperCase(), style: AppTextStyles.headline.copyWith(fontSize: 20, color: Colors.white)),
              const SizedBox(height: 20),

              // VS Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text('$guildScore', style: AppTextStyles.display.copyWith(color: AppColors.neonCyan, fontSize: 32)),
                      Text('OUR SCORE', style: AppTextStyles.label.copyWith(fontSize: 8)),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text('VS', style: AppTextStyles.headline.copyWith(color: AppColors.textMuted)),
                  ),
                  Column(
                    children: [
                      Text('$opponentScore', style: AppTextStyles.display.copyWith(color: AppColors.red, fontSize: 32)),
                      Text('ENEMY GUILD', style: AppTextStyles.label.copyWith(fontSize: 8)),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),
              const Divider(color: AppColors.surface, indent: 40, endIndent: 40),
              const SizedBox(height: 16),

              // Player contribution
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SmartAvatar(avatarUrl: playerAvatarUrl, size: 40),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(playerName, style: AppTextStyles.bodyMd.copyWith(fontWeight: FontWeight.bold)),
                      Text('Contributed $playerContribution pts', style: AppTextStyles.label.copyWith(fontSize: 9, color: AppColors.gold)),
                    ],
                  ),
                  if (isMvp) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 20),
                  ],
                ],
              ),

              const SizedBox(height: 24),
              
              // Rewards
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   _StatMini(icon: Icons.stars_rounded, value: '+$xpEarned', label: 'GUILD XP', color: AppColors.purple),
                   const SizedBox(width: 40),
                   _StatMini(icon: Icons.monetization_on_rounded, value: '+100', label: 'COINS', color: AppColors.gold),
                ],
              ),

              const SizedBox(height: 30),
              Text('WE ARE UNSTOPPABLE!', style: AppTextStyles.label.copyWith(color: AppColors.neonPink, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getGuildIcon(String id) {
    switch (id) {
      case '1': return Icons.auto_awesome_rounded;
      case '2': return Icons.military_tech_rounded;
      case '3': return Icons.shield_rounded;
      case '4': return Icons.bolt_rounded;
      case '5': return Icons.workspace_premium_rounded;
      case '6': return Icons.pets_rounded;
      default: return Icons.groups_rounded;
    }
  }
}

class _StatMini extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _StatMini({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        Text(value, style: AppTextStyles.headline.copyWith(fontSize: 16)),
        Text(label, style: AppTextStyles.label.copyWith(fontSize: 7)),
      ],
    );
  }
}
