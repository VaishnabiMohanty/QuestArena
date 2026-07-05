import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/borders.dart';
import '../../providers/border_providers.dart';
import 'smart_avatar.dart';

class BorderedAvatar extends ConsumerWidget {
  final String? avatarUrl;
  final String? rank;
  final double size;
  final bool showGlow;
  final String? borderId;

  const BorderedAvatar({
    super.key,
    this.avatarUrl,
    this.rank,
    this.size = 56,
    this.showGlow = false,
    this.borderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final effectiveBorderId = borderId ?? ref.watch(selectedBorderProvider);
    final border = AppBorders.getBorderById(effectiveBorderId);

    return Stack(
      alignment: Alignment.center,
      children: [
        // The Avatar
        SmartAvatar(
          avatarUrl: avatarUrl,
          rank: rank,
          size: size * 0.85, // Slightly smaller to fit inside border
          showGlow: showGlow,
          showBorder: border.id == 'no_border',
        ),
        
        // The Border
        if (border.id != 'no_border')
          SizedBox(
            width: size,
            height: size,
            child: Image.asset(
              border.image,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                // Fallback if asset is missing: Draw a simple colored ring
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getBorderColor(border.requiredLeague),
                      width: size * 0.08,
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Color _getBorderColor(String league) {
    switch (league) {
      case 'Bronze': return const Color(0xFFCD7F32);
      case 'Silver': return const Color(0xFFC0C0C0);
      case 'Gold': return const Color(0xFFFFD700);
      case 'Platinum': return const Color(0xFFE5E4E2);
      case 'Diamond': return const Color(0xFFB9F2FF);
      default: return Colors.transparent;
    }
  }
}
