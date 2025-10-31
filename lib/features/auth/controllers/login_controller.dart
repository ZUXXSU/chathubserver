import 'package:flutter_app/core/api/api_service.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/core/services/notification_service.dart';
import 'package:flutter_app/core/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Manages the state and business logic for the [LoginScreen] using GetX.
///
/// This controller is responsible for:
/// 1. Handling user input for email and password.
/// 2. Orchestrating the login flow by calling `AuthService`.
/// 3. Updating the user's FCM token on the backend via `ApiService` after a
///    successful login.
/// 4. Managing the loading state (`isLoading`).
/// 5. Displaying error messages using `Helpers.showErrorSnackbar`.
class LoginController extends GetxController {
  // Find the globally provided services using Get.find()
  // This works because of the `GlobalBindings` class.
  final AuthService _authService = Get.find<AuthService>();
  final ApiService _apiService = Get.find<ApiService>();
  final NotificationService _notificationService = NotificationService();

  // Text editing controllers for the login form
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // Observable boolean for tracking loading state
  var isLoading = false.obs;

  /// Attempts to log the user in using Firebase Auth.
  /// If successful, it proceeds to get the FCM token and update the
  /// backend, before navigating to the home screen.
  Future<void> login() async {
    // Prevent multiple login attempts
    if (isLoading.isTrue) return;

    try {
      isLoading(true);

      // 1. Log in with Firebase
      await _authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      // 2. Get the device's FCM token
      // We do this *after* login to ensure the user is authenticated
      // when we send the token to our backend.
      final String? fcmToken = await _notificationService.getFcmToken();

      if (fcmToken != null) {
        // 3. Send the FCM token to our backend server
        // This is crucial for push notifications.
        await _apiService.updateFcmToken(fcmToken);
      } else {
        // Not a critical error, but good to be aware of.
        debugPrint('Could not get FCM token.');
      }

      // 4. Navigate to the home screen
      // This might also be handled by the AuthWrapper, but an explicit
      // navigation ensures the user is moved immediately.
      Get.offAllNamed('/home');
    } catch (e) {
      // 5. Show error to the user
      Helpers.showErrorSnackbar(e.toString());
    } finally {
      // 6. Ensure loading indicator is always turned off
      isLoading(false);
    }
  }

  /// Clean up text controllers when the controller is disposed.
  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
