import 'dart:io';
import 'package:flutter_app/core/api/api_service.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/core/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

/// Manages the state for the Registration screen using GetX.
///
/// Handles form field controllers, avatar image picking,
/// and the registration logic by calling [ApiService].
class RegisterController extends GetxController {
  // Find services injected by GlobalBindings
  // We only need ApiService here for registration
  final ApiService _apiService = Get.find<ApiService>();

  // Form field controllers
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final bioController = TextEditingController();

  // State observables
  var isLoading = false.obs;
  var avatarFile = Rx<File?>(null); // Use Rx<File?> for observable
  final ImagePicker _picker = ImagePicker();

  /// Picks an image from the gallery to be used as an avatar.
  Future<void> pickAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Compress image
      );
      if (image != null) {
        avatarFile.value = File(image.path);
      }
    } catch (e) {
      Get.snackbar(
        'Image Error',
        'Failed to pick image: $e',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Attempts to register a new user.
  ///
  /// Validates form, calls the [ApiService] to register,
  /// and handles success or error UI.
  Future<void> register() async {
    if (avatarFile.value == null) {
      Get.snackbar(
        'Error',
        'Please select an avatar',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (nameController.text.isEmpty ||
        usernameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        bioController.text.isEmpty) {
      Get.snackbar(
        'Error',
        'Please fill all fields',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading(true);

      // Pass the File object directly as required by ApiService
      await _apiService.registerUser(
        name: nameController.text.trim(),
        username: usernameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        bio: bioController.text.trim(),
        avatarFile: avatarFile.value!,
      );

      // On success, show a message and pop back to the login screen
      // --- CORRECTED LINE ---
      Helpers.showSuccessSnackbar('Registration successful! Please log in.');
      Get.back(); // Go back to LoginScreen
      
    } catch (e) {
      Get.snackbar(
        'Registration Failed',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading(false);
    }
  }

  @override
  void onClose() {
    // Dispose all controllers
    nameController.dispose();
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    bioController.dispose();
    super.onClose();
  }
}