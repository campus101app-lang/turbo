// lib/services/snackbar_service.dart
//
// Custom Snackbar Service for DayFi
// Tracks usage and provides unified snackbar interface across all screens
//

import 'package:flutter/material.dart';
import 'package:awesome_snackbar_content/awesome_snackbar_content.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum SnackbarType {
  success,
  failure,
  help,
  warning,
  info,
}

enum SnackbarCategory {
  auth,           // Authentication related
  transaction,    // Transaction operations
  network,        // Network/API errors
  validation,     // Form validation
  system,         // System messages
  user,           // User actions
}

class SnackbarEvent {
  final String id;
  final String message;
  final SnackbarType type;
  final SnackbarCategory category;
  final String screen;
  final DateTime timestamp;
  final Duration duration;

  SnackbarEvent({
    required this.id,
    required this.message,
    required this.type,
    required this.category,
    required this.screen,
    required this.timestamp,
    required this.duration,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'type': type.name,
      'category': category.name,
      'screen': screen,
      'timestamp': timestamp.toIso8601String(),
      'duration': duration.inMilliseconds,
    };
  }

  factory SnackbarEvent.fromJson(Map<String, dynamic> json) {
    return SnackbarEvent(
      id: json['id'],
      message: json['message'],
      type: SnackbarType.values.firstWhere((e) => e.name == json['type']),
      category: SnackbarCategory.values.firstWhere((e) => e.name == json['category']),
      screen: json['screen'],
      timestamp: DateTime.parse(json['timestamp']),
      duration: Duration(milliseconds: json['duration']),
    );
  }
}

class SnackbarService {
  static final SnackbarService _instance = SnackbarService._internal();
  factory SnackbarService() => _instance;
  SnackbarService._internal();

  static const String _storageKey = 'snackbar_events';
  static const int _maxStoredEvents = 1000;
  
  final List<SnackbarEvent> _events = [];
  final Map<String, int> _screenUsageCount = {};
  final Map<SnackbarCategory, int> _categoryUsageCount = {};
  final Map<SnackbarType, int> _typeUsageCount = {};

  List<SnackbarEvent> get events => List.unmodifiable(_events);
  Map<String, int> get screenUsageCount => Map.unmodifiable(_screenUsageCount);
  Map<SnackbarCategory, int> get categoryUsageCount => Map.unmodifiable(_categoryUsageCount);
  Map<SnackbarType, int> get typeUsageCount => Map.unmodifiable(_typeUsageCount);

  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getStringList(_storageKey) ?? [];
      
      _events.clear();
      _screenUsageCount.clear();
      _categoryUsageCount.clear();
      _typeUsageCount.clear();

      for (final eventJson in eventsJson) {
        try {
          final event = SnackbarEvent.fromJson(jsonDecode(eventJson));
          _events.add(event);
          _updateUsageStats(event);
        } catch (e) {
          debugPrint('Error parsing snackbar event: $e');
        }
      }

