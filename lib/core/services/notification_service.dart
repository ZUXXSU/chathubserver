import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_app/core/api/api_service.dart';
import 'package:get/get.dart';

/// Handles background message notifications.
/// This must be a top-level function (not inside a class).
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // You can perform background tasks here if needed, like data sync.
  // For now, we just print that a message was received.
  debugPrint("Handling a background message: ${message.messageId}");
  debugPrint("Title: ${message.notification?.title}");
  debugPrint("Body: ${message.notification?.body}");
}

/// Manages Firebase Cloud Messaging (FCM) setup and token retrieval.
///
/// This service handles:
/// - Initializing FCM and requesting permissions.
/// - Setting up listeners for foreground, background, and terminated messages.
/// - Retrieving the unique device FCM token to send to the backend.
/// - Handling user taps on notifications.
class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  /// Initializes FCM, requests permissions, and sets up message handlers.
  /// This should be called once when the app starts (e.g., in `main.dart`).
  Future<void> initNotifications() async {
    // Request permission from the user (required for iOS, web, macOS)
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (kDebugMode) {
      print('FCM Permission granted: ${settings.authorizationStatus}');
    }

    // --- Set up message handlers ---

    // 1. For messages received while the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');

      if (message.notification != null) {
        debugPrint(
            'Message contained a notification: ${message.notification?.title}');
        
        // TODO: Show a local notification
        // By default, FCM notifications are not shown when the app is in
        // the foreground. You'll need a package like
        // `flutter_local_notifications` to display an in-app heads-up alert.
      }
    });

    // 2. For messages received while the app is in the background or terminated
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // --- Handle notification taps ---

    // 3. When the app is opened from a terminated state by a notification
    _fcm.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });

    // 4. When the app is opened from a background state by a notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
  }

  /// Retrieves the Firebase Cloud Messaging (FCM) token for this device.
  /// This token is sent to your backend to identify this device.
  Future<String?> getFcmToken() async {
    try {
      // For web, you must provide your VAPID key.
      String? token = await _fcm.getToken(
        vapidKey: kIsWeb
            ? "AIzaSyBj3eR_62gp8kOMQmeDKe_7UsYIi2rVdNk" // From firebase_options.dart
            : null,
      );
      
      debugPrint("FCM Token: $token");

      // Listen for token refreshes and send the new token to your backend
      _fcm.onTokenRefresh.listen((newToken) {
        debugPrint("FCM Token Refreshed: $newToken");
        // Send this `newToken` to your backend API
        try {
          final apiService = Get.find<ApiService>();
          apiService.updateFcmToken(newToken);
        } catch (e) {
          debugPrint('Error updating refreshed FCM token: $e');
        }
      });

      return token;
    } catch (e) {
      debugPrint("Error getting FCM token: $e");
      return null;
    }
  }

  /// Handles logic for when a user taps on a notification.
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint("Notification Tapped!");
    debugPrint("Title: ${message.notification?.title}");
    // This is where you would navigate the user.
    // For example, if your notification data includes a `chatId`:
    //
    // final String? chatId = message.data['chatId'];
    // if (chatId != null) {
    //   Get.toNamed('/chat/$chatId');
    // }
  }
}