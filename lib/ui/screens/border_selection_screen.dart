import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/borders.dart';
import '../../providers/border_providers.dart';
import '../../providers/user_providers.dart';
import '../widgets/bordered_avatar.dart';

class BorderSelectionScreen extends ConsumerWidget {
  const BorderSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final borders = ref.watch(availableBordersProvider);
    final user = ref.watch(currentUserProvider).value;
    final selectedId = ref.watch(selectedBorderProvider);
    final borderService = ref.watch(borderServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        title: const Text('Change Border', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Preview Section
          Center(
            child: Column(
              children: [
                Hero(
                  tag: 'avatar-border',
                  child: BorderedAvatar(
                    avatarUrl: user?.avatarUrl,
                    rank: user?.rank,
                    size: 150,
                    borderId: selectedId,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppBorders.getBorderById(selectedId).name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 0.85,
                ),
                itemCount: borders.length,
                itemBuilder: (context, index) {
                  final border = borders[index];
                  final isSelected = border.id == selectedId;
                  final isUnlocked = border.isUnlocked;

                  return GestureDetector(
                    onTap: isUnlocked
                        ? () => borderService.selectBorder(user!.uid, border.id)
                        : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.gold.withValues(alpha: 0.1)
                            : AppColors.bgBase.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected ? AppColors.gold : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              BorderedAvatar(
                                avatarUrl: user?.avatarUrl,
                                rank: user?.rank,
                                size: 80,
                                borderId: border.id,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                border.name,
                                style: TextStyle(
                                  color: isUnlocked ? Colors.white : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!isUnlocked)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    'Requires ${border.requiredLeague}',
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (!isUnlocked)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Icon(Icons.lock, color: Colors.grey.withValues(alpha: 0.8), size: 20),
                            ),
                          if (isSelected)
                            const Positioned(
                              top: 10,
                              right: 10,
                              child: Icon(Icons.check_circle, color: AppColors.gold, size: 20),
                            ),
                          if (!isUnlocked)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                        ],
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
}
