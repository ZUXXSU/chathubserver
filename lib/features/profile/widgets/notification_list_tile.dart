import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/core/models/FriendRequestNotification.dart';
import 'package:flutter_app/features/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A widget that displays a single friend request and provides
/// "Accept" and "Reject" buttons.
class NotificationListTile extends StatelessWidget {
  /// The type is the correct `FriendRequestNotification`
  final FriendRequestNotification notification;

  const NotificationListTile({
    super.key,
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    // Find the controller to call accept/reject methods
    final ProfileController controller = Get.find();

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(notification.sender.avatar),
        backgroundColor: ChatHubTheme.backgroundLight,
      ),
      title: Text(
        notification.sender.name,
        style: const TextStyle(
          color: ChatHubTheme.textOnSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: const Text(
        'Sent you a friend request',
        style: TextStyle(color: ChatHubTheme.textSecondary),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reject Button
          IconButton(
            icon: const Icon(Icons.close, color: ChatHubTheme.error),
            onPressed: () {
              // --- CORRECTION ---
              controller.handleFriendRequest(
                requestId: notification.id,
                accept: false,
              );
            },
          ),
          // Accept Button
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            onPressed: () {
              // --- CORRECTION ---
              controller.handleFriendRequest(
                requestId: notification.id,
                accept: true,
              );
            },
          ),
        ],
      ),
    );
  }
}