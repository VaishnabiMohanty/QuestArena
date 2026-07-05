import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../providers/user_providers.dart';
import '../../providers/shop_provider.dart';
import '../../data/services/shop_service.dart';

class StoreScreen extends ConsumerWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).value;
    final shopState = ref.watch(shopControllerProvider);

    // Listen for shop state changes to show snackbars
    ref.listen<AsyncValue<void>>(shopControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: AppColors.red,
            ),
          );
        },
        data: (_) {
          if (previous is AsyncLoading) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Purchase successful!'),
                backgroundColor: AppColors.teal,
              ),
            );
          }
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text('SHOP', style: AppTextStyles.display.copyWith(fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _buildCoinBalance(user?.coins ?? 0),
        ],
      ),
      body: shopState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Lifelines'),
                  const SizedBox(height: 12),
                  _buildLifelineSection(context, ref, user),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Rank Protection Shields'),
                  const SizedBox(height: 12),
                  _buildRankProtectionSection(context, ref, user),
                ],
              ),
            ),
    );
  }

  Widget _buildCoinBalance(int coins) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 18),
              const SizedBox(width: 6),
              Text('$coins', style: AppTextStyles.headline.copyWith(fontSize: 14, color: AppColors.gold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: AppTextStyles.headline.copyWith(fontSize: 16, color: AppColors.purple),
    );
  }

  Widget _buildLifelineSection(BuildContext context, WidgetRef ref, dynamic user) {
    return Column(
      children: [
        _buildShopItem(
          context: context,
          title: 'Remove 1 Option',
          description: 'Randomly hides one incorrect option during a quiz.',
          price: ShopService.oneOptionLifelineCost,
          owned: user?.oneOptionLifelines ?? 0,
          onTap: () => ref.read(shopControllerProvider.notifier).purchaseOneOptionLifeline(),
          canAfford: (user?.coins ?? 0) >= ShopService.oneOptionLifelineCost,
          icon: Icons.exposure_minus_1,
        ),
        const SizedBox(height: 12),
        _buildShopItem(
          context: context,
          title: 'Remove 2 Options',
          description: 'Randomly hides two incorrect options during a quiz.',
          price: ShopService.twoOptionLifelineCost,
          owned: user?.twoOptionLifelines ?? 0,
          onTap: () => ref.read(shopControllerProvider.notifier).purchaseTwoOptionLifeline(),
          canAfford: (user?.coins ?? 0) >= ShopService.twoOptionLifelineCost,
          icon: Icons.exposure_minus_2,
        ),
      ],
    );
  }

  Widget _buildRankProtectionSection(BuildContext context, WidgetRef ref, dynamic user) {
    final shields = ShopService.rankProtectionCosts.entries.toList();
    final int remainingMatches = user?.rankProtectionMatches ?? 0;

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security, color: AppColors.purple, size: 20),
              const SizedBox(width: 8),
              Text(
                'Remaining Protection: $remainingMatches Matches',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.purple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...shields.map((entry) {
          final bool canAfford = (user?.coins ?? 0) >= entry.value;

          return _buildShopItem(
            context: context,
            title: '${entry.key} Match Protection',
            description: 'Prevents Rank Point loss for ${entry.key} matches.',
            price: entry.value,
            owned: 0,
            onTap: () => ref.read(shopControllerProvider.notifier).purchaseRankProtection(entry.key, entry.value),
            canAfford: canAfford,
            icon: Icons.security,
            hideOwned: true,
          );
        }),
      ],
    );
  }

  Widget _buildShopItem({
    required BuildContext context,
    required String title,
    required String description,
    required int price,
    required int owned,
    required VoidCallback onTap,
    required bool canAfford,
    required IconData icon,
    bool hideOwned = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surface),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.gold, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.headline.copyWith(fontSize: 16)),
                const SizedBox(height: 4),
                Text(description, style: AppTextStyles.label.copyWith(color: AppColors.textSecondary)),
                if (!hideOwned) ...[
                  const SizedBox(height: 4),
                  Text('Owned: $owned', style: AppTextStyles.label.copyWith(color: AppColors.purple, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: canAfford ? onTap : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              disabledBackgroundColor: AppColors.surface,
              disabledForegroundColor: AppColors.textSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_rounded, size: 16),
                const SizedBox(width: 4),
                Text('$price', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
