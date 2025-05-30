import 'package:flutter/foundation.dart';

import '../models/user.dart';
import 'improved_api_service.dart';
import 'mock_api_service.dart';

enum ApiMode { real, mock }

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;

  ServiceLocator._internal();

  ApiMode _apiMode = ApiMode.mock; // Default to mock for development
  User? _currentUser;

  // Getters for services
  dynamic get apiService =>
      _apiMode == ApiMode.real ? ImprovedApiService() : _mockApiService;

  MockApiService get _mockApiService => MockApiService();

  // Get current user
  User? get currentUser => _currentUser;

  // Set current user
  void setCurrentUser(User user) {
    _currentUser = user;
    debugPrint('Current user set: ${user.name} (ID: ${user.id})');
  }

  // Clear current user
  void clearCurrentUser() {
    _currentUser = null;
  }

  // Set API mode
  void setApiMode(ApiMode mode) {
    _apiMode = mode;
  }

  // Check if using mock API
  bool get isMockApi => _apiMode == ApiMode.mock;
}
