import 'package:flutter_app/core/models/user.dart';
import 'package:flutter/foundation.dart';

/// Represents an attachment within a message.
/// Based on the structure from `sendAttachments` controller.
class Attachment {
  final String publicId;
  final String url;

  Attachment({
    required this.publicId,
    required this.url,
  });

  /// Creates an [Attachment] from a JSON map.
  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      publicId: json['public_id'] ?? '',
      url: json['url'] ?? '',
    );
  }
}

/// Represents a single chat message.
/// This model is from the `GET /chat/message/:id` endpoint
/// and the real-time 'NEW_MESSAGE' socket event.
class Message {
  final String id;
  final String content;
  final String chatId;
  final MessageSender sender; // Denormalized sender info
  final DateTime createdAt;
  final List<Attachment> attachments;

  Message({
    required this.id,
    required this.content,
    required this.chatId,
    required this.sender,
    required this.createdAt,
    required this.attachments,
  });

  /// Creates a [Message] from a JSON map.
  factory Message.fromJson(Map<String, dynamic> json) {
    var attachmentList = (json['attachments'] as List<dynamic>?) ?? [];

    return Message(
      id: json['_id'] ?? '',
      content: json['content'] ?? '',
      chatId: json['chat'] ?? '',
      // Provide a default empty map to MessageSender.fromJson to avoid null errors
      sender: MessageSender.fromJson(json['sender'] ?? {}),
      // Add a null check with a fallback to the current time
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      attachments:
          attachmentList.map((i) => Attachment.fromJson(i)).toList(),
    );
  }

  /// --- ADDED THIS METHOD ---
  /// Creates a list of [Message] from a list of JSON maps.
  static List<Message> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => Message.fromJson(json)).toList();
  }
  /// --- END OF ADDED METHOD ---
}

