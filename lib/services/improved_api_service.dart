import 'package:flutter/foundation.dart';

import '../models/models.dart';
import 'api_client.dart';

class ImprovedApiService {
  final ApiClient _client = ApiClient();

  // Authentication methods
  Future<ApiResponse<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    final response = await _client.post<Map<String, dynamic>>('/auth/login', {
      'email': email,
      'password': password,
    }, (json) => json);

    if (response.success && response.data != null) {
      final token = response.data!['token'];
      if (token != null) {
        await _client.saveToken(token);
      }

      // Check if user is admin
      final isAdmin = response.data!['data']['isAdmin'] ?? false;
      debugPrint('User is admin: $isAdmin');

      // Store admin status
      _client.isAdmin = isAdmin;
    }

    return response;
  }

  Future<ApiResponse<Map<String, dynamic>>> signup(
    String name,
    String email,
    String password,
    String passwordConfirm,
  ) async {
    debugPrint('Signup request: name=$name, email=$email');

    final requestBody = {
      'name': name,
      'email': email,
      'password': password,
      'passwordConfirm': passwordConfirm,
    };

    debugPrint('Sending signup request with body: $requestBody');

    final response = await _client.post<Map<String, dynamic>>(
      '/auth/signup',
      requestBody,
      (json) => json,
    );

    debugPrint(
      'Signup response: success=${response.success}, error=${response.error}',
    );

    if (response.success && response.data != null) {
      debugPrint('Signup successful, saving token');
      final token = response.data!['token'];
      if (token != null) {
        await _client.saveToken(token);
      }
    } else {
      debugPrint('Signup failed: ${response.error}');
    }

    return response;
  }

  Future<void> logout() async {
    await _client.clearToken();
  }

  // Update password
  Future<ApiResponse<Map<String, dynamic>>> updatePassword(
    String currentPassword,
    String newPassword,
    String newPasswordConfirm,
  ) async {
    debugPrint('Updating password');

    final requestBody = {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
      'newPasswordConfirm': newPasswordConfirm,
    };

    final response = await _client.patch<Map<String, dynamic>>(
      '/auth/update-password',
      requestBody,
      (json) => json,
    );

    debugPrint(
      'Update password response: success=${response.success}, error=${response.error}',
    );

    if (response.success && response.data != null) {
      debugPrint('Password updated successfully, saving new token');
      final token = response.data!['token'];
      if (token != null) {
        await _client.saveToken(token);
      }
    } else {
      debugPrint('Password update failed: ${response.error}');
    }

    return response;
  }

  // User methods
  Future<ApiResponse<User>> getCurrentUser() async {
    return await _client.get<User>(
      '/users/me',
      (json) => User.fromMap(json['data']['user']),
    );
  }

  Future<ApiResponse<List<User>>> getAllUsers() async {
    final response = await _client.get<Map<String, dynamic>>(
      '/users',
      (json) => json,
    );

    if (response.success && response.data != null) {
      final users = List<User>.from(
        response.data!['data']['users'].map((user) => User.fromMap(user)),
      );

      // Check if currentUser is included in the response
      if (response.data!['data']['currentUser'] != null) {
        final currentUser = User.fromMap(response.data!['data']['currentUser']);
        debugPrint(
          'Current user from API: ${currentUser.name}, isAdmin: ${currentUser.isAdmin}',
        );

        // Make sure the current user is in the list
        if (!users.any((user) => user.id == currentUser.id)) {
          users.add(currentUser);
          debugPrint('Added current user to the list');
        }
      }

      return ApiResponse.success(users);
    } else {
      return ApiResponse.error(response.error ?? 'Failed to load users');
    }
  }

  Future<ApiResponse<User>> createUser(User user) async {
    return await _client.post<User>(
      '/users',
      user.toMap(),
      (json) => User.fromMap(json['data']['user']),
    );
  }

  Future<ApiResponse<User>> updateUser(User user) async {
    return await _client.patch<User>(
      '/users/${user.id}',
      user.toMap(),
      (json) => User.fromMap(json['data']['user']),
    );
  }

  // Update current user's profile
  Future<ApiResponse<User>> updateProfile(User user) async {
    return await _client.patch<User>(
      '/users/updateMe',
      user.toMap(),
      (json) => User.fromMap(json['data']['user']),
    );
  }

  Future<ApiResponse<bool>> deleteUser(dynamic id) async {
    return await _client.delete('/users/$id');
  }

  // Expense methods
  Future<ApiResponse<List<Expense>>> getAllExpenses() async {
    return await _client.get<List<Expense>>(
      '/expenses',
      (json) => List<Expense>.from(
        json['data']['expenses'].map((expense) => Expense.fromMap(expense)),
      ),
    );
  }

  Future<ApiResponse<List<Expense>>> getMyExpenses() async {
    return await _client.get<List<Expense>>(
      '/expenses/my-expenses',
      (json) => List<Expense>.from(
        json['data']['expenses'].map((expense) => Expense.fromMap(expense)),
      ),
    );
  }

  Future<ApiResponse<List<Expense>>> getExpensesByUser(dynamic userId) async {
    return await _client.get<List<Expense>>(
      '/expenses/user/$userId',
      (json) => List<Expense>.from(
        json['data']['expenses'].map((expense) => Expense.fromMap(expense)),
      ),
    );
  }

  Future<ApiResponse<List<Expense>>> getExpensesByMonth(
    int month,
    int year,
  ) async {
    return await _client.get<List<Expense>>(
      '/expenses?month=$month&year=$year',
      (json) => List<Expense>.from(
        json['data']['expenses'].map((expense) => Expense.fromMap(expense)),
      ),
    );
  }

  Future<ApiResponse<Expense>> createExpense(Expense expense) async {
    return await _client.post<Expense>(
      '/expenses',
      expense.toMap(),
      (json) => Expense.fromMap(json['data']['expense']),
    );
  }

  Future<ApiResponse<Expense>> updateExpense(Expense expense) async {
    return await _client.patch<Expense>(
      '/expenses/${expense.id}',
      expense.toMap(),
      (json) => Expense.fromMap(json['data']['expense']),
    );
  }

  Future<ApiResponse<bool>> deleteExpense(dynamic id) async {
    return await _client.delete('/expenses/$id');
  }

  // Summary methods
  Future<ApiResponse<MonthlySummary>> getMonthlySummary(
    int month,
    int year,
  ) async {
    return await _client.get<MonthlySummary>(
      '/summary/monthly?month=$month&year=$year',
      (json) {
        final summary = json['data']['summary'];

        // Convert userExpenses from array to map
        Map<dynamic, double> userExpensesMap = {};
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
      },
    );
  }
}
