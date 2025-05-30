import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class ApiService {
  // Base URL for the API
  static String get baseUrl {
    // Check if running on web
    bool isWeb = identical(0, 0.0);

    if (isWeb) {
      return "https://room-expenser-tracker.vercel.app/api"; // For web
    } else {
      return "https://room-expenser-tracker.vercel.app/api"; // For Android emulator
      // Use 'http://localhost:5000/api' for iOS simulator
    }
  }

  // Headers for API requests
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Authentication methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Save token to shared preferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', data['token']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to login');
    }
  }

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
    String passwordConfirm,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'passwordConfirm': passwordConfirm,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      // Save token to shared preferences
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('token', data['token']);
      return data;
    } else {
      throw Exception(data['message'] ?? 'Failed to signup');
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
  }

  // User methods
  Future<User> getCurrentUser() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromMap(data['data']['user']);
    } else {
      throw Exception('Failed to get current user');
    }
  }

  Future<List<User>> getAllUsers() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/users'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<User>.from(
        data['data']['users'].map((user) => User.fromMap(user)),
      );
    } else {
      throw Exception('Failed to get users');
    }
  }

  Future<User> createUser(User user) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/users'),
      headers: headers,
      body: jsonEncode(user.toMap()),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return User.fromMap(data['data']['user']);
    } else {
      throw Exception('Failed to create user');
    }
  }

  Future<User> updateUser(User user) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/users/${user.id}'),
      headers: headers,
      body: jsonEncode(user.toMap()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return User.fromMap(data['data']['user']);
    } else {
      throw Exception('Failed to update user');
    }
  }

  Future<void> deleteUser(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/users/$id'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete user');
    }
  }

  // Expense methods
  Future<List<Expense>> getAllExpenses() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/expenses'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Expense>.from(
        data['data']['expenses'].map((expense) => Expense.fromMap(expense)),
      );
    } else {
      throw Exception('Failed to get expenses');
    }
  }

  Future<List<Expense>> getMyExpenses() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/expenses/my-expenses'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return List<Expense>.from(
        data['data']['expenses'].map((expense) => Expense.fromMap(expense)),
      );
    } else {
      throw Exception('Failed to get my expenses');
    }
  }

  Future<Expense> createExpense(Expense expense) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/expenses'),
      headers: headers,
      body: jsonEncode(expense.toMap()),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return Expense.fromMap(data['data']['expense']);
    } else {
      throw Exception('Failed to create expense');
    }
  }

  Future<Expense> updateExpense(Expense expense) async {
    final headers = await _getHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/expenses/${expense.id}'),
      headers: headers,
      body: jsonEncode(expense.toMap()),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Expense.fromMap(data['data']['expense']);
    } else {
      throw Exception('Failed to update expense');
    }
  }

  Future<void> deleteExpense(int id) async {
    final headers = await _getHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl/expenses/$id'),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to delete expense');
    }
  }

  // Summary methods
  Future<MonthlySummary> getMonthlySummary(int month, int year) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/summary/monthly?month=$month&year=$year'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final summary = data['data']['summary'];

      // Convert userExpenses from array to map
      Map<int, double> userExpensesMap = {};
      for (var userExpense in summary['userExpenses']) {
        userExpensesMap[userExpense['userId']] =
            userExpense['spent'].toDouble();
      }

      return MonthlySummary(
        month: summary['month'],
        year: summary['year'],
        totalAmount: summary['totalAmount'].toDouble(),
        userCount: summary['userCount'],
        perHeadAmount: summary['perHeadAmount'].toDouble(),
        userExpenses: userExpensesMap,
      );
    } else {
      throw Exception('Failed to get monthly summary');
    }
  }
}
