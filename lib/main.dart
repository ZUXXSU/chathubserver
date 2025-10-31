import 'package:flutter_app/app.dart';
import 'package:flutter_app/core/api/api_service.dart';
import 'package:flutter_app/core/api/socket_service.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/core/services/notification_service.dart';
import 'package:flutter_app/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' as river;
// import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

/// The main entry point for the ChatHub application.
///
/// This function initializes:
/// 1. Firebase Core
/// 2. Firebase Cloud Messaging (via [NotificationService])
/// 3. Global services for ([AuthService], [SocketService], [ApiService])
/// 4. The root [ProviderScope] for [Riverpod].
///
/// It then runs the root [App] widget.
void main() async {
  // Ensure Flutter bindings are initialized before async calls
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Firebase Cloud Messaging and request permissions
  await NotificationService().initNotifications();

  // --- Initialize Global Services ---
  // These services will be provided to the entire widget tree
  // and will be accessible by all other state managers.
  
  // 1. AuthService is the source of truth for auth state
  final authService = AuthService();
  
  // 2. SocketService manages the real-time connection
  final socketService = SocketService();
  
  // 3. ApiService handles all REST requests and needs AuthService for tokens
  final apiService = ApiService(http.Client(), authService);
  
  // 4. NotificationService needs ApiService to update the token on the backend
  // We can call this right after ApiService is created.
  // We'll pass ApiService to the NotificationService for this purpose.
  // Let's refine NotificationService to accept ApiService.
  // For now, we'll assume NotificationService can find ApiService via GetX
  // or we'll update it later. Let's stick to the plan:
  // The LoginController will be responsible for updating the FCM token.

  runApp(
    // 1. Riverpod Scope
    // This allows all Riverpod providers to function.
    river.ProviderScope(
      child:
          // 2. Provider Scope (for global services)
          // This makes your core services available to the entire app
          // via `context.read<T>()`.
          MultiProvider(
        providers: [
          // Provides the auth state (e.g., isAuthenticated)
          ChangeNotifierProvider(create: (_) => authService),
          
          // Provides the socket connection state
          ChangeNotifierProvider(create: (_) => socketService),
          
          // Provides the API client
          Provider(create: (_) => apiService),
          
          // Provides the notification service
          Provider(create: (_) => NotificationService()),
        ],
        child: const App(), // Your root GetMaterialApp widget
      ),
    ),
  );
}
