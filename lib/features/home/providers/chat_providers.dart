import 'dart:async';
import 'package:flutter_app/core/api/api_service.dart';
import 'package:flutter_app/core/api/socket_service.dart';
import 'package:flutter_app/core/models/chat.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A proxy provider to make the [ApiService] (from Provider)
/// available to other Riverpod providers.
///
/// **This provider MUST be overridden in the widget tree**
/// where `ApiService` is available from `Provider`.
final apiServiceProvider = Provider<ApiService>((ref) {
  throw UnimplementedError('apiServiceProvider must be overridden');
});

/// A proxy provider to make the [SocketService] (from Provider)
/// available to other Riverpod providers.
///
/// **This provider MUST be overridden in the widget tree**
/// where `SocketService` is available from `Provider`.
final socketServiceProvider = Provider<SocketService>((ref) {
  throw UnimplementedError('socketServiceProvider must be overridden');
});

/// A stream provider that listens for the 'REFETCH_CHATS' socket event.
///
/// Other providers can `watch` this provider. When it emits a new event,
/// any providers watching it will automatically be invalidated and refetch.
final refetchChatsTriggerProvider = StreamProvider.autoDispose<void>((ref) {
  final socketService = ref.watch(socketServiceProvider);
  final controller = StreamController<void>();

  final listener = (dynamic _) {
    controller.add(null); // Emit an event to trigger refetch
  };

  // Subscribe to the socket event
  socketService.socket?.on('REFETCH_CHATS', listener);

  // On dispose, remove the listener to prevent memory leaks
  ref.onDispose(() {
    socketService.socket?.off('REFETCH_CHATS', listener);
    controller.close();
  });

  return controller.stream;
});

/// A [FutureProvider] that fetches the user's list of chats.
///
/// It automatically refetches when [refetchChatsTriggerProvider] emits.
final chatListProvider = FutureProvider.autoDispose<List<Chat>>((ref) async {
  // Watch the trigger. If it emits, this provider will re-execute.
  ref.watch(refetchChatsTriggerProvider);

  // Get the ApiService and fetch data.
  final apiService = ref.watch(apiServiceProvider);
  final chatJsonList = await apiService.getMyChats();
  
  // Parse the JSON list into a List<Chat>
  return (chatJsonList as List)
      .map((json) => Chat.fromJson(json))
      .toList();
});

/// A [FutureProvider] that fetches the user's list of groups.
///
/// It automatically refetches when [refetchChatsTriggerProvider] emits.
final myGroupsProvider = FutureProvider.autoDispose<List<GroupInfo>>((ref) async {
  // Watch the trigger. If it emits, this provider will re-execute.
  ref.watch(refetchChatsTriggerProvider);

  // Get the ApiService and fetch data.
  final apiService = ref.watch(apiServiceProvider);
  final groupJsonList = await apiService.getMyGroups();

  // Parse the JSON list into a List<GroupInfo>
  return (groupJsonList as List)
      .map((json) => GroupInfo.fromJson(json))
      .toList();
});
