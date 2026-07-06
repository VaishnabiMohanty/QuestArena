import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/text_styles.dart';
import '../../../providers/user_providers.dart';
import '../../../providers/guild_providers.dart';
import '../../../data/models/guild_model.dart';
import '../../widgets/smart_avatar.dart';
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
              
              await ref.read(guildRepositoryProvider).createGuild(
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
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.red));
              }
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.neonCyan),
          child: const Text('JOIN', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

void showInviteFriendsBottomSheet(BuildContext context, WidgetRef ref, GuildModel guild) {
  showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bgBase,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
    ),
    builder: (context) => _InviteFriendsSheet(guild: guild),
  );
}

class _InviteFriendsSheet extends ConsumerStatefulWidget {
  final GuildModel guild;
  const _InviteFriendsSheet({required this.guild});

  @override
  ConsumerState<_InviteFriendsSheet> createState() => _InviteFriendsSheetState();
}

class _InviteFriendsSheetState extends ConsumerState<_InviteFriendsSheet> {
  final Set<String> _invitedUids = {};

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final sentInvitesAsync = ref.watch(guildSentInvitationsProvider(widget.guild.id));
    final user = ref.read(currentUserProvider).value;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('INVITE FRIENDS', style: AppTextStyles.display.copyWith(fontSize: 20, color: AppColors.neonCyan)),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: friendsAsync.when(
              data: (friends) {
                // Filter out friends who are already in THIS guild
                final eligibleFriends = friends.where((f) => !widget.guild.memberUids.contains(f.uid)).toList();
                
                if (eligibleFriends.isEmpty) {
                  return const Center(
                    child: Text('No friends found to invite.', style: TextStyle(color: AppColors.textMuted)),
                  );
                }
                
                return ListView.builder(
                  itemCount: eligibleFriends.length,
                  itemBuilder: (context, index) {
                    final friend = eligibleFriends[index];
                    final isAlreadyInAnotherGuild = friend.guildId != null;
                    final hasSentInvite = _invitedUids.contains(friend.uid) || 
                        (sentInvitesAsync.value?.any((invite) => invite['receiverUid'] == friend.uid) ?? false);
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surface),
                      ),
                      child: Row(
                        children: [
                          SmartAvatar(avatarUrl: friend.avatarUrl, size: 48),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              friend.username,
                              style: AppTextStyles.bodyMd.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isAlreadyInAnotherGuild ? AppColors.textMuted : Colors.white,
                              ),
                            ),
                          ),
                          if (isAlreadyInAnotherGuild)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.surface.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'ALREADY IN A GUILD',
                                style: AppTextStyles.label.copyWith(fontSize: 8, color: AppColors.textMuted, fontWeight: FontWeight.w900),
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: hasSentInvite ? null : () async {
                                setState(() => _invitedUids.add(friend.uid));
                                await ref.read(guildRepositoryProvider).inviteFriend(
                                  guildId: widget.guild.id,
                                  guildName: widget.guild.name,
                                  guildIconId: widget.guild.iconId,
                                  senderUid: user!.uid,
                                  senderName: user.username,
                                  receiverUid: friend.uid,
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: hasSentInvite ? AppColors.surface : AppColors.neonCyan,
                                foregroundColor: hasSentInvite ? AppColors.textMuted : Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasSentInvite) ...[
                                    const Icon(Icons.check_rounded, size: 14),
                                    const SizedBox(width: 4),
                                    const Text('INVITED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                  ] else 
                                    const Text('INVITE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: AppColors.red))),
            ),
          ),
        ],
      ),
    );
  }
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
