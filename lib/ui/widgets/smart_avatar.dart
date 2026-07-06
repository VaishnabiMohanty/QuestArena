import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'character_avatar.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/borders.dart';
import '../../core/utils/rank_system.dart';

class SmartAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? rank;
  final double size;
  final bool showGlow;
  final bool showBorder;
  final String? borderId;

  const SmartAvatar({
    super.key,
    this.avatarUrl,
    this.rank,
    this.size = 56,
    this.showGlow = false,
    this.showBorder = true,
    this.borderId,
  });

  static String getAvatarIdForRank(String? rank) {
    if (rank == null) return 'f3';
    final normalized = rank.toLowerCase();
    
    if (normalized.contains('bronze')) {
      return 'm3'; // Ryo
    } else if (normalized.contains('silver')) {
      return 'f2'; // Arya
    } else if (normalized.contains('gold')) {
      return 'm1'; // Veer
    } else if (normalized.contains('platinum')) {
      return 'f1'; // Nova
    } else if (normalized.contains('diamond') || 
               normalized.contains('master') || 
               normalized.contains('champion') || 
               normalized.contains('legend')) {
      return 'm2'; // Zane
    } else if (normalized.contains('unranked')) {
      return 'f3'; // Lyra
    }
    
    return 'f3'; // Fallback
  }

  @override
  Widget build(BuildContext context) {
    final effectiveAvatar = (avatarUrl != null && avatarUrl!.isNotEmpty)
        ? avatarUrl
        : (rank != null ? getAvatarIdForRank(rank) : null);

    Widget avatarWidget;

    if (effectiveAvatar == null || effectiveAvatar.isEmpty) {
      avatarWidget = _buildFallback();
    } else {
      // Check if it's a character ID (e.g., 'f1', 'm2')
      final character = kCharacters.cast<CharacterData?>().firstWhere(
            (c) => c?.id == effectiveAvatar,
            orElse: () => null,
          );

      if (character != null) {
        avatarWidget = CharacterAvatar(
          character: character,
          size: size,
          showGlow: showGlow,
          showBorder: showBorder,
        );
      } else {
        // Otherwise, assume it's a network URL
        avatarWidget = _buildNetworkAvatar(effectiveAvatar);
      }
    }

    if (borderId != null && borderId != 'no_border') {
      final border = AppBorders.getBorderById(borderId);
      final borderColor = RankSystem.getRankColor(border.requiredLeague);

      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // Procedural glow behind the avatar
            Container(
              width: size * 0.95,
              height: size * 0.95,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            avatarWidget,
            Positioned(
              width: size * 1.15,
              height: size * 1.15,
              child: IgnorePointer(
                child: Image.asset(
                  border.image,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Procedural Fallback if image asset is missing (fixes the red cross)
                    return Container(
                      width: size * 1.15,
                      height: size * 1.15,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: borderColor.withValues(alpha: 0.8),
                          width: size * 0.06,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    return avatarWidget;
  }

  Widget _buildNetworkAvatar(String url) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: AppColors.surface, width: 2)
            : null,
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: AppColors.neonCyan.withValues(alpha: 0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: AppColors.surface,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
            ),
          ),
          errorWidget: (context, url, error) => _buildFallback(),
        ),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: showBorder
            ? Border.all(color: AppColors.textMuted.withValues(alpha: 0.5), width: 1)
            : null,
      ),
      child: Icon(
        Icons.person_rounded,
        size: size * 0.6,
        color: AppColors.textMuted,
      ),
    );
  }
}
