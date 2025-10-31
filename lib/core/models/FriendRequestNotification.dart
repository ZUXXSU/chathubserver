import 'package:flutter_app/core/models/user.dart';

/// Represents a friend request notification.
/// This model is from the `GET /user/notifications` endpoint.
class FriendRequestNotification {
  final String id;
  final PopulatedUser sender;

  FriendRequestNotification({
    required this.id,
    required this.sender,
  });

  /// Creates a [FriendRequestNotification] from a JSON map.
  factory FriendRequestNotification.fromJson(Map<String, dynamic> json) {
    return FriendRequestNotification(
      id: json['_id'],
      sender: PopulatedUser.fromJson(json['sender']),
    );
  }

  /// Creates a list of [FriendRequestNotification] from a list of JSON maps.
  static List<FriendRequestNotification> fromJsonList(List<dynamic> jsonList) {
    return jsonList
        .map((json) => FriendRequestNotification.fromJson(json))
        .toList();
  }
}

