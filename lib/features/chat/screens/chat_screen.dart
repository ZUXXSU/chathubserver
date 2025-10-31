import 'dart:async';
import 'package:flutter_app/core/api/api_service.dart';
import 'package:flutter_app/core/api/socket_service.dart';
import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter_app/features/chat/bloc/chat_bloc.dart';
import 'package:flutter_app/features/chat/bloc/chat_event.dart';
import 'package:flutter_app/features/chat/bloc/chat_state.dart';
import 'package:flutter_app/features/chat/widget/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Arguments from navigation
  late final String chatId;
  late final String chatName;
  late final List<String> members;
  late final String currentUserId;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    // Read arguments passed from Get.toNamed()
    final args = Get.arguments as Map<String, dynamic>;
    chatId = args['chatId'];
    chatName = args['chatName'];
    members = List<String>.from(args['members']);

    // Get current user ID from AuthService
    currentUserId = context.read<AuthService>().firebaseUser!.uid;

    _messageController.addListener(_onTyping);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTyping);
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTyping() {
    final bloc = context.read<ChatBloc>();
    if (_messageController.text.isNotEmpty) {
      // User is typing
      bloc.add(StartTyping(members));
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        // Stop typing if no input for 2 seconds
        bloc.add(StopTyping(members));
      });
    } else {
      // User stopped typing
      _typingTimer?.cancel();
      bloc.add(StopTyping(members));
    }
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    if (message.isNotEmpty) {
      context.read<ChatBloc>().add(SendTextMessage(message, members));
      _messageController.clear();
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(
        myUserId: currentUserId,
        apiService: context.read<ApiService>(),
        socketService: context.read<SocketService>(),
        chatId: chatId,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              bool isTyping = false;
              if (state is ChatLoaded) {
                isTyping = state.isOtherUserTyping;
              }
              return Column(
                children: [
                  Text(chatName),
                  if (isTyping)
                    const Text(
                      'Typing...',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                        color: Colors.grey,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: BlocBuilder<ChatBloc, ChatState>(
                builder: (context, state) {
                  if (state is ChatLoading) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: ChatHubTheme.primary,
                      ),
                    );
                  }
                  if (state is ChatError) {
                    return Center(
                      child: Text(
                        'Error: ${state.message}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  if (state is ChatLoaded) {
                    if (state.messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet.\nSay hello!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true, // To show latest messages at the bottom
                      itemCount: state.messages.length,
                      itemBuilder: (context, index) {
                        // Reversing the list for display
                        final message = state.messages.reversed.toList()[index];
                        return MessageBubble(
                          message: message,
                          currentUserId: currentUserId,
                        );
                      },
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      decoration: const BoxDecoration(
        color: ChatHubTheme.surface,
        border: Border(
          top: BorderSide(color: ChatHubTheme.backgroundLight, width: 1.0),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.grey),
            onPressed: () {
              // TODO: Handle attachment picking
            },
          ),
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: ChatHubTheme.textOnSurface),
              decoration: InputDecoration(
                hintText: 'Type a message...',
                filled: true,
                fillColor: ChatHubTheme.backgroundLight,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: const Icon(Icons.send),
            color: ChatHubTheme.primary,
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
