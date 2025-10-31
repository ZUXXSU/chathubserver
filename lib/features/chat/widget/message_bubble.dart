import 'package:flutter_app/core/config/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_app/core/models/message.dart';
import 'package:intl/intl.dart';

/// A widget that displays a single chat message bubble.
class MessageBubble extends StatelessWidget {
  final Message message;
  final String currentUserId;

  const MessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final bool isMe = message.sender.id == currentUserId;
    final alignment = isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = isMe ? ChatHubTheme.primary : ChatHubTheme.surface;
    final textColor =
        isMe ? ChatHubTheme.black : ChatHubTheme.textOnSurface;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft:
                    isMe ? const Radius.circular(16) : const Radius.circular(0),
                bottomRight:
                    isMe ? const Radius.circular(0) : const Radius.circular(16),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TODO: Add sender name if it's a group chat and not me
                // if (isGroupChat && !isMe)
                //   Text(
                //     message.sender.name,
                //     style: TextStyle(
                //       fontWeight: FontWeight.bold,
                //       color: ChatHubTheme.primary,
                //       fontSize: 12,
                //     ),
                //   ),
                if (message.content.isNotEmpty)
                  Text(
                    message.content,
                    style: TextStyle(color: textColor, fontSize: 16),
                  ),
                if (message.attachments.isNotEmpty)
                  ...message.attachments.map((att) {
                    // Simple attachment placeholder
                    return Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Row(
                        children: [
                          Icon(Icons.attach_file, color: textColor, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Attachment',
                            style: TextStyle(color: textColor),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            DateFormat('h:mm a').format(message.createdAt),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
