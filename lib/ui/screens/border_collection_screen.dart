import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/borders.dart';
import '../../data/models/border_model.dart';
import '../../providers/user_providers.dart';
import '../../providers/border_providers.dart';
import '../widgets/smart_avatar.dart';
import '../widgets/neon_swirl_background.dart';

class BorderCollectionScreen extends ConsumerWidget {
  const BorderCollectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: Text('User not found')));

        final unlocked = Set<String>.from(user.unlockedBorders);
        final currentBorder = user.selectedBorder;

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: AppBar(
            title: Text('BORDER COLLECTION', style: AppTextStyles.display.copyWith(fontSize: 18, letterSpacing: 2)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
          ),
          body: NeonSwirlBackground(
            colors: const [AppColors.neonCyan, AppColors.neonViolet],
            child: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: AppBorders.borders.length,
              itemBuilder: (context, index) {
                final border = AppBorders.borders[index];
                final isUnlocked = unlocked.contains(border.id) || border.id == 'no_border';
                final isSelected = currentBorder == border.id || (currentBorder == null && border.id == 'no_border');

                return _BorderCard(
                  border: border,
                  isUnlocked: isUnlocked,
                  isSelected: isSelected,
                  avatarUrl: user.avatarUrl,
                  onSelect: () async {
                    if (isUnlocked && !isSelected) {
                      await ref.read(borderServiceProvider).selectBorder(user.uid, border.id);
                    }
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _BorderCard extends StatelessWidget {
  final BorderModel border;
  final bool isUnlocked;
  final bool isSelected;
  final String? avatarUrl;
  final VoidCallback onSelect;

  const _BorderCard({
    required this.border,
    required this.isUnlocked,
    required this.isSelected,
    required this.avatarUrl,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        decoration: BoxDecoration(
          color: isUnlocked ? AppColors.cardBg : AppColors.cardBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.gold : (isUnlocked ? AppColors.surface : Colors.white10),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.2),
              blurRadius: 15,
              spreadRadius: 2,
            )
          ] : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: isUnlocked ? 1.0 : 0.4,
                  child: SmartAvatar(
                    avatarUrl: avatarUrl,
                    size: 70,
                    showBorder: false,
                    borderId: border.id,
                  ),
                ),
                if (!isUnlocked)
                  const Icon(Icons.lock_rounded, color: Colors.white70, size: 32),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              border.name,
              style: AppTextStyles.bodyMd.copyWith(
                fontWeight: FontWeight.bold,
                color: isUnlocked ? Colors.white : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isUnlocked ? 'UNLOCKED' : border.requiredLeague,
              style: AppTextStyles.label.copyWith(
                fontSize: 10,
                color: isUnlocked ? AppColors.teal : AppColors.textMuted,
              ),
            ),
            if (isSelected)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  'EQUIPPED',
                  style: TextStyle(color: Colors.green, fontSize: 9, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    ).animate(target: isSelected ? 1 : 0).shimmer(duration: 2.seconds, color: AppColors.gold.withValues(alpha: 0.2));
  }
}
