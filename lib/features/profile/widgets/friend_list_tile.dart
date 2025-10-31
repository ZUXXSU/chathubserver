import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/core/models/user.dart';
import 'package:flutter/material.dart';

/// A simple widget to display a friend in a list.
class FriendListTile extends StatelessWidget {
  final PopulatedUser friend;

  const FriendListTile({super.key, required this.friend});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(friend.avatar),
      ),
      title: Text(
        friend.name,
        style: const TextStyle(
          color: ChatHubTheme.textOnSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '@${friend.name}',
        style: const TextStyle(color: Colors.grey),
      ),
      // You could add an onTap to open a 1-on-1 chat
      onTap: () {
        // TODO: Implement navigation to chat screen
        // Get.to(() => ChatScreen(chat: ...));
      },
    );
  }
}
