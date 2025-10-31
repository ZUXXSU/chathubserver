import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/features/auth/controllers/register_controller.dart';
import 'package:flutter_app/features/auth/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The registration screen UI.
///
/// This screen uses GetX to bind the UI to the [RegisterController].
/// It provides text fields for user details, an avatar picker, and a
/// register button that shows a loading state.
class RegisterScreen extends StatelessWidget {
  RegisterScreen({super.key});

  // Initialize the RegisterController using Get.put()
  final RegisterController controller = Get.put(RegisterController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The theme's Scaffold background color is already set to dark
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo or Title
                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ChatHubTheme.text,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Join ChatHub today!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ChatHubTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),

                // Avatar Picker
                Center(
                  child: GestureDetector(
                    onTap: controller.pickAvatar,
                    child: Obx(() {
                      final avatar = controller.avatarFile.value;
                      return CircleAvatar(
                        radius: 50,
                        backgroundColor: ChatHubTheme.backgroundLight,
                        backgroundImage:
                            avatar != null ? FileImage(avatar) : null,
                        child: avatar == null
                            ? const Icon(
                                Icons.camera_alt,
                                color: ChatHubTheme.primary,
                                size: 40,
                              )
                            : null,
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 24),

                // Form Fields
                AuthTextField(
                  controller: controller.nameController,
                  labelText: 'Full Name',
                  icon: Icons.person,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: controller.usernameController,
                  labelText: 'Username',
                  icon: Icons.alternate_email,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: controller.emailController,
                  labelText: 'Email',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: controller.passwordController,
                  labelText: 'Password',
                  icon: Icons.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 16),
                AuthTextField(
                  controller: controller.bioController,
                  labelText: 'Bio',
                  icon: Icons.article,
                ),
                const SizedBox(height: 32),

                // Register Button
                Obx(() {
                  return SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChatHubTheme.primary,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed:
                          controller.isLoading.isTrue ? null : controller.register,
                      child: controller.isLoading.isTrue
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  ChatHubTheme.text),
                            )
                          : const Text(
                              'Register',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Link to Login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account?',
                      style: TextStyle(color: ChatHubTheme.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to Login screen
                        Get.offNamed('/login');
                      },
                      child: const Text(
                        'Log In',
                        style: TextStyle(
                          color: ChatHubTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
