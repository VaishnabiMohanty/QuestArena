import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/guild_providers.dart';
import 'guild_home_screen.dart';

void showGuildOptionsDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('GUILDS', style: AppTextStyles.headline.copyWith(color: AppColors.neonPink)),
      content: const Text(
        'Join a guild to participate in Guild Battles and climb the ranks together.',
        style: TextStyle(color: AppColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            showJoinGuildDialog(context, ref);
          },
          child: const Text('JOIN GUILD', style: TextStyle(color: AppColors.neonCyan)),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            showCreateGuildDialog(context, ref);
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPink),
          child: const Text('CREATE GUILD', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

void showCreateGuildDialog(BuildContext context, WidgetRef ref) {
  final nameController = TextEditingController();
  String selectedIconId = '1';

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        scrollable: true,
        backgroundColor: AppColors.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('CREATE GUILD', style: AppTextStyles.headline.copyWith(color: AppColors.neonPink)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'GUILD NAME',
                labelStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.surface)),
                focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.neonPink)),
              ),
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 24),
            const Text('SELECT ICON', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(6, (i) {
                final id = (i + 1).toString();
                final isSelected = selectedIconId == id;
                return GestureDetector(
                  onTap: () => setState(() => selectedIconId = id),
                  child: Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? AppColors.neonPink : AppColors.surface,
                      border: Border.all(color: isSelected ? Colors.white : Colors.transparent, width: 2),
                    ),
                    child: Icon(_getIconData(id), color: isSelected ? Colors.white : AppColors.textMuted, size: 24),
                  ),
                );
              }),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              final user = ref.read(currentUserProvider).value;
              if (user == null) return;
              
              final guildId = await ref.read(guildRepositoryProvider).createGuild(
                name: nameController.text.trim(),
                iconId: selectedIconId,
                leader: user,
              );
              
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildHomeScreen()));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonPink),
            child: const Text('CREATE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}

void showJoinGuildDialog(BuildContext context, WidgetRef ref) {
  final codeController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      scrollable: true,
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('JOIN GUILD', style: AppTextStyles.headline.copyWith(color: AppColors.neonCyan)),
      content: TextField(
        controller: codeController,
        decoration: const InputDecoration(
          labelText: 'GUILD CODE',
          labelStyle: TextStyle(color: AppColors.textMuted),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.surface)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppColors.neonCyan)),
        ),
        style: const TextStyle(color: Colors.white),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL', style: TextStyle(color: AppColors.textMuted))),
        ElevatedButton(
          onPressed: () async {
            if (codeController.text.trim().isEmpty) return;
            final user = ref.read(currentUserProvider).value;
            if (user == null) return;

            try {
              await ref.read(guildRepositoryProvider).joinGuild(codeController.text.trim().toUpperCase(), user);
              if (context.mounted) {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GuildHomeScreen()));
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
          child: const Text('JOIN', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

IconData _getIconData(String id) {
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
