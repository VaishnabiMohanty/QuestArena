import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'character_avatar.dart';
import '../../core/constants/colors.dart';

class SmartAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String? rank;
  final double size;
  final bool showGlow;
  final bool showBorder;

  const SmartAvatar({
    super.key,
    this.avatarUrl,
    this.rank,
    this.size = 56,
    this.showGlow = false,
    this.showBorder = true,
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

    if (effectiveAvatar == null || effectiveAvatar.isEmpty) {
      return _buildFallback();
    }

    // Check if it's a character ID (e.g., 'f1', 'm2')
    final character = kCharacters.cast<CharacterData?>().firstWhere(
          (c) => c?.id == effectiveAvatar,
          orElse: () => null,
        );

    if (character != null) {
      return CharacterAvatar(
        character: character,
        size: size,
        showGlow: showGlow,
        showBorder: showBorder,
      );
    }

    // Otherwise, assume it's a network URL
    return _buildNetworkAvatar(effectiveAvatar);
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