      // Keep only the most recent events
      if (_events.length > _maxStoredEvents) {
        _events.removeRange(0, _events.length - _maxStoredEvents);
        await _saveEvents();
      }
    } catch (e) {
      debugPrint('Error initializing snackbar service: $e');
    }
  }

  void _updateUsageStats(SnackbarEvent event) {
    // Update screen usage
    _screenUsageCount[event.screen] = (_screenUsageCount[event.screen] ?? 0) + 1;
    
    // Update category usage
    _categoryUsageCount[event.category] = (_categoryUsageCount[event.category] ?? 0) + 1;
    
    // Update type usage
    _typeUsageCount[event.type] = (_typeUsageCount[event.type] ?? 0) + 1;
  }

  Future<void> _saveEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = _events.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_storageKey, eventsJson);
    } catch (e) {
      debugPrint('Error saving snackbar events: $e');
    }
  }

  void showCustomSnackBar(
    BuildContext context, {
    required String message,
    required SnackbarType type,
    required SnackbarCategory category,
    String? title,
    Duration duration = const Duration(seconds: 3),
    Color? backgroundColor,
    Color? textColor,
    IconData? icon,
  }) {
    final screen = _getCurrentScreen(context);
    final eventId = DateTime.now().millisecondsSinceEpoch.toString();
    
    // Create event
    final event = SnackbarEvent(
      id: eventId,
      message: message,
      type: type,
      category: category,
      screen: screen,
      timestamp: DateTime.now(),
      duration: duration,
    );

    // Update stats and save
    _events.add(event);
    _updateUsageStats(event);
    _saveEvents();

    // Show snackbar
    final contentType = _getContentType(type);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        content: AwesomeSnackbarContent(
          title: title ?? _getDefaultTitle(type),
          message: message,
          contentType: contentType,
          color: backgroundColor ?? _getDefaultColor(type),
          inMaterialBanner: false,
        ),
        duration: duration,
      ),
    );
  }

  ContentType _getContentType(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return ContentType.success;
      case SnackbarType.failure:
        return ContentType.failure;
      case SnackbarType.help:
        return ContentType.help;
      case SnackbarType.warning:
        return ContentType.warning;
      case SnackbarType.info:
        return ContentType.help;
    }
  }

  String _getDefaultTitle(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return 'Success!';
      case SnackbarType.failure:
        return 'Error!';
      case SnackbarType.help:
        return 'Help';
      case SnackbarType.warning:
        return 'Warning';
      case SnackbarType.info:
        return 'Info';
    }
  }

  Color _getDefaultColor(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Colors.green;
      case SnackbarType.failure:
        return Colors.red;
      case SnackbarType.help:
        return Colors.blue;
      case SnackbarType.warning:
        return Colors.orange;
      case SnackbarType.info:
        return Colors.blue;
    }
  }

  String _getCurrentScreen(BuildContext context) {
    final route = ModalRoute.of(context);
    if (route != null) {
      return route.settings.name ?? 'Unknown';
    }
    return 'Unknown';
  }

  // Convenience methods for common scenarios
  void showSuccess(
    BuildContext context, {
    required String message,
    String? title,
    String? screen,
    Duration duration = const Duration(seconds: 3),
  }) {
    showCustomSnackBar(
      context,
      message: message,
      type: SnackbarType.success,
      category: SnackbarCategory.user,
      title: title,
      duration: duration,
    );
  }

  void showError(
    BuildContext context, {
    required String message,
    String? title,
    String? screen,
    Duration duration = const Duration(seconds: 4),
  }) {
    showCustomSnackBar(
      context,
      message: message,
      type: SnackbarType.failure,
      category: SnackbarCategory.system,
      title: title,
      duration: duration,
    );
  }

  void showNetworkError(
    BuildContext context, {
    String? message,
    Duration duration = const Duration(seconds: 4),
  }) {
    showCustomSnackBar(
      context,
      message: message ?? 'Network error. Please check your connection.',
      type: SnackbarType.failure,
      category: SnackbarCategory.network,
      title: 'Network Error',
      duration: duration,
    );
  }

  void showValidationError(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    showCustomSnackBar(
      context,
      message: message,
      type: SnackbarType.warning,
      category: SnackbarCategory.validation,
      title: title ?? 'Validation Error',
      duration: duration,
    );
  }

  void showAuthError(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    showCustomSnackBar(
      context,
      message: message,
      type: SnackbarType.failure,
      category: SnackbarCategory.auth,
      title: title ?? 'Authentication Error',
      duration: duration,
    );
  }

  void showTransactionSuccess(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 3),
  }) {
    showCustomSnackBar(
      context,
      message: message,
      type: SnackbarType.success,
      category: SnackbarCategory.transaction,
      title: title ?? 'Transaction Successful',
      duration: duration,
    );
  }

  void showTransactionError(
    BuildContext context, {
    required String message,
    String? title,
    Duration duration = const Duration(seconds: 4),
  }) {
    showCustomSnackBar(
      context,
      message: message,
      type: SnackbarType.failure,
      category: SnackbarCategory.transaction,
      title: title ?? 'Transaction Failed',
      duration: duration,
    );
  }

  // Analytics methods
  Map<String, dynamic> getUsageStats() {
    return {
      'totalEvents': _events.length,
      'screenUsage': _screenUsageCount,
      'categoryUsage': _categoryUsageCount.map((k, v) => MapEntry(k.name, v)),
      'typeUsage': _typeUsageCount.map((k, v) => MapEntry(k.name, v)),
      'mostUsedScreen': _screenUsageCount.isEmpty ? null : 
          _screenUsageCount.entries.reduce((a, b) => a.value > b.value ? a : b).key,
      'mostUsedCategory': _categoryUsageCount.isEmpty ? null :
          _categoryUsageCount.entries.reduce((a, b) => a.value > b.value ? a : b).key.name,
      'mostUsedType': _typeUsageCount.isEmpty ? null :
          _typeUsageCount.entries.reduce((a, b) => a.value > b.value ? a : b).key.name,
    };
  }

  List<SnackbarEvent> getEventsForScreen(String screen) {
    return _events.where((event) => event.screen == screen).toList();
  }

  List<SnackbarEvent> getEventsForCategory(SnackbarCategory category) {
    return _events.where((event) => event.category == category).toList();
  }

  Future<void> clearHistory() async {
    _events.clear();
    _screenUsageCount.clear();
    _categoryUsageCount.clear();
    _typeUsageCount.clear();
    await _saveEvents();
  }

  Future<void> exportHistory() async {
    final stats = getUsageStats();
    debugPrint('=== Snackbar Usage Statistics ===');
    debugPrint('Total Events: ${stats['totalEvents']}');
    debugPrint('Most Used Screen: ${stats['mostUsedScreen']}');
    debugPrint('Most Used Category: ${stats['mostUsedCategory']}');
    debugPrint('Most Used Type: ${stats['mostUsedType']}');
    debugPrint('Screen Usage: ${stats['screenUsage']}');
    debugPrint('Category Usage: ${stats['categoryUsage']}');
    debugPrint('Type Usage: ${stats['typeUsage']}');
    debugPrint('================================');
  }
}
