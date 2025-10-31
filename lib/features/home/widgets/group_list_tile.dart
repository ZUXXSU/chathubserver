import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/core/models/chat.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GroupListTile extends StatelessWidget {
  final GroupInfo group;

  const GroupListTile({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    // Use the first avatar as a placeholder, or a group icon
    String? displayAvatarUrl =
        group.avatar.isNotEmpty ? group.avatar.first : null;

    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: ChatHubTheme.surface,
        backgroundImage:
            displayAvatarUrl != null ? NetworkImage(displayAvatarUrl) : null,
        child: displayAvatarUrl == null
            ? const Icon(Icons.group, color: ChatHubTheme.primary)
            : null,
      ),
      title: Text(
        group.name,
        style: const TextStyle(
          color: ChatHubTheme.textOnSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      onTap: () {
        // Navigate to ChatScreen using GetX
        // We need to fetch members first, or pass an empty list
        // and have ChatScreen fetch them.
        // For now, just navigate.
        Get.toNamed(
          '/chat',
          arguments: {
            'chatId': group.id,
            'chatName': group.name,
            'members': [], // TODO: Pass actual members or fetch in ChatScreen
          },
        );
      },
    );
  }
}
