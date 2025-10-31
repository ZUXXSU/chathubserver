import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:flutter_app/core/api/api_service.dart';
import 'package:flutter_app/core/api/socket_service.dart';
import 'package:flutter_app/core/models/message.dart';
import 'package:flutter_app/core/models/user.dart';
import 'package:flutter_app/features/chat/bloc/chat_event.dart';
import 'package:flutter_app/features/chat/bloc/chat_state.dart';
import 'package:flutter/foundation.dart';

/// Manages the state for the [ChatScreen] using the BLoC pattern.
///
/// This BLoC handles:
/// - Loading initial messages from the API.
/// - Sending new messages via Socket.io.
/// - Listening for real-time `NEW_MESSAGE` events.
/// - Listening for `START_TYPING` and `STOP_TYPING` events.
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService apiService;
  final SocketService socketService;
  final String chatId;
  final String myUserId; // Need this to identify "my" messages

  /// Holds the *unsubscribe* function for the 'NEW_MESSAGE' event.
  Function? _messageSubscription;
  /// Holds the *unsubscribe* function for the 'START_TYPING' event.
  Function? _typingStartSubscription;
  /// Holds the *unsubscribe* function for the 'STOP_TYPING' event.
  Function? _typingStopSubscription;

  ChatBloc({
    required this.apiService,
    required this.socketService,
    required this.chatId,
    required this.myUserId,
  }) : super(ChatLoading()) {
    
    // Register event handlers
    on<LoadMessages>(_onLoadMessages);
    on<SendTextMessage>(_onSendMessage); // Corrected event name
    on<MessageReceived>(_onMessageReceived);
    on<TypingStarted>(_onTypingStarted);
    on<TypingStopped>(_onTypingStopped);

    // Listen to socket events and store the "off" function
    _messageSubscription = socketService.socket?.on('NEW_MESSAGE', (data) {
      try {
        if (data['chatId'] == chatId) {
          // --- CORRECTION 1 ---
          // Add event to BLoC stream with the raw Map data
          add(MessageReceived(data['message']));
        }
      } catch (e) {
        debugPrint('Error parsing received message: $e');
      }
    });

    _typingStartSubscription = socketService.socket?.on('START_TYPING', (data) {
      if (data['chatId'] == chatId) {
        add(const TypingStarted());
      }
    });

    _typingStopSubscription = socketService.socket?.on('STOP_TYPING', (data) {
      if (data['chatId'] == chatId) {
        add(const TypingStopped());
      }
    });

    // Load initial messages
    add(LoadMessages(chatId));
  }

  /// Handles the [LoadMessages] event.
  Future<void> _onLoadMessages(LoadMessages event, Emitter<ChatState> emit) async {
    try {
      emit(ChatLoading());
      // Assume page is part of the event, or default to 1
      final result = await apiService.getMessages(chatId, 1); // Defaulting to page 1
      final messages = Message.fromJsonList(result['messages']);
      
      emit(ChatLoaded(
        messages: messages,
        totalPages: result['totalPages'],
        currentPage: 1,
      ));
    } catch (e) {
      emit(ChatError(e.toString()));
    }
  }

  /// Handles the [SendTextMessage] event.
  void _onSendMessage(SendTextMessage event, Emitter<ChatState> emit) {
    if (event.message.trim().isEmpty) return;

    // Emit the message via Socket.io
    socketService.sendMessage(
      chatId: chatId,
      members: event.members,
      message: event.message.trim(),
    );

    // Optimistic UI update: Add the message to the state immediately.
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;
      
      // Create a temporary local message
      final optimisticMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Temp ID
        content: event.message.trim(),
        attachments: [],
        sender: MessageSender(id: myUserId, name: "Me"), // Use 'myUserId'
        chatId: chatId,
        createdAt: DateTime.now(),
      );

      final updatedMessages = List<Message>.from(currentState.messages)
        ..add(optimisticMessage);
      
      emit(currentState.copyWith(messages: updatedMessages));
    }
  }

  /// Handles the [MessageReceived] event (from socket).
  void _onMessageReceived(MessageReceived event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      final currentState = state as ChatLoaded;

      // --- CORRECTION 2 & 3 ---
      final message = Message.fromJson(event.messageData);

      if (message.sender.id == myUserId) {
        // This is an echo of our own message.
        // Find the optimistic (temporary) message and replace it.
        final index = currentState.messages.indexWhere(
          (m) => m.sender.id == myUserId && m.content == message.content
        );

        if (index != -1) {
          // Found it, replace it with the server-confirmed message
          final updatedMessages = List<Message>.from(currentState.messages);
          updatedMessages[index] = message;
          emit(currentState.copyWith(messages: updatedMessages));
        }
        // If not found, it was probably already processed. Do nothing.
      } else {
        // This is a new message from another user.
        final updatedMessages = List<Message>.from(currentState.messages)
          ..add(message);
        emit(currentState.copyWith(messages: updatedMessages));
      }
    }
  }

  /// Handles the [TypingStarted] event.
  void _onTypingStarted(TypingStarted event, Emitter<ChatState> emit) {
    if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(isOtherUserTyping: true));
    }
  }

  /// Handles the [TypingStopped] event.
  void _onTypingStopped(TypingStopped event, Emitter<ChatState> emit) {
     if (state is ChatLoaded) {
      emit((state as ChatLoaded).copyWith(isOtherUserTyping: false));
    }
  }
  
  @override
  Future<void> close() {
    // Call the stored "off" functions to unsubscribe
    _messageSubscription?.call();
    _typingStartSubscription?.call();
    _typingStopSubscription?.call();
    return super.close();
  }
}