// lib/services/tab_cache_service.dart
//
// Tab Cache Service for Performance Optimization
// Implements intelligent caching with refresh functionality for all tabs
//

import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class TabCacheService {
  static final TabCacheService _instance = TabCacheService._internal();
  factory TabCacheService() => _instance;
  TabCacheService._internal();

  // Cache keys for different tabs
  static const String _homeCacheKey = 'tab_cache_home';
  static const String _billingCacheKey = 'tab_cache_billing';
  static const String _shopCacheKey = 'tab_cache_shop';
  static const String _organizationCacheKey = 'tab_cache_organization';
  static const String _transactionsCacheKey = 'tab_cache_transactions';
  static const String _analyticsCacheKey = 'tab_cache_analytics';

  // Cache metadata keys
  static const String _cacheTimestampKey = '_timestamp';
  static const String _cacheVersionKey = '_version';
  static const String _cacheExpiryKey = '_expiry';

  // Cache configuration
  static const Duration _defaultCacheExpiry = Duration(minutes: 30);
  static const Duration _criticalCacheExpiry = Duration(minutes: 5);
  static const Duration _backgroundCacheExpiry = Duration(hours: 2);
  static const int _maxCacheSize = 1024 * 1024; // 1MB per tab

  final Map<String, DateTime> _lastRefreshTimes = {};
  final Map<String, StreamController<TabCacheEvent>> _cacheControllers = {};
  final Map<String, Timer?> _refreshTimers = {};

  void initialize() {
    _initializeAutoRefresh();
  }

  // Cache data for a specific tab
  Future<void> cacheTabData(
    String tabKey,
    Map<String, dynamic> data, {
    Duration? expiry,
    bool isCritical = false,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(tabKey);
      final metadataKey = _getMetadataKey(tabKey);

      // Check cache size
      final jsonData = jsonEncode(data);
      if (jsonData.length > _maxCacheSize) {
        debugPrint(
          'Cache data too large for tab $tabKey: ${jsonData.length} bytes',
        );
        return;
      }

      // Create cache metadata
      final metadata = {
        _cacheTimestampKey: DateTime.now().toIso8601String(),
        _cacheVersionKey: '1.0',
        _cacheExpiryKey:
            (expiry ??
                    (isCritical ? _criticalCacheExpiry : _defaultCacheExpiry))
                .inMilliseconds,
        'size': jsonData.length,
        'isCritical': isCritical,
      };

      // Save data and metadata
      await prefs.setString(cacheKey, jsonData);
      await prefs.setString(metadataKey, jsonEncode(metadata));

      // Update last refresh time
      _lastRefreshTimes[tabKey] = DateTime.now();

      // Notify listeners
      _notifyCacheEvent(tabKey, TabCacheEventType.updated, data);

      debugPrint('Cached data for tab $tabKey (${jsonData.length} bytes)');
    } catch (e) {
      debugPrint('Error caching data for tab $tabKey: $e');
    }
  }

  // Get cached data for a specific tab
  Future<T?> getCachedTabData<T>(String tabKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(tabKey);
      final metadataKey = _getMetadataKey(tabKey);

      // Check if data exists
      final cachedData = prefs.getString(cacheKey);
      final metadataStr = prefs.getString(metadataKey);

      if (cachedData == null || metadataStr == null) {
        return null;
      }

      // Parse metadata
      final metadata = jsonDecode(metadataStr) as Map<String, dynamic>;
      final timestamp = DateTime.parse(metadata[_cacheTimestampKey] as String);
      final expiryMs = metadata[_cacheExpiryKey] as int;
      final expiry = Duration(milliseconds: expiryMs);

      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > expiry) {
        debugPrint('Cache expired for tab $tabKey');
        await clearTabCache(tabKey);
        return null;
      }

      // Parse and return data
      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      return data as T?;
    } catch (e) {
      debugPrint('Error getting cached data for tab $tabKey: $e');
      return null;
    }
  }

  // Check if tab has cached data
  Future<bool> hasCachedData(String tabKey) async {
    final data = await getCachedTabData(tabKey);
    return data != null;
  }

  // Check if cache is fresh (not expired)
  Future<bool> isCacheFresh(String tabKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final metadataKey = _getMetadataKey(tabKey);
      final metadataStr = prefs.getString(metadataKey);

      if (metadataStr == null) return false;

      final metadata = jsonDecode(metadataStr) as Map<String, dynamic>;
      final timestamp = DateTime.parse(metadata[_cacheTimestampKey] as String);
      final expiryMs = metadata[_cacheExpiryKey] as int;
      final expiry = Duration(milliseconds: expiryMs);

      return DateTime.now().difference(timestamp) <= expiry;
    } catch (e) {
      debugPrint('Error checking cache freshness for tab $tabKey: $e');
      return false;
    }
  }

  // Refresh tab data
  Future<void> refreshTabData(
    String tabKey,
    Future<Map<String, dynamic>?> Function() dataLoader, {
    bool forceRefresh = false,
    bool isCritical = false,
  }) async {
    try {
      // Check if refresh is needed
      if (!forceRefresh && await isCacheFresh(tabKey)) {
        debugPrint('Cache is fresh for tab $tabKey, skipping refresh');
        return;
      }

      debugPrint('Refreshing data for tab $tabKey...');
      _notifyCacheEvent(tabKey, TabCacheEventType.refreshing, null);

      // Load fresh data
      final data = await dataLoader();
      if (data != null) {
        await cacheTabData(tabKey, data, isCritical: isCritical);
        _notifyCacheEvent(tabKey, TabCacheEventType.updated, data);
        debugPrint('Successfully refreshed data for tab $tabKey');
      } else {
        _notifyCacheEvent(
          tabKey,
          TabCacheEventType.error,
          'Failed to load data',
        );
      }
    } catch (e) {
      debugPrint('Error refreshing data for tab $tabKey: $e');
      _notifyCacheEvent(tabKey, TabCacheEventType.error, e.toString());
    }
  }

  // Clear cache for a specific tab
  Future<void> clearTabCache(String tabKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(tabKey);
      final metadataKey = _getMetadataKey(tabKey);

      await prefs.remove(cacheKey);
      await prefs.remove(metadataKey);

      _lastRefreshTimes.remove(tabKey);
      _notifyCacheEvent(tabKey, TabCacheEventType.cleared, null);

      debugPrint('Cleared cache for tab $tabKey');
    } catch (e) {
      debugPrint('Error clearing cache for tab $tabKey: $e');
    }
  }

  // Clear all tab caches
  Future<void> clearAllCaches() async {
    try {
      final tabs = [
        _homeCacheKey,
        _billingCacheKey,
        _shopCacheKey,
        _organizationCacheKey,
        _transactionsCacheKey,
        _analyticsCacheKey,
      ];

      for (final tab in tabs) {
        await clearTabCache(tab);
      }

      debugPrint('Cleared all tab caches');
    } catch (e) {
      debugPrint('Error clearing all caches: $e');
    }
  }

  // Get cache statistics
  Future<TabCacheStats> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tabs = [
        _homeCacheKey,
        _billingCacheKey,
        _shopCacheKey,
        _organizationCacheKey,
        _transactionsCacheKey,
        _analyticsCacheKey,
      ];

      int totalSize = 0;
      int freshCount = 0;
      final Map<String, TabCacheInfo> tabInfo = {};

      for (final tabKey in tabs) {
        final metadataKey = _getMetadataKey(tabKey);
        final metadataStr = prefs.getString(metadataKey);

        if (metadataStr != null) {
          final metadata = jsonDecode(metadataStr) as Map<String, dynamic>;
          final size = metadata['size'] as int? ?? 0;
          final timestamp = DateTime.parse(
            metadata[_cacheTimestampKey] as String,
          );
          final expiryMs = metadata[_cacheExpiryKey] as int;
          final expiry = Duration(milliseconds: expiryMs);
          final isFresh = DateTime.now().difference(timestamp) <= expiry;

          totalSize += size;
          if (isFresh) freshCount++;

          tabInfo[tabKey] = TabCacheInfo(
            size: size,
            timestamp: timestamp,
            expiry: expiry,
            isFresh: isFresh,
            isCritical: metadata['isCritical'] as bool? ?? false,
          );
        }
      }

      return TabCacheStats(
        totalSize: totalSize,
        freshCount: freshCount,
        totalCount: tabs.length,
        tabInfo: tabInfo,
      );
    } catch (e) {
      debugPrint('Error getting cache stats: $e');
      return TabCacheStats(
        totalSize: 0,
        freshCount: 0,
        totalCount: 0,
        tabInfo: {},
      );
    }
  }

  // Listen to cache events for a specific tab
  Stream<TabCacheEvent> getCacheEvents(String tabKey) {
    _cacheControllers.putIfAbsent(
      tabKey,
      () => StreamController<TabCacheEvent>.broadcast(),
    );
    return _cacheControllers[tabKey]!.stream;
  }

  // Auto-refresh configuration
  void _initializeAutoRefresh() {
    // Set up periodic refresh for critical tabs
    _setupPeriodicRefresh(_billingCacheKey, const Duration(minutes: 5));
    _setupPeriodicRefresh(_transactionsCacheKey, const Duration(minutes: 2));
    _setupPeriodicRefresh(_homeCacheKey, const Duration(minutes: 10));
  }

  void _setupPeriodicRefresh(String tabKey, Duration interval) {
    _refreshTimers[tabKey]?.cancel();
    _refreshTimers[tabKey] = Timer.periodic(interval, (timer) {
      _notifyCacheEvent(tabKey, TabCacheEventType.autoRefreshRequested, null);
    });
  }

  void _notifyCacheEvent(String tabKey, TabCacheEventType type, dynamic data) {
    final controller = _cacheControllers[tabKey];
    if (controller != null && !controller.isClosed) {
      controller.add(TabCacheEvent(tabKey, type, data, DateTime.now()));
    }
  }

  String _getCacheKey(String tabKey) => '${tabKey}_cache';
  String _getMetadataKey(String tabKey) => '${tabKey}_metadata';

  // Cleanup
  void dispose() {
    for (final timer in _refreshTimers.values) {
      timer?.cancel();
    }
    for (final controller in _cacheControllers.values) {
      controller.close();
    }
    _refreshTimers.clear();
    _cacheControllers.clear();
    _lastRefreshTimes.clear();
  }
}

// Tab cache data classes
class TabCacheEvent {
  final String tabKey;
  final TabCacheEventType type;
  final dynamic data;
  final DateTime timestamp;

  TabCacheEvent(this.tabKey, this.type, this.data, this.timestamp);
}

enum TabCacheEventType {
  updated,
  refreshed,
  refreshing,
  cleared,
  expired,
  error,
  autoRefreshRequested,
}

class TabCacheStats {
  final int totalSize;
  final int freshCount;
  final int totalCount;
  final Map<String, TabCacheInfo> tabInfo;

  TabCacheStats({
    required this.totalSize,
    required this.freshCount,
    required this.totalCount,
    required this.tabInfo,
  });

  double get freshnessPercentage =>
      totalCount > 0 ? (freshCount / totalCount) * 100 : 0;
  String get totalSizeFormatted =>
      '${(totalSize / 1024).toStringAsFixed(2)} KB';
}

class TabCacheInfo {
  final int size;
  final DateTime timestamp;
  final Duration expiry;
  final bool isFresh;
  final bool isCritical;

  TabCacheInfo({
    required this.size,
    required this.timestamp,
    required this.expiry,
    required this.isFresh,
    required this.isCritical,
  });

  String get sizeFormatted => '${(size / 1024).toStringAsFixed(2)} KB';
  String get age => DateTime.now().difference(timestamp).inMinutes < 60
      ? '${DateTime.now().difference(timestamp).inMinutes}m ago'
      : '${DateTime.now().difference(timestamp).inHours}h ago';
}

// Tab cache widget for easy integration
class TabCacheWidget extends StatefulWidget {
  final String tabKey;
  final Widget Function(
    Map<String, dynamic>? cachedData,
    bool isLoading,
    VoidCallback refresh,
  )
  builder;
  final Future<Map<String, dynamic>?> Function() dataLoader;
  final Duration? refreshInterval;
  final bool autoRefresh;

  const TabCacheWidget({
    super.key,
    required this.tabKey,
    required this.builder,
    required this.dataLoader,
    this.refreshInterval,
    this.autoRefresh = true,
  });

  @override
  State<TabCacheWidget> createState() => _TabCacheWidgetState();
}

class _TabCacheWidgetState extends State<TabCacheWidget> {
  final TabCacheService _cacheService = TabCacheService();
  Map<String, dynamic>? _cachedData;
  bool _isLoading = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _listenToCacheEvents();
    if (widget.autoRefresh) {
      _setupAutoRefresh();
    }
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _loadCachedData() async {
    setState(() => _isLoading = true);

    try {
      final data = await _cacheService.getCachedTabData(widget.tabKey);
      if (data != null) {
        setState(() {
          _cachedData = data;
          _isLoading = false;
        });
      } else {
        await _refreshData();
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error loading cached data: $e');
    }
  }

  Future<void> _refreshData() async {
    setState(() => _isLoading = true);

    try {
      await _cacheService.refreshTabData(widget.tabKey, widget.dataLoader);
      final data = await _cacheService.getCachedTabData(widget.tabKey);
      setState(() {
        _cachedData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint('Error refreshing data: $e');
    }
  }

  void _listenToCacheEvents() {
    _cacheService.getCacheEvents(widget.tabKey).listen((event) {
      if (event.type == TabCacheEventType.updated) {
        setState(() {
          _cachedData = event.data;
          _isLoading = false;
        });
      } else if (event.type == TabCacheEventType.refreshing) {
        setState(() => _isLoading = true);
      } else if (event.type == TabCacheEventType.error) {
        setState(() => _isLoading = false);
      } else if (event.type == TabCacheEventType.autoRefreshRequested) {
        _refreshData();
      }
    });
  }

  void _setupAutoRefresh() {
    final interval = widget.refreshInterval ?? const Duration(minutes: 5);
    _autoRefreshTimer = Timer.periodic(interval, (timer) {
      _refreshData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(_cachedData, _isLoading, _refreshData);
  }
}
