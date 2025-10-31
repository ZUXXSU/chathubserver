import 'package:flutter_app/core/api/api_service.dart';
import 'package:flutter_app/core/api/socket_service.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/features/profile/controllers/profile_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

/// Sets up global dependencies for GetX.
///
/// This binding bridge allows GetX controllers to `Get.find()` services
/// that are being managed by the `Provider` package at the root of the app.
///
/// It also initializes controllers that need to be alive for the
/// entire app session, like [ProfileController].
class GlobalBindings extends Bindings {
  @override
  void dependencies() {
    // Use Get.context to access the Provider context
    // This context is available because GetMaterialApp is a child of MultiProvider
    final context = Get.context!;

    // --- Bridge Services from Provider to GetX ---
    // This makes the singletons from Provider available to all GetX controllers.
    // `fenix: true` ensures the service is re-created if lost.
    Get.lazyPut<AuthService>(() => context.read<AuthService>(), fenix: true);
    Get.lazyPut<ApiService>(() => context.read<ApiService>(), fenix: true);
    Get.lazyPut<SocketService>(() => context.read<SocketService>(), fenix: true);

    // --- Initialize Global GetX Controllers ---
    // Initialize the ProfileController here so it's ready when the
    // Profile tab is accessed. `permanent: true` keeps it in memory.
    Get.lazyPut<ProfileController>(() => ProfileController());
  }
}
