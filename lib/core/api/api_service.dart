import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_app/core/config/app_constants.dart';
import 'package:flutter_app/core/services/auth_service.dart';
import 'package:flutter/foundation.dart';

/// A service class for handling all REST API communications.
/// It depends on [AuthService] to get the Firebase authentication token.
class ApiService {
  final http.Client _client;
  final AuthService _authService;

  ApiService(this._client, this._authService);

  /// Helper to get authenticated headers.
  /// Throws an [Exception] if the user is not authenticated.
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _authService.getUserToken();
    if (token == null) {
      throw Exception('User not authenticated. Please log in.');
    }
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      'Authorization': 'Bearer $token',
    };
  }

  /// Handles and decodes the HTTP response.
  /// Throws an [Exception] if the response status is not 200 or 201.
  dynamic _handleResponse(http.Response response) {
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      debugPrint('API Error: ${response.body}');
      final errorBody = jsonDecode(response.body);
      throw Exception(
          errorBody['message'] ?? 'API Error: ${response.statusCode}');
    }
  }

  /// Handles multipart request responses.
  dynamic _handleStreamedResponse(http.StreamedResponse streamedResponse) async {
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  // --- User Routes ---

  /// Registers a new user. This is a multipart request.
  /// Corresponds to: POST /user/new
  Future<Map<String, dynamic>> registerUser({
    required String name,
    required String username,
    required String email,
    required String password,
    required String bio,
    required File avatarFile, // Use File object
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.baseUrl}/user/new'),
    );

    // Add fields
    request.fields['name'] = name;
    request.fields['username'] = username;
    request.fields['email'] = email;
    request.fields['password'] = password;
    request.fields['bio'] = bio;

    // Add file
    request.files.add(
      await http.MultipartFile.fromPath('avatar', avatarFile.path),
    );

    var streamedResponse = await request.send();
    return await _handleStreamedResponse(streamedResponse);
  }

  /// Fetches the profile of the currently authenticated user.
  /// Corresponds to: GET /user/me
  Future<Map<String, dynamic>> getMyProfile() async {
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/user/me'),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response);
  }

  /// Searches for users by name.
  /// Corresponds to: GET /user/search
  Future<List<dynamic>> searchUser(String name) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/user/search?name=$name'),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response)['users'];
  }

  /// Sends a friend request to a user.
  /// Corresponds to: PUT /user/sendrequest
  Future<Map<String, dynamic>> sendFriendRequest(String userId) async {
    final response = await _client.put(
      Uri.parse('${AppConstants.baseUrl}/user/sendrequest'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({'userId': userId}),
    );
    return _handleResponse(response);
  }

  /// Accepts or rejects a friend request.
  /// Corresponds to: PUT /user/acceptrequest
  Future<Map<String, dynamic>> acceptFriendRequest({
    required String requestId,
    required bool accept,
  }) async {
    final response = await _client.put(
      Uri.parse('${AppConstants.baseUrl}/user/acceptrequest'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({'requestId': requestId, 'accept': accept}),
    );
    return _handleResponse(response);
  }

  /// Gets all pending friend requests for the user.
  /// Corresponds to: GET /user/notifications
  Future<List<dynamic>> getMyNotifications() async {
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/user/notifications'),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response)['allRequests'];
  }

  /// Gets the user's friend list.
  /// Corresponds to: GET /user/friends
  Future<List<dynamic>> getMyFriends() async {
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/user/friends'),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response)['friends'];
  }

  /// Updates the user's FCM token on the server.
  /// Corresponds to: PUT /user/fcm-token
  Future<Map<String, dynamic>> updateFcmToken(String fcmToken) async {
    final response = await _client.put(
      Uri.parse('${AppConstants.baseUrl}/user/fcm-token'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({'fcmToken': fcmToken}),
    );
    return _handleResponse(response);
  }

  // --- Chat Routes ---

  /// Creates a new group chat.
  /// Corresponds to: POST /chat/new
  Future<Map<String, dynamic>> newGroupChat({
    required String name,
    required List<String> members,
  }) async {
    final response = await _client.post(
      Uri.parse('${AppConstants.baseUrl}/chat/new'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({'name': name, 'members': members}),
    );
    return _handleResponse(response);
  }

  /// Gets all chats (1-on-1 and group) for the user.
  /// Corresponds to: GET /chat/my
  Future<List<dynamic>> getMyChats() async {
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/chat/my'),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response)['chats'];
  }

  /// Gets all groups for the user.
  /// Corresponds to: GET /chat/my/groups
  Future<List<dynamic>> getMyGroups() async {
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/chat/my/groups'),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response)['groups'];
  }

  /// Adds members to a group.
  /// Corresponds to: PUT /chat/addmembers
  Future<Map<String, dynamic>> addMembers({
    required String chatId,
    required List<String> members,
  }) async {
    final response = await _client.put(
      Uri.parse('${AppConstants.baseUrl}/chat/addmembers'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({'chatId': chatId, 'members': members}),
    );
    return _handleResponse(response);
  }

  /// Removes a member from a group.
  /// Corresponds to: PUT /chat/removemember
  Future<Map<String, dynamic>> removeMember({
    required String chatId,
    required String userId,
  }) async {
    final response = await _client.put(
      Uri.parse('${AppConstants.baseUrl}/chat/removemember'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({'chatId': chatId, 'userId': userId}),
    );
    return _handleResponse(response);
  }

  /// Leaves a group.
  /// Corresponds to: DELETE /chat/leave/:id
  Future<Map<String, dynamic>> leaveGroup(String chatId) async {
    final response = await _client.delete(
      Uri.parse('${AppConstants.baseUrl}/chat/leave/$chatId'),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response);
  }

  /// Sends attachments to a chat.
  /// Corresponds to: POST /chat/message
  Future<Map<String, dynamic>> sendAttachments({
    required String chatId,
    required List<File> files,
  }) async {
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${AppConstants.baseUrl}/chat/message'),
    );

    // Add headers (multipart headers are set automatically, but auth is needed)
    final authHeaders = await _getAuthHeaders();
    request.headers['Authorization'] = authHeaders['Authorization']!;

    // Add fields
    request.fields['chatId'] = chatId;

    // Add files
    for (var file in files) {
      request.files.add(
        await http.MultipartFile.fromPath('files', file.path),
      );
    }

    var streamedResponse = await request.send();
    return await _handleStreamedResponse(streamedResponse);
  }

  /// Gets messages for a specific chat with pagination.
  /// Corresponds to: GET /chat/message/:id
  Future<Map<String, dynamic>> getMessages(String chatId, int page) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/chat/message/$chatId?page=$page'),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response);
  }

  /// Gets the details for a specific chat.
  /// Corresponds to: GET /chat/:id
  Future<Map<String, dynamic>> getChatDetails(String chatId) async {
    final response = await _client.get(
      Uri.parse('${AppConstants.baseUrl}/chat/$chatId?populate=true'),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response);
  }

  /// Renames a group.
  /// Corresponds to: PUT /chat/:id
  Future<Map<String, dynamic>> renameGroup({
    required String chatId,
    required String name,
  }) async {
    final response = await _client.put(
      Uri.parse('${AppConstants.baseUrl}/chat/$chatId'),
      headers: await _getAuthHeaders(),
      body: jsonEncode({'name': name}),
    );
    return _handleResponse(response);
  }

  /// Deletes a chat or group.
  /// Corresponds to: DELETE /chat/:id
  Future<Map<String, dynamic>> deleteChat(String chatId) async {
    final response = await _client.delete(
      Uri.parse('${AppConstants.baseUrl}/chat/$chatId'),
      headers: await _getAuthHeaders(),
    );
    return _handleResponse(response);
  }
}

