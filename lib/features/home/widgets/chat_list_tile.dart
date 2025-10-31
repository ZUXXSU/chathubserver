import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/core/models/chat.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ChatListTile extends StatelessWidget {
  final Chat chat;

  const ChatListTile({super.key, required this.chat});

  @override
  Widget build(BuildContext context) {
    // Use the first avatar as a placeholder, or a group icon
    String? displayAvatarUrl =
        chat.avatar.isNotEmpty ? chat.avatar.first : null;
    IconData fallbackIcon =
        chat.groupChat ? Icons.group : Icons.person;

    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundColor: ChatHubTheme.surface,
        backgroundImage:
            displayAvatarUrl != null ? NetworkImage(displayAvatarUrl) : null,
        child: displayAvatarUrl == null
            ? Icon(fallbackIcon, color: ChatHubTheme.primary)
            : null,
      ),
      title: Text(
        chat.name,
        style: const TextStyle(
          color: ChatHubTheme.textOnSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: const Text(
        'Last message placeholder...', // Your Chat model doesn't have last message
        style: TextStyle(color: Colors.grey),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () {
        // Navigate to ChatScreen using GetX
        Get.toNamed(
          '/chat',
          arguments: {
            'chatId': chat.id,
            'chatName': chat.name,
            'members': chat.members,
          },
        );
      },
    );
  }
}
