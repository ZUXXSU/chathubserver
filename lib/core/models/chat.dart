

import 'package:flutter_app/core/models/user.dart';

class ChatListItem {
  final String id;
  final bool groupChat;
  final List<String> avatar; // List of avatar URLs
  final String name;
  final List<String> members; // List of member IDs (other members)

  ChatListItem({
    required this.id,
    required this.groupChat,
    required this.avatar,
    required this.name,
    required this.members,
  });

  /// Creates a [ChatListItem] from a JSON map.
  factory ChatListItem.fromJson(Map<String, dynamic> json) {
    return ChatListItem(
      id: json['_id'],
      groupChat: json['groupChat'] ?? false,
      avatar: json['avatar'] != null
          ? List<String>.from(json['avatar'].map((item) => item.toString()))
          : [],
      name: json['name'] ?? 'Chat',
      members: json['members'] != null
          ? List<String>.from(json['members'].map((item) => item.toString()))
          : [],
    );
  }
}

/// Represents the detailed view of a chat with populated members.
/// This model is from the `GET /chat/:id?populate=true` endpoint.
class ChatDetails {
  final String id;
  final bool groupChat;
  final String name;
  final String creator; // Creator's ID
  final List<PopulatedUser> members; // List of populated user objects

  ChatDetails({
    required this.id,
    required this.groupChat,
    required this.name,
    required this.creator,
    required this.members,
  });

  /// Creates a [ChatDetails] from a JSON map.
  factory ChatDetails.fromJson(Map<String, dynamic> json) {
    var memberList = (json['members'] as List<dynamic>?) ?? [];
    return ChatDetails(
      id: json['_id'],
      groupChat: json['groupChat'] ?? false,
      name: json['name'] ?? 'Chat',
      creator: json['creator'] ?? '',
      members:
          memberList.map((i) => PopulatedUser.fromJson(i)).toList(),
    );
  }
}
class Chat {
  final String id;
  final String name;
  final bool groupChat;
  final List<String> members; // List of member IDs
  final List<String> avatar; // List of avatar URLs

  Chat({
    required this.id,
    required this.name,
    required this.groupChat,
    required this.members,
    required this.avatar,
  });

  /// Creates a [Chat] from a JSON map.
  factory Chat.fromJson(Map<String, dynamic> json) {
    return Chat(
      id: json['_id'],
      name: json['name'] ?? 'Unknown Chat',
      groupChat: json['groupChat'] ?? false,
      members: List<String>.from(json['members'] ?? []),
      avatar: List<String>.from(json['avatar'] ?? []),
    );
  }
}

class GroupInfo {
  final String id;
  final String name;
  final bool groupChat;
  final List<String> avatar; // List of avatar URLs

  GroupInfo({
    required this.id,
    required this.name,
    required this.groupChat,
    required this.avatar,
  });

  /// Creates a [GroupInfo] from a JSON map.
  factory GroupInfo.fromJson(Map<String, dynamic> json) {
    return GroupInfo(
      id: json['_id'],
      name: json['name'] ?? 'Unknown Group',
      groupChat: json['groupChat'] ?? true,
      avatar: List<String>.from(json['avatar'] ?? []),
    );
  }
}

