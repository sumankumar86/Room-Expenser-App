import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiResponse<T> {
  final T? data;
  final String? error;
  final bool success;

  ApiResponse({this.data, this.error, required this.success});

  factory ApiResponse.success(T data) {
    return ApiResponse(data: data, success: true);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse(error: error, success: false);
  }
}

class ApiClient {
  // Base URL for the API
  static String get baseUrl {
    if (kIsWeb) {
      return 'https://room-expenser-tracker.vercel.app/api'; // For web
    } else if (Platform.isAndroid) {
      // For Android devices
      // Use 10.0.2.2 for emulator or your computer's IP address for physical devices
      // For physical devices, replace with your computer's IP address
      return 'https://room-expenser-tracker.vercel.app/api'; // For Android emulator
      // If using a physical device, uncomment the line below and replace with your computer's IP address
      // return 'http://192.168.0.101:5000/api'; // Replace with your computer's IP address
    } else {
      return 'https://room-expenser-tracker.vercel.app/api'; // For iOS simulator or desktop
    }
  }

  // Singleton pattern
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  // Token storage
  String? _token;
  bool _isInitialized = false;
  bool _isAdmin = false;

  // Getter and setter for admin status
  bool get isAdmin => _isAdmin;
  set isAdmin(bool value) => _isAdmin = value;

  // Initialize the client
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('token');
      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing ApiClient: $e');
      // Continue without token
      _isInitialized = true;
    }
  }

  // Get headers for API requests
  Future<Map<String, String>> _getHeaders() async {
    await init();

    // For development, always include a test token if no real token exists
    final token = _token ?? 'test-token-for-development';

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Save token
  Future<void> saveToken(String token) async {
    try {
      _token = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  // Clear token
  Future<void> clearToken() async {
    try {
      _token = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    } catch (e) {
      debugPrint('Error clearing token: $e');
    }
  }

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(fromJson(data));
      } else {
        final error = _parseError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint,
    dynamic body,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl$endpoint';

      debugPrint('POST request to $url');
      debugPrint('Headers: $headers');
      debugPrint('Body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(fromJson(data));
      } else {
        final error = _parseError(response);
        debugPrint('Error response: $error');
        return ApiResponse.error(error);
      }
    } catch (e) {
      debugPrint('Network error: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // Generic PATCH request
  Future<ApiResponse<T>> patch<T>(
    String endpoint,
    dynamic body,
    T Function(dynamic json) fromJson,
  ) async {
    try {
      final headers = await _getHeaders();
      final url = '$baseUrl$endpoint';

      debugPrint('PATCH request to $url');
      debugPrint('Headers: $headers');
      debugPrint('Body: ${jsonEncode(body)}');

      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        return ApiResponse.success(fromJson(data));
      } else {
        final error = _parseError(response);
        debugPrint('Error response: $error');
        return ApiResponse.error(error);
      }
    } catch (e) {
      debugPrint('Network error: $e');
      return ApiResponse.error('Network error: $e');
    }
  }

  // Generic DELETE request
  Future<ApiResponse<bool>> delete(String endpoint) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(true);
      } else {
        final error = _parseError(response);
        return ApiResponse.error(error);
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Parse error from response
  String _parseError(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      return data['message'] ?? 'Unknown error';
    } catch (e) {
      return 'Error ${response.statusCode}: ${response.reasonPhrase}';
    }
  }
}
