import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

/// A utility class for common helper functions.
class Helpers {
  /// Shows a standardized error snackbar using GetX.
  static void showErrorSnackbar(String message) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    Get.snackbar(
      'Error',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red.shade800,
      colorText: Colors.white,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
    );
  }

  /// Shows a standardized success snackbar using GetX.
  static void showSuccessSnackbar(String message) {
    if (Get.isSnackbarOpen) {
      Get.closeCurrentSnackbar();
    }
    Get.snackbar(
      'Success',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: ChatHubTheme.primary,
      colorText: ChatHubTheme.text,
      margin: const EdgeInsets.all(10),
      borderRadius: 8,
    );
  }

  /// Formats a [DateTime] object into a user-friendly string.
  ///
  /// Example: "10:30 AM" or "Yesterday" or "28/10/2025"
  static String formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);

    final dateToFormat =
        DateTime(timestamp.year, timestamp.month, timestamp.day);

    if (dateToFormat == today) {
      // Today: Show time
      return DateFormat.jm().format(timestamp); // e.g., "5:08 PM"
    } else if (dateToFormat == yesterday) {
      // Yesterday: Show "Yesterday"
      return 'Yesterday';
    } else {
      // Older: Show date
      return DateFormat.yMd().format(timestamp); // e.g., "10/28/2025"
    }
  }

  /// Formats a [DateTime] object specifically for chat message timestamps.
  static String formatChatMessageTime(DateTime timestamp) {
    // Just returns the time, e.g., "10:30 AM"
    return DateFormat.jm().format(timestamp);
  }
}
