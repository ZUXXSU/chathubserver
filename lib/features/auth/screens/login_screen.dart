import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/features/auth/controllers/login_controller.dart';
import 'package:flutter_app/features/auth/screens/register_screen.dart';
import 'package:flutter_app/features/auth/widgets/auth_text_field.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// The login screen UI.
///
/// This screen uses GetX to bind the UI to the [LoginController].
/// It provides email and password fields, and a login button that
/// shows a loading state.
class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  // Initialize the LoginController using Get.put()
  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  'Welcome Back',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ChatHubTheme.text,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to continue to ChatHub',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: ChatHubTheme.textSecondary,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 48),

                // Form Fields
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
                const SizedBox(height: 32),

                // Login Button
                Obx(() {
                  return SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChatHubTheme.primary,
                        foregroundColor: ChatHubTheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      onPressed:
                          controller.isLoading.isTrue ? null : controller.login,
                      child: controller.isLoading.isTrue
                          ? const CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  ChatHubTheme.onPrimary),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Link to Register
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account?",
                      style: TextStyle(color: ChatHubTheme.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        // Navigate to Register screen
                        Get.to(() => RegisterScreen(),
                            transition: Transition.rightToLeft);
                      },
                      child: const Text(
                        'Register',
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
