import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/text_styles.dart';
import '../../core/constants/avatars.dart';
import '../../providers/user_providers.dart';
import '../../providers/avatar_providers.dart';
import '../../data/models/user_model.dart';
import 'package:questarena/ui/widgets/smart_avatar.dart';

class AvatarSelectionScreen extends ConsumerWidget {
  const AvatarSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: Text('User not found')));

        return Scaffold(
          backgroundColor: AppColors.bgBase,
          appBar: AppBar(
            title: Text('AVATAR GALLERY', style: AppTextStyles.display.copyWith(fontSize: 18)),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Column(
            children: [
              _buildCurrentSelection(user),
              const Divider(color: AppColors.surface, height: 1),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: AppAvatars.avatars.length,
                  itemBuilder: (context, index) {
                    final avatar = AppAvatars.avatars[index];
                    final isUnlocked = user.unlockedAvatars.contains(avatar.image);
                    final isSelected = user.avatarUrl == avatar.image;

                    return _AvatarGridTile(
                      avatar: avatar,
                      isUnlocked: isUnlocked,
                      isSelected: isSelected,
                      onTap: () => _onAvatarTap(context, ref, user, avatar, isUnlocked),
                    ).animate().fadeIn(delay: (index * 20).ms).slideY(begin: 0.1, end: 0, delay: (index * 20).ms);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentSelection(UserModel user) {
    return Container(
      padding: const EdgeInsets.all(24),
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.gold.withValues(alpha: 0.05),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          Hero(
            tag: 'selected_avatar',
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.gold, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
                },
                child: SmartAvatar(
                  key: ValueKey(user.avatarUrl),
                  avatarUrl: user.avatarUrl,
                  size: 80,
                  showBorder: false,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ACTIVE AVATAR',
                  style: AppTextStyles.label.copyWith(
                    color: AppColors.gold,
                    letterSpacing: 1.2,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.username,
                  style: AppTextStyles.headline.copyWith(fontSize: 22, letterSpacing: 0.5),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.rank.toUpperCase(),
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onAvatarTap(BuildContext context, WidgetRef ref, UserModel user, AvatarModel avatar, bool isUnlocked) async {
    if (!isUnlocked) {
      _showLockedDialog(context, avatar);
      return;
    }

    if (user.avatarUrl == avatar.image) return;

    try {
      await ref.read(avatarServiceProvider).selectAvatar(user.uid, avatar.image, user.unlockedAvatars);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red),
        );
      }
    }
  }

  void _showLockedDialog(BuildContext context, AvatarModel avatar) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.gold, width: 0.5)),
          title: Text('LOCKED AVATAR', style: AppTextStyles.headline.copyWith(color: AppColors.gold, fontSize: 18), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: ColorFiltered(
                  colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                  child: CachedNetworkImage(imageUrl: avatar.image, width: 100, height: 100, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Reach ${avatar.requiredLeague} League to unlock ${avatar.name}.',
                style: AppTextStyles.bodyMd.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('GOT IT', style: AppTextStyles.label.copyWith(color: AppColors.gold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarGridTile extends StatelessWidget {
  final AvatarModel avatar;
  final bool isUnlocked;
  final bool isSelected;
  final VoidCallback onTap;

  const _AvatarGridTile({
    required this.avatar,
    required this.isUnlocked,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Animated Selection Border
                if (isSelected)
                  _buildAvatarImage()
                      .animate(onPlay: (controller) => controller.repeat(reverse: true))
                      .custom(
                        duration: 1.5.seconds,
                        builder: (context, value, child) {
                          return Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.5 + (0.5 * (value - 0.5).abs())),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.gold.withValues(alpha: 0.2 * value),
                                  blurRadius: 10 * value,
                                  spreadRadius: 2 * value,
                                ),
                              ],
                            ),
                            child: child,
                          );
                        },
                      )
                else
                  _buildAvatarImage(),
                
                // Selection Checkmark
                if (isSelected)
                  Positioned(
                    bottom: 0,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
                      child: const Icon(Icons.check_rounded, color: Colors.black, size: 12),
                    ).animate().scale(curve: Curves.elasticOut, duration: 500.ms),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            avatar.name.toUpperCase(),
            style: AppTextStyles.label.copyWith(
              fontSize: 10,
              letterSpacing: 0.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isUnlocked ? Colors.white : AppColors.textMuted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            isUnlocked ? avatar.style : 'LOCKED',
            style: AppTextStyles.label.copyWith(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? AppColors.teal : AppColors.neonPink,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarImage() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.surface,
      ),
      child: ClipOval(
        child: Stack(
          children: [
            CachedNetworkImage(
              imageUrl: avatar.image,
              fit: BoxFit.cover,
              width: 80,
              height: 80,
              color: isUnlocked ? null : Colors.grey,
              colorBlendMode: isUnlocked ? null : BlendMode.saturation,
            ),
            if (!isUnlocked)
              Positioned.fill(
                child: ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 1.0, sigmaY: 1.0),
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: const Icon(Icons.lock_rounded, color: Colors.white70, size: 20),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
