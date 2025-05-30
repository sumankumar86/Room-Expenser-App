import 'dart:math';

import '../models/models.dart';
import 'api_client.dart';

class MockApiService {
  // Mock data
  final List<User> _users = [];
  final List<Expense> _expenses = [];
  String? _token;
  int _userId = 1;
  int _expenseId = 1;

  // Singleton pattern
  static final MockApiService _instance = MockApiService._internal();
  factory MockApiService() => _instance;

  MockApiService._internal() {
    _initMockData();
  }

  void _initMockData() {
    // Add some mock users
    _users.add(
      User(id: _userId++, name: 'John Doe', email: 'john@example.com'),
    );
    _users.add(
      User(id: _userId++, name: 'Jane Smith', email: 'jane@example.com'),
    );

    // Add some mock expenses
    final now = DateTime.now();
    _expenses.add(
      Expense(
        id: _expenseId++,
        userId: 1,
        description: 'Groceries',
        amount: 50.0,
        date: now.subtract(const Duration(days: 2)),
      ),
    );
    _expenses.add(
      Expense(
        id: _expenseId++,
        userId: 2,
        description: 'Rent',
        amount: 500.0,
        date: now.subtract(const Duration(days: 5)),
      ),
    );
    _expenses.add(
      Expense(
        id: _expenseId++,
        userId: 1,
        description: 'Internet',
        amount: 60.0,
        date: now.subtract(const Duration(days: 10)),
      ),
    );
  }

  // Authentication methods
  Future<ApiResponse<Map<String, dynamic>>> login(
    String email,
    String password,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final user = _users.firstWhere((u) => u.email == email);
      _token = 'mock_token_${Random().nextInt(1000)}';

      return ApiResponse.success({
        'token': _token,
        'data': {'user': user.toMap()},
      });
    } catch (e) {
      return ApiResponse.error('Invalid email or password');
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> signup(
    String name,
    String email,
    String password,
    String passwordConfirm,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    if (_users.any((u) => u.email == email)) {
      return ApiResponse.error('Email already in use');
    }

    if (password != passwordConfirm) {
      return ApiResponse.error('Passwords do not match');
    }

    final newUser = User(id: _userId++, name: name, email: email);

    _users.add(newUser);
    _token = 'mock_token_${Random().nextInt(1000)}';

    return ApiResponse.success({
      'token': _token,
      'data': {'user': newUser.toMap()},
    });
  }

  Future<void> logout() async {
    _token = null;
  }

  // User methods
  Future<ApiResponse<User>> getCurrentUser() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    if (_token == null) {
      return ApiResponse.error('Not authenticated');
    }

    return ApiResponse.success(_users.first);
  }

  Future<ApiResponse<List<User>>> getAllUsers() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return ApiResponse.success(_users);
  }

  Future<ApiResponse<User>> createUser(User user) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final newUser = User(
      id: _userId++,
      name: user.name,
      email: user.email,
      phoneNumber: user.phoneNumber,
    );

    _users.add(newUser);

    return ApiResponse.success(newUser);
  }

  Future<ApiResponse<User>> updateUser(User user) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _users.indexWhere((u) => u.id == user.id);
    if (index == -1) {
      return ApiResponse.error('User not found');
    }

    _users[index] = user;

    return ApiResponse.success(user);
  }

  Future<ApiResponse<bool>> deleteUser(int id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _users.indexWhere((u) => u.id == id);
    if (index == -1) {
      return ApiResponse.error('User not found');
    }

    _users.removeAt(index);

    return ApiResponse.success(true);
  }

  // Expense methods
  Future<ApiResponse<List<Expense>>> getAllExpenses() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return ApiResponse.success(_expenses);
  }

  Future<ApiResponse<List<Expense>>> getMyExpenses() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Assume current user is the first user
    final currentUserId = _users.first.id;
    final myExpenses =
        _expenses.where((e) => e.userId == currentUserId).toList();

    return ApiResponse.success(myExpenses);
  }

  Future<ApiResponse<List<Expense>>> getExpensesByMonth(
    int month,
    int year,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final startDate = DateTime(year, month, 1);
    final endDate = DateTime(year, month + 1, 0); // Last day of month

    final monthlyExpenses =
        _expenses
            .where(
              (expense) =>
                  expense.date.isAfter(
                    startDate.subtract(const Duration(days: 1)),
                  ) &&
                  expense.date.isBefore(endDate.add(const Duration(days: 1))),
            )
            .toList();

    return ApiResponse.success(monthlyExpenses);
  }

  Future<ApiResponse<Expense>> createExpense(Expense expense) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final newExpense = Expense(
      id: _expenseId++,
      userId: expense.userId,
      description: expense.description,
      amount: expense.amount,
      date: expense.date,
    );

    _expenses.add(newExpense);

    return ApiResponse.success(newExpense);
  }

  Future<ApiResponse<Expense>> updateExpense(Expense expense) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _expenses.indexWhere((e) => e.id == expense.id);
    if (index == -1) {
      return ApiResponse.error('Expense not found');
    }

    _expenses[index] = expense;

    return ApiResponse.success(expense);
  }

  Future<ApiResponse<bool>> deleteExpense(int id) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final index = _expenses.indexWhere((e) => e.id == id);
    if (index == -1) {
      return ApiResponse.error('Expense not found');
    }

    _expenses.removeAt(index);

    return ApiResponse.success(true);
  }

  // Summary methods
  Future<ApiResponse<MonthlySummary>> getMonthlySummary(
    int month,
    int year,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final expensesResponse = await getExpensesByMonth(month, year);
    if (!expensesResponse.success) {
      return ApiResponse.error(expensesResponse.error!);
    }

    final expenses = expensesResponse.data!;

    // Calculate total amount
    double totalAmount = 0;
    for (var expense in expenses) {
      totalAmount += expense.amount;
    }

    // Calculate per head amount
    int userCount = _users.length;
    double perHeadAmount = userCount > 0 ? totalAmount / userCount : 0;

    // Calculate user expenses
    Map<int, double> userExpenses = {};
    for (var user in _users) {
      if (user.id != null) {
        userExpenses[user.id!] = 0;
      }
    }

    for (var expense in expenses) {
      if (userExpenses.containsKey(expense.userId)) {
        userExpenses[expense.userId] =
            (userExpenses[expense.userId] ?? 0) + expense.amount;
      }
    }

    final summary = MonthlySummary(
      month: month,
      year: year,
      totalAmount: totalAmount,
      userCount: userCount,
      perHeadAmount: perHeadAmount,
      userExpenses: userExpenses,
    );

    return ApiResponse.success(summary);
  }
}
