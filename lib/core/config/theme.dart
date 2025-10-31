import 'package:flutter/material.dart';

// Colors based on the provided logo
const Color kPrimaryColor = Color(0xFFF9A825); // Logo Orange
const Color kBackgroundColor = Color(0xFF000000); // Logo Black
const Color kOnBackgroundColor = Color(0xFFFFFFFF); // Logo White
const Color kSurfaceColor = Color(0xFF1A1A1A); // A slightly lighter black for cards

class ChatHubTheme {
  // --- Primary Colors ---
  static const Color primary = Color(0xFFF9A825); // Logo Orange
  static const Color background = Color(0xFF000000); // Logo Black
  static const Color surface = Color(0xFF1A1A1A); // Lighter black for cards/fields
  static const Color backgroundLight = Color(0xFF2C2C2C); // Lighter bg for containers
  static const Color black = Color(0xFF000000); // Added for clarity

  // --- Text Colors ---
  static const Color text = Color(0xFFFFFFFF); // Logo White (for headlines, body)
  static const Color textSecondary = Color(0xFFBDBDBD); // Grey (for labels, subtext)
  static const Color textOnSurface = Color(0xFFFFFFFF); // Alias for 'text'
  static const Color onText = Color(0xFFFFFFFF); // (Kept for compatibility)

  // --- Button Text Colors ---
  static const Color onPrimary = Color(0xFF000000); // Black text on orange buttons
  static const Color textOnPrimary = Color(0xFF000000); // Alias for 'onPrimary'

  // --- Other ---
  static const Color error = Colors.redAccent;
}

/// The main dark theme data for the application.
/// References colors from the [ChatHubTheme] class.
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: ChatHubTheme.primary,
  scaffoldBackgroundColor: ChatHubTheme.background,

  colorScheme: const ColorScheme(
    brightness: Brightness.dark,
    primary: ChatHubTheme.primary,
    onPrimary: ChatHubTheme.onPrimary, // Text on primary buttons (black)
    secondary: ChatHubTheme.primary, // Can be the same as primary
    onSecondary: ChatHubTheme.onPrimary, // Text on secondary buttons (black)
    background: ChatHubTheme.background,
    onBackground: ChatHubTheme.text, // Main app text color (white)
    surface: ChatHubTheme.surface, // Color for cards, dialogs, etc.
    onSurface: ChatHubTheme.text, // Text on cards (white)
    error: ChatHubTheme.error,
    onError: ChatHubTheme.onText,
  ),

  // --- Component Themes ---

  appBarTheme: const AppBarTheme(
    backgroundColor: ChatHubTheme.surface,
    elevation: 0,
    centerTitle: true,
    titleTextStyle: TextStyle(
      color: ChatHubTheme.text,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
    iconTheme: IconThemeData(color: ChatHubTheme.text),
  ),

  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: ChatHubTheme.text),
    bodyMedium: TextStyle(color: ChatHubTheme.text),
    titleLarge: TextStyle(color: ChatHubTheme.text, fontWeight: FontWeight.bold),
    labelMedium: TextStyle(color: ChatHubTheme.textSecondary),
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: ChatHubTheme.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: ChatHubTheme.primary),
    ),
    labelStyle: const TextStyle(color: ChatHubTheme.textSecondary),
    hintStyle: TextStyle(color: Colors.grey[700]),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: ChatHubTheme.primary,
      foregroundColor: ChatHubTheme.onPrimary, // Text color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
    ),
  ),

  floatingActionButtonTheme: const FloatingActionButtonThemeData(
    backgroundColor: ChatHubTheme.primary,
    foregroundColor: ChatHubTheme.onPrimary,
  ),

  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: ChatHubTheme.primary,
    ),
  ),

  listTileTheme: const ListTileThemeData(
    tileColor: Colors.transparent,
    textColor: ChatHubTheme.text,
    iconColor: ChatHubTheme.text,
  ),

  tabBarTheme: const TabBarThemeData(
    labelColor: ChatHubTheme.primary,
    unselectedLabelColor: ChatHubTheme.textSecondary,
    indicatorColor: ChatHubTheme.primary,
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: ChatHubTheme.surface,
    selectedItemColor: ChatHubTheme.primary,
    unselectedItemColor: ChatHubTheme.textSecondary,
    showUnselectedLabels: false,
  ),
);
