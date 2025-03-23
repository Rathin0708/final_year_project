import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_data_model.dart';

class ApiService {
  static const String baseUrl = 'https://67d9262600348dd3e2a9d318.mockapi.io/api/v1';
  static const String usersEndpoint = '/Userdata';

  // Fetch all users
  Future<List<UserDataModel>> getUsers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$usersEndpoint'));
      
      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        return jsonData.map((userData) => UserDataModel.fromJson(userData)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // Fetch single user by ID
  Future<UserDataModel> getUserById(String id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl$usersEndpoint/$id'));
      
      if (response.statusCode == 200) {
        return UserDataModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching user: $e');
    }
  }

  // Create a new user
  Future<UserDataModel> createUser(UserDataModel user) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$usersEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );
      
      if (response.statusCode == 201) {
        return UserDataModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating user: $e');
    }
  }

  // Update user
  Future<UserDataModel> updateUser(String id, UserDataModel user) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$usersEndpoint/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(user.toJson()),
      );
      
      if (response.statusCode == 200) {
        return UserDataModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to update user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating user: $e');
    }
  }

  // Delete user
  Future<bool> deleteUser(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl$usersEndpoint/$id'));
      
      if (response.statusCode == 200) {
        return true;
      } else {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting user: $e');
    }
  }
}