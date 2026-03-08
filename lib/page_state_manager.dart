import 'package:flutter/material.dart';

/// Global state manager for sidebar selection
class PageStateManager {
  static final PageStateManager _instance = PageStateManager._internal();

  int _currentPage = 0;
  final List<VoidCallback> _listeners = [];

  PageStateManager._internal();

  factory PageStateManager() {
    return _instance;
  }

  int get currentPage => _currentPage;

  void setCurrentPage(int index) {
    if (_currentPage != index) {
      _currentPage = index;
      notifyListeners();
    }
  }

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void notifyListeners() {
    for (var listener in _listeners) {
      listener();
    }
  }

  void dispose() {
    _listeners.clear();
  }
}

// Global instance - easier to access
final pageManager = PageStateManager();