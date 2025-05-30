import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/service_locator.dart';

class ExpenseProvider with ChangeNotifier {
  final _serviceLocator = ServiceLocator();
  List<Expense> _expenses = [];
  bool _isLoading = false;
  String? _error;

  List<Expense> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadExpenses() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _serviceLocator.apiService.getAllExpenses();

      if (response.success) {
        _expenses = response.data ?? [];
      } else {
        _error = response.error;
        debugPrint('Error loading expenses: $_error');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading expenses: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExpensesByUser(dynamic userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _serviceLocator.apiService.getExpensesByUser(
        userId,
      );

      if (response.success) {
        _expenses = response.data ?? [];
      } else {
        _error = response.error;
        debugPrint('Error loading expenses by user: $_error');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading expenses by user: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExpensesByMonth(int month, int year) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _serviceLocator.apiService.getExpensesByMonth(
        month,
        year,
      );

      if (response.success) {
        _expenses = response.data ?? [];
      } else {
        _error = response.error;
        debugPrint('Error loading expenses by month: $_error');
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading expenses by month: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addExpense(Expense expense) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _serviceLocator.apiService.createExpense(expense);

      if (response.success) {
        await loadExpenses(); // Reload expenses to get the updated list
        return true;
      } else {
        _error = response.error;
        debugPrint('Error adding expense: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error adding expense: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExpense(Expense expense) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _serviceLocator.apiService.updateExpense(expense);

      if (response.success) {
        // Update the expense in the local list
        final index = _expenses.indexWhere((e) => e.id == expense.id);
        if (index != -1) {
          _expenses[index] = expense;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error;
        debugPrint('Error updating expense: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error updating expense: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExpense(dynamic id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _serviceLocator.apiService.deleteExpense(id);

      if (response.success) {
        // Remove the expense from the local list
        _expenses.removeWhere((expense) => expense.id == id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error;
        debugPrint('Error deleting expense: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error deleting expense: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
