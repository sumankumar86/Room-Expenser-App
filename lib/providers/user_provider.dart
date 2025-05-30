import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../services/service_locator.dart';

class UserProvider with ChangeNotifier {
  final _serviceLocator = ServiceLocator();
  List<User> _users = [];
  bool _isLoading = false;
  String? _error;

  List<User> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadUsers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _serviceLocator.apiService.getAllUsers();

      if (response.success) {
        _users = response.data!;
      } else {
        _error = response.error;
        debugPrint('Error loading users: $_error');
      }
    } catch (e) {
      _error = 'Unexpected error: $e';
      debugPrint('Error loading users: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addUser(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _serviceLocator.apiService.createUser(user);

      if (response.success) {
        await loadUsers(); // Reload users to get the updated list
        return true;
      } else {
        _error = response.error;
        debugPrint('Error adding user: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Unexpected error: $e';
      debugPrint('Error adding user: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateUser(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _serviceLocator.apiService.updateUser(user);

      if (response.success) {
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = response.data!;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error;
        debugPrint('Error updating user: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Unexpected error: $e';
      debugPrint('Error updating user: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteUser(dynamic id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _serviceLocator.apiService.deleteUser(id);

      if (response.success) {
        _users.removeWhere((user) => user.id == id);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error;
        debugPrint('Error deleting user: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Unexpected error: $e';
      debugPrint('Error deleting user: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update current user profile
  Future<bool> updateProfile(User user) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _serviceLocator.apiService.updateProfile(user);

      if (response.success) {
        // Update the user in the local list
        final index = _users.indexWhere((u) => u.id == user.id);
        if (index != -1) {
          _users[index] = user;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response.error;
        debugPrint('Error updating profile: $_error');
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Unexpected error: $e';
      debugPrint('Error updating profile: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
