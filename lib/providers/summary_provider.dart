import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/service_locator.dart';

class SummaryProvider with ChangeNotifier {
  final _serviceLocator = ServiceLocator();
  MonthlySummary? _currentSummary;
  bool _isLoading = false;
  String? _error;
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  int? _selectedUserId; // null means show all users

  // Getters
  MonthlySummary? get currentSummary => _currentSummary;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentMonth => _currentMonth;
  int get currentYear => _currentYear;
  int? get selectedUserId => _selectedUserId;

  // Load monthly summary
  Future<void> loadMonthlySummary([int? month, int? year]) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final targetMonth = month ?? _currentMonth;
      final targetYear = year ?? _currentYear;

      final response = await _serviceLocator.apiService.getMonthlySummary(
        targetMonth,
        targetYear,
      );

      if (response.success && response.data != null) {
        _currentSummary = response.data;
        _currentMonth = targetMonth;
        _currentYear = targetYear;
      } else {
        _error = response.error ?? 'Failed to load summary';
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading monthly summary: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setMonth(int month, int year) {
    // Get current date to prevent setting future months
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Check if the requested month is in the future
    if (year > currentYear || (year == currentYear && month > currentMonth)) {
      _error = "Cannot navigate to future months";
      notifyListeners();
      return;
    }

    if (month != _currentMonth || year != _currentYear) {
      _currentMonth = month;
      _currentYear = year;
      loadMonthlySummary(month, year);
    }
  }

  void nextMonth() {
    int nextMonth = _currentMonth + 1;
    int nextYear = _currentYear;

    if (nextMonth > 12) {
      nextMonth = 1;
      nextYear++;
    }

    // Get current date to prevent navigating to future months
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;

    // Only navigate if not going to a future month
    if (nextYear < currentYear ||
        (nextYear == currentYear && nextMonth <= currentMonth)) {
      setMonth(nextMonth, nextYear);
    } else {
      // If trying to navigate to future, show error
      _error = "Cannot navigate to future months";
      notifyListeners();
    }
  }

  void previousMonth() {
    int prevMonth = _currentMonth - 1;
    int prevYear = _currentYear;

    if (prevMonth < 1) {
      prevMonth = 12;
      prevYear--;
    }

    setMonth(prevMonth, prevYear);
  }

  // Set selected user for filtering
  void setSelectedUser(int? userId) {
    if (_selectedUserId != userId) {
      _selectedUserId = userId;
      notifyListeners();
    }
  }

  // Clear selected user filter
  void clearUserFilter() {
    if (_selectedUserId != null) {
      _selectedUserId = null;
      notifyListeners();
    }
  }
}
