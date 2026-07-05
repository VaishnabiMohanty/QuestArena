import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../providers/user_providers.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../widgets/smart_avatar.dart';
import '../../widgets/character_avatar.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  String? _selectedAvatarId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(currentUserProvider).value;
    if (user != null) {
      _usernameController.text = user.username;
      _selectedAvatarId = user.avatarUrl ?? kCharacters.first.id;
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final user = ref.read(currentUserProvider).value;
    if (user == null || _isSaving) return;

    final newUsername = _usernameController.text.trim();
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Username cannot be empty')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updatedUser = user.copyWith(
        username: newUsername,
        avatarUrl: _selectedAvatarId,
      );
      await ref.read(userRepositoryProvider).updateUserProfile(updatedUser);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBg,
      appBar: AppBar(
        title: Text('EDIT PROFILE', style: AppTextStyles.display.copyWith(fontSize: 18, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    SmartAvatar(avatarUrl: _selectedAvatarId, size: 120, showBorder: true, showGlow: true),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: AppColors.neonViolet, shape: BoxShape.circle),
                        child: const Icon(Icons.check_rounded, size: 20, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              Text('SELECT CHARACTER', style: AppTextStyles.label.copyWith(letterSpacing: 2, color: AppColors.textMuted)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: kCharacters.length,
                itemBuilder: (context, index) {
                  final character = kCharacters[index];
                  final isSelected = _selectedAvatarId == character.id;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatarId = character.id),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? AppColors.gold : AppColors.surface, width: 2),
                        boxShadow: isSelected ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.15), blurRadius: 10)] : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: SmartAvatar(avatarUrl: character.id, size: 60, showBorder: false),
                      ),
                    ),
                  ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1));
                },
              ),
              const SizedBox(height: 40),

              Text('USERNAME', style: AppTextStyles.label.copyWith(letterSpacing: 2, color: AppColors.textMuted)),
              const SizedBox(height: 12),
              TextField(
                controller: _usernameController,
                style: AppTextStyles.headline.copyWith(fontSize: 18),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.cardBg,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.person_rounded, color: AppColors.purple),
                  hintText: 'Enter username',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              const SizedBox(height: 48),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 8,
                    shadowColor: AppColors.purple.withValues(alpha: 0.4),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('SAVE PROFILE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
