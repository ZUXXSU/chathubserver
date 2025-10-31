import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object> get props => [];
}

/// Event to load the initial batch of messages.
class LoadMessages extends ChatEvent {
  final String chatId;
  const LoadMessages(this.chatId);

  @override
  List<Object> get props => [chatId];
}

/// Event to send a new text message.
class SendTextMessage extends ChatEvent {
  final String message;
  final List<String> members;
  const SendTextMessage(this.message, this.members);

  @override
  List<Object> get props => [message, members];
}

/// Event triggered when a new message is received from the socket.
class MessageReceived extends ChatEvent {
  final Map<String, dynamic> messageData; // Data from Socket
  const MessageReceived(this.messageData);

  @override
  List<Object> get props => [messageData];
}

/// Event when the local user starts typing.
class StartTyping extends ChatEvent {
  final List<String> members;
  const StartTyping(this.members);
   @override
  List<Object> get props => [members];
}

/// Event when the local user stops typing.
class StopTyping extends ChatEvent {
  final List<String> members;
  const StopTyping(this.members);
   @override
  List<Object> get props => [members];
}

/// Event triggered when another user starts typing.
class TypingStarted extends ChatEvent {
  const TypingStarted();
}

/// Event triggered when another user stops typing.
class TypingStopped extends ChatEvent {
  const TypingStopped();
}
