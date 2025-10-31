import 'package:flutter_app/core/api/api_service.dart';
import 'package:flutter_app/core/models/user.dart';
import 'package:flutter_app/core/utils/helpers.dart';
import 'package:get/get.dart';
import 'dart:async';

/// Manages the state for the User Search screen using GetX.
class CustomSearchController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();

  var isLoading = false.obs;
  var searchResults = <PopulatedUser>[].obs;
  var hasSearched = false.obs; // To show "no results" message

  // Debouncer to prevent API calls on every keystroke
  Timer? _debounce;

  /// Searches for users with debouncing.
  void searchUser(String query) {
    // Clear results if query is empty
    if (query.isEmpty) {
      searchResults.clear();
      hasSearched.value = false;
      return;
    }

    // Cancel the previous debounce timer
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    // Start a new timer
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        isLoading(true);
        hasSearched.value = true;
        final jsonList = await _apiService.searchUser(query);
        searchResults.value = PopulatedUser.fromJsonList(jsonList);
      } catch (e) {
        Get.snackbar('Search Error', 'Failed to find users: $e');
      } finally {
        isLoading(false);
      }
    });
  }

  /// Sends a friend request to a user.
  Future<void> sendRequest(String userId, String name) async {
    try {
      // Show a loading dialog or disable button (not shown here)
      await _apiService.sendFriendRequest(userId);
      Helpers.showSuccessSnackbar('Friend request sent to $name');
      
      // Optionally, remove user from search results to prevent re-adding
      searchResults.removeWhere((user) => user.id == userId);
      
    } catch (e) {
      Get.snackbar('Error', 'Failed to send request: $e');
    }
  }

  @override
  void onClose() {
    _debounce?.cancel();
    super.onClose();
  }
}
