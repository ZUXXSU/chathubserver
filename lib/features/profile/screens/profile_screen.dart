import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/core/models/user.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/features/profile/controllers/profile_controller.dart';
import 'package:flutter_app/features/profile/screens/notifications_screen.dart';
import 'package:flutter_app/features/profile/screens/search_screen.dart';
import 'package:flutter_app/features/profile/widgets/friend_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// The main profile screen, designed to be a tab in the [HomeScreen].
///
/// Uses [GetX] to observe the [ProfileController] for user info and friends.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Find the ProfileController, which is initialized in HomeScreen's binding
    final ProfileController controller = Get.find<ProfileController>();
    
    // --- CORRECTION: REMOVED Scaffold and AppBar ---
    return RefreshIndicator(
      color: ChatHubTheme.primary,
      backgroundColor: ChatHubTheme.surface,
      // --- CORRECTION: Changed to correct public method name ---
      onRefresh: () => controller.refreshData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Profile Header ---
            Obx(() {
              if (controller.isLoading.value && // Corrected typo
                  controller.userProfile.value == null) {
                return const Center(
                  child: CircularProgressIndicator(color: ChatHubTheme.primary),
                );
              }
              final user = controller.userProfile.value;
              if (user == null) {
                return const Center(child: Text('Could not load profile.'));
              }
              return _buildProfileHeader(user);
            }),
            const SizedBox(height: 24),
            
            // --- Friends List ---
            Text(
              'Friends',
              style: Get.textTheme.titleLarge?.copyWith(
                color: ChatHubTheme.textOnSurface,
              ),
            ),
            const SizedBox(height: 10),
            Obx(() {
              if (controller.isLoading.value && // Corrected typo
                  controller.friendsList.value.isEmpty) { // Corrected typo
                return const Center(child: Text('Loading friends...'));
              }
              if (controller.friendsList.value.isEmpty) { // Corrected typo
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'You have no friends yet. Use the search icon to find users!',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ),
                );
              }
              // Use ListView.separated for a non-scrolling column
              return ListView.separated(
                shrinkWrap: true, // Important in a SingleChildScrollView
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.friendsList.value.length, // Corrected typo
                separatorBuilder: (context, index) => const Divider(
                  color: ChatHubTheme.backgroundLight,
                  height: 1,
                ),
                itemBuilder: (context, index) {
                  final friend = controller.friendsList.value[index]; // Corrected typo
                  return FriendListTile(friend: friend);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  /// Builds the top section of the profile screen.
  Widget _buildProfileHeader(UserProfile user) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(user.avatarUrl),
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            style: Get.textTheme.headlineSmall?.copyWith(
              color: ChatHubTheme.textOnSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '@${user.username}',
            style: Get.textTheme.titleMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            user.bio,
            textAlign: TextAlign.center,
            style: Get.textTheme.bodyLarge?.copyWith(
              color: ChatHubTheme.textOnSurface.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Joined: ${DateFormat.yMMMd().format(user.createdAt)}',
            style: Get.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}