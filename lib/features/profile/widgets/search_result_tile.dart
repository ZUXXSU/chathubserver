import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/core/models/user.dart';
import 'package:flutter_app/features/profile/controllers/search_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// A widget that displays a single user in the search results list.
///
/// Shows the user's avatar, name, and a button to send a friend request.
class SearchResultTile extends StatelessWidget {
  final PopulatedUser user;
  final CustomSearchController controller;

  const SearchResultTile({
    super.key,
    required this.user,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        radius: 25,
        backgroundImage: NetworkImage(user.avatar),
      ),
      title: Text(
        user.name,
        style: const TextStyle(
          color: ChatHubTheme.textOnSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        '@${user.name}',
        style: const TextStyle(
          color: Colors.grey,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.person_add, color: ChatHubTheme.primary),
        onPressed: () {
          // Show confirmation dialog
          Get.defaultDialog(
            title: 'Send Request?',
            titleStyle: const TextStyle(color: ChatHubTheme.textOnSurface),
            middleText: 'Send a friend request to ${user.name}?',
            middleTextStyle: const TextStyle(color: ChatHubTheme.textOnSurface),
            backgroundColor: ChatHubTheme.surface,
            buttonColor: ChatHubTheme.primary,
            textConfirm: 'Send',
            textCancel: 'Cancel',
            confirmTextColor: ChatHubTheme.textOnPrimary,
            cancelTextColor: ChatHubTheme.textOnSurface,
            onConfirm: () {
              Get.back(); // Close dialog
              controller.sendRequest(user.id, user.name);
            },
          );
        },
        tooltip: 'Send Friend Request',
      ),
    );
  }
}
