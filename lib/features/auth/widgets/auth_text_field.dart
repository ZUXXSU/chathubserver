import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter/material.dart';

/// A reusable text field widget styled for the auth screens (Login/Register).
/// It uses the ChatHub dark theme.
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData icon;
  final bool isPassword;
  final TextInputType keyboardType;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.icon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      style: const TextStyle(color: ChatHubTheme.text),
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: const TextStyle(color: ChatHubTheme.textSecondary),
        prefixIcon: Icon(icon, color: ChatHubTheme.primary),
        // Enabled border
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: ChatHubTheme.textSecondary, width: 1.0),
        ),
        // Focused border
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: ChatHubTheme.primary, width: 2.0),
        ),
        // Error border
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        // Focused error border
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
        ),
        filled: true,
        fillColor: ChatHubTheme.backgroundLight,
      ),
    );
  }
}
