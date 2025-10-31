import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter_app/core/config/app_constants.dart';

/// A service class for managing the Socket.io connection.
/// Uses [ChangeNotifier] to notify listeners about connection status.
class SocketService with ChangeNotifier {
  io.Socket? _socket;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  /// Exposes the raw socket instance for feature-specific listeners
  /// (e.g., ChatBloc listening for 'NEW_MESSAGE').
  io.Socket? get socket => _socket;

  /// Initiates a connection to the Socket.io server.
  /// [token] is the Firebase Auth ID token.
  /// [fcmToken] is the Firebase Cloud Messaging device token.
  void connect(String token, String fcmToken) {
    if (_socket != null && _socket!.connected) {
      debugPrint('Socket is already connected.');
      return;
    }

    _socket = io.io(AppConstants.socketUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      // Send tokens as required by the backend's `socketAuthenticator`
      'auth': {
        'token': token,
        'fcmToken': fcmToken,
      }
    });

    // --- Register Core Listeners ---

    _socket!.onConnect((_) {
      _isConnected = true;
      notifyListeners();
      debugPrint('Socket connected: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      notifyListeners();
      debugPrint('Socket disconnected');
    });

    _socket!.onConnectError((data) {
      _isConnected = false;
      notifyListeners();
      debugPrint('Socket connection error: $data');
    });

    _socket!.onError((data) => debugPrint('Socket error: $data'));

    // --- Register Global App Event Listeners ---
    // These are events that the whole app might care about.
    // Feature-specific events (like 'NEW_MESSAGE') should be
    // listened to by their respective Blocs/Controllers.

    _socket!.on('ALERT', (data) {
      debugPrint('Socket ALERT: $data');
      // Here you could use Get.snackbar or a similar global notification
      // to show the alert message.
    });
    
    _socket!.on('REFETCH_CHATS', (data) {
       debugPrint('Socket REFETCH_CHATS received');
       // This event tells the app to refresh its chat list.
       // The Riverpod provider for the chat list should be
       // invalidated here to trigger a refetch.
    });
  }

  /// Disconnects the socket.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    if (_isConnected) {
      _isConnected = false;
      notifyListeners();
    }
  }

  // --- Emitters ---

  /// Emits a 'NEW_MESSAGE' event to the server.
  void sendMessage({
    required String chatId,
    required List<String> members,
    required String message,
  }) {
    if (_socket == null || !_isConnected) {
      debugPrint('Socket not connected, cannot send message.');
      return;
    }
    _socket!.emit('NEW_MESSAGE', {
      'chatId': chatId,
      'members': members,
      'message': message,
    });
  }

  /// Emits a 'START_TYPING' event.
  void startTyping({
    required String chatId,
    required List<String> members,
  }) {
     _socket?.emit('START_TYPING', {
      'chatId': chatId,
      'members': members,
    });
  }

  /// Emits a 'STOP_TYPING' event.
  void stopTyping({
    required String chatId,
    required List<String> members,
  }) {
     _socket?.emit('STOP_TYPING', {
      'chatId': chatId,
      'members': members,
    });
  }

  @override
  void dispose() {
    disconnect();
    super.dispose();
  }
}

