import 'package:flutter/foundation.dart';

/// Represents the full profile of the logged-in user.
/// This model is from the `GET /user/me` endpoint.
class UserProfile {
  final String id;
  final String name;
  final String username;
  final String bio;
  final String avatarUrl;
  final String avatarPublicId;
  final String? fcmToken;
  final DateTime createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.username,
    required this.bio,
    required this.avatarUrl,
    required this.avatarPublicId,
    this.fcmToken,
    required this.createdAt,
  });

  /// Creates a [UserProfile] from a JSON map.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> avatarData = json['avatar'] ?? {};
    return UserProfile(
      id: json['_id'],
      name: json['name'] ?? 'No Name',
      username: json['username'] ?? 'no_username',
      bio: json['bio'] ?? '',
      avatarUrl: avatarData['url'] ?? '',
      avatarPublicId: avatarData['public_id'] ?? '',
      fcmToken: json['fcmToken'],
      // Added null check for safety
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

/// Represents a populated user object with minimal details.
/// Used in chat details, search results, and friend lists.
class PopulatedUser {
  final String id;
  final String name;
  final String avatar;

  PopulatedUser({
    required this.id,
    required this.name,
    required this.avatar,
  });

  /// Creates a [PopulatedUser] from a JSON map.
  /// Handles both flat avatar URLs (from search) and nested avatar objects.
  factory PopulatedUser.fromJson(Map<String, dynamic> json) {
    dynamic avatarData = json['avatar'];
    String avatarUrl = '';

    if (avatarData is String) {
      // Handles 'avatar' being just a URL string
      avatarUrl = avatarData;
    } else if (avatarData is Map) {
      // Handles 'avatar' being a {'url': '...', 'public_id': '...'} map
      avatarUrl = avatarData['url'] ?? '';
    }

    return PopulatedUser(
      id: json['_id'],
      name: json['name'] ?? 'Unknown User',
      avatar: avatarUrl,
    );
  }

  /// --- ADDED THIS METHOD ---
  /// Creates a list of [PopulatedUser] from a list of JSON maps.
  static List<PopulatedUser> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((json) => PopulatedUser.fromJson(json)).toList();
  }
  /// --- END OF ADDED METHOD ---
}

/// Represents the denormalized sender info stored inside a Message object.
class MessageSender {
  final String id;
  final String name;

  MessageSender({
    required this.id,
    required this.name,
  });

  /// Creates a [MessageSender] from a JSON map.
  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: json['_id'],
      name: json['name'] ?? 'Unknown',
    );
  }
}

