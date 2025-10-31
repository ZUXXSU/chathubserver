import 'package:flutter_app/core/api/socket_service.dart';
import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/core/services/notification_service.dart';
import 'package:flutter_app/features/home/screens/chat_list_tab.dart';
import 'package:flutter_app/features/home/screens/groups_list_tab.dart';
import 'package:flutter_app/features/profile/controllers/profile_controller.dart';
import 'package:flutter_app/features/profile/screens/notifications_screen.dart';
import 'package:flutter_app/features/profile/screens/profile_screen.dart';
import 'package:flutter_app/features/profile/screens/search_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- CORRECTION 1 ---
  final List<Widget> _tabs = [
    const ChatListTab(),
    const GroupsListTab(),
    const ProfileScreen(), // Use the real profile screen
  ];
  // --- END CORRECTION ---

  @override
  void initState() {
    super.initState();
    _connectServices();
  }

  /// Connects to Socket.io and updates the FCM token
  void _connectServices() async {
    // Use context.read inside initState as it's a one-time call
    final authService = context.read<AuthService>();
    final socketService = context.read<SocketService>();

    // Get auth token
    final token = await authService.getUserToken();
    
    // Get FCM token
    final fcmToken = await NotificationService().getFcmToken();

    if (token != null && fcmToken != null) {
      // Connect to socket
      socketService.connect(token, fcmToken);

      // NOTE: FCM token is updated on the server via LoginController
      // and NotificationService's onTokenRefresh. No need to do it here.
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- CORRECTION 4 & 5 ---
  /// Actions for the Chat and Groups tabs
  List<Widget> _buildChatActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          Get.to(() => const SearchScreen());
        },
      ),
      IconButton(
        icon: const Icon(Icons.add),
        onPressed: () {
          // TODO: Navigate to create new chat/group screen
        },
      ),
    ];
  }

  /// Actions for the Profile tab
  List<Widget> _buildProfileActions(BuildContext context) {
    // Find controllers/services needed for actions
    final ProfileController controller = Get.find<ProfileController>();
    final AuthService authService = context.read<AuthService>();

    return [
      // Notifications Button
      IconButton(
        icon: Obx(() {
          // --- CORRECTION 6 (typo fix) ---
          final count = controller.notificationList.value.length;
          return Badge(
            label: Text(count.toString()),
            isLabelVisible: count > 0,
            child: const Icon(Icons.notifications_outlined),
          );
        }),
        onPressed: () {
          Get.to(() => const NotificationsScreen());
        },
      ),
      // Search Button
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          Get.to(() => const SearchScreen());
        },
      ),
      // Logout Button
      IconButton(
        icon: const Icon(Icons.logout, color: Colors.redAccent),
        onPressed: () {
          Get.defaultDialog(
            title: 'Logout',
            titleStyle: const TextStyle(color: ChatHubTheme.textOnSurface),
            middleText: 'Are you sure you want to log out?',
            middleTextStyle: const TextStyle(color: ChatHubTheme.textOnSurface),
            backgroundColor: ChatHubTheme.surface,
            buttonColor: ChatHubTheme.primary,
            textConfirm: 'Logout',
            textCancel: 'Cancel',
            confirmTextColor: ChatHubTheme.textOnPrimary,
            cancelTextColor: ChatHubTheme.textOnSurface,
            onConfirm: () {
              authService.logout();
              Get.back(); // Close dialog
            },
          );
        },
      ),
    ];
  }
  // --- END CORRECTION ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedIndex == 0 ? 'Chats' : _selectedIndex == 1 ? 'Groups' : 'Profile'),
        // --- CORRECTION 4 ---
        actions: _selectedIndex == 2
            ? _buildProfileActions(context)
            : _buildChatActions(context),
        // --- END CORRECTION ---
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.group),
            label: 'Groups',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      // --- CORRECTION 3 ---
      // Removed FloatingActionButton as it's now in the AppBar
      // --- END CORRECTION ---
    );
  }
}

// --- CORRECTION 2 ---
// Removed the ProfilePlaceholderTab class as it's no longer used
// --- END CORRECTION ---