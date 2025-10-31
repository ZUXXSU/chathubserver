import 'package:equatable/equatable.dart';
import 'package:flutter_app/core/models/message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object> get props => [];
}

/// Initial state, messages are loading.
class ChatLoading extends ChatState {}

/// State when messages are successfully loaded.
class ChatLoaded extends ChatState {
  final List<Message> messages;
  final int totalPages;
  final int currentPage;
  final bool isLoadingMore;
  final bool isOtherUserTyping;

  const ChatLoaded({
    this.messages = const [],
    this.totalPages = 1,
    this.currentPage = 1,
    this.isLoadingMore = false,
    this.isOtherUserTyping = false,
  });

  ChatLoaded copyWith({
    List<Message>? messages,
    int? totalPages,
    int? currentPage,
    bool? isLoadingMore,
    bool? isOtherUserTyping,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
    );
  }

  @override
  List<Object> get props => [
        messages,
        totalPages,
        currentPage,
        isLoadingMore,
        isOtherUserTyping,
      ];
}

/// State when an error occurs.
class ChatError extends ChatState {
  final String message;
  const ChatError(this.message);

  @override
  List<Object> get props => [message];
}
