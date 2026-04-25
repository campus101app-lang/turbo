// lib/services/performance_service.dart
//
// Performance Service for Mobile App Optimization
// Handles caching, preloading, and performance monitoring
//

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();
  factory PerformanceService() => _instance;
  PerformanceService._internal();

  // Cache management
  final Map<String, dynamic> _memoryCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _defaultCacheExpiry = Duration(minutes: 5);

  // Performance metrics
  final List<PerformanceMetric> _metrics = [];
  Timer? _metricsTimer;

  // Preload queue
  final List<PreloadTask> _preloadQueue = [];
  bool _isPreloading = false;

  // Memory management
  static const int _maxCacheSize = 100; // Maximum items in memory cache
  static const int _maxMemoryUsage = 50 * 1024 * 1024; // 50MB

  void initialize() {
    _startPerformanceMonitoring();
    _preloadCriticalData();
  }

  // Cache management
  Future<T?> getCachedData<T>(String key, {Duration? expiry}) async {
    final timestamp = _cacheTimestamps[key];
    final cacheExpiry = expiry ?? _defaultCacheExpiry;

    if (timestamp != null && DateTime.now().difference(timestamp) < cacheExpiry) {
      return _memoryCache[key] as T?;
    }

    // Check persistent cache
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(key);
    if (cachedData != null) {
      try {
        final data = _deserializeData<T>(cachedData);
        _memoryCache[key] = data;
        _cacheTimestamps[key] = DateTime.now();
        return data;
      } catch (e) {
        debugPrint('Cache deserialization error: $e');
      }
    }

    return null;
  }

  Future<void> setCachedData<T>(String key, T data, {Duration? expiry}) async {
    _memoryCache[key] = data;
    _cacheTimestamps[key] = DateTime.now();

    // Save to persistent cache for important data
    if (expiry != null && expiry.inHours > 1) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final serializedData = _serializeData(data);
        await prefs.setString(key, serializedData);
      } catch (e) {
        debugPrint('Cache serialization error: $e');
      }
    }

    _cleanupCache();
  }

  void _cleanupCache() {
    if (_memoryCache.length > _maxCacheSize) {
      // Remove oldest entries
      final sortedEntries = _cacheTimestamps.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      
      final entriesToRemove = sortedEntries.take(_memoryCache.length - _maxCacheSize);
      for (final entry in entriesToRemove) {
        _memoryCache.remove(entry.key);
        _cacheTimestamps.remove(entry.key);
      }
    }
  }

  // Performance monitoring
  void _startPerformanceMonitoring() {
    _metricsTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _collectPerformanceMetrics();
    });
  }

  void _collectPerformanceMetrics() {
    final metric = PerformanceMetric(
      timestamp: DateTime.now(),
      memoryUsage: _getCurrentMemoryUsage(),
      cacheSize: _memoryCache.length,
      cacheHitRate: _calculateCacheHitRate(),
    );

    _metrics.add(metric);
    
    // Keep only last 100 metrics
    if (_metrics.length > 100) {
      _metrics.removeAt(0);
    }

    // Alert if performance issues detected
    _checkPerformanceIssues(metric);
  }

  int _getCurrentMemoryUsage() {
    // Estimate memory usage (simplified)
    return _memoryCache.length * 1024; // Rough estimate
  }

  double _calculateCacheHitRate() {
    // This would be calculated based on actual cache hits/misses
    return 0.85; // Placeholder
  }

  void _checkPerformanceIssues(PerformanceMetric metric) {
    if (metric.memoryUsage > _maxMemoryUsage) {
      debugPrint('WARNING: High memory usage detected: ${metric.memoryUsage}');
      _aggressiveCacheCleanup();
    }

    if (metric.cacheHitRate < 0.7) {
      debugPrint('WARNING: Low cache hit rate: ${metric.cacheHitRate}');
    }
  }

  void _aggressiveCacheCleanup() {
    // Remove half of the oldest cache entries
    final sortedEntries = _cacheTimestamps.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    final entriesToRemove = sortedEntries.take(sortedEntries.length ~/ 2);
    for (final entry in entriesToRemove) {
      _memoryCache.remove(entry.key);
      _cacheTimestamps.remove(entry.key);
    }
  }

  // Preloading
  void _preloadCriticalData() {
    // Add critical data to preload queue
    _preloadQueue.addAll([
      PreloadTask(
        key: 'user_profile',
        priority: PreloadPriority.high,
        loader: () => _preloadUserProfile(),
      ),
      PreloadTask(
        key: 'recent_transactions',
        priority: PreloadPriority.high,
        loader: () => _preloadRecentTransactions(),
      ),
      PreloadTask(
        key: 'balance_data',
        priority: PreloadPriority.high,
        loader: () => _preloadBalanceData(),
      ),
    ]);

    _processPreloadQueue();
  }

  void _processPreloadQueue() {
    if (_isPreloading || _preloadQueue.isEmpty) return;

    _isPreloading = true;
    _preloadQueue.sort((a, b) => b.priority.index.compareTo(a.priority.index));

    _preloadNext();
  }

  Future<void> _preloadNext() async {
    if (_preloadQueue.isEmpty) {
      _isPreloading = false;
      return;
    }

    final task = _preloadQueue.removeAt(0);
    
    try {
      final data = await task.loader();
      if (data != null) {
        await setCachedData(task.key, data);
      }
    } catch (e) {
      debugPrint('Preload error for ${task.key}: $e');
    }

    // Continue with next task
    _preloadNext();
  }

  Future<Map<String, dynamic>?> _preloadUserProfile() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 100));
    return {
      'name': 'Test User',
      'email': 'test@example.com',
      'businessName': 'Test Business',
    };
  }

  Future<List<Map<String, dynamic>>> _preloadRecentTransactions() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 150));
    return [
      {'id': '1', 'amount': 50000, 'type': 'payment'},
      {'id': '2', 'amount': 25000, 'type': 'invoice'},
    ];
  }

  Future<Map<String, dynamic>> _preloadBalanceData() async {
    // Simulate API call
    await Future.delayed(const Duration(milliseconds: 100));
    return {
      'NGN': 125000.50,
      'USDC': 1000.00,
      'XLM': 500.00,
    };
  }

  void addToPreloadQueue(PreloadTask task) {
    _preloadQueue.add(task);
    if (!_isPreloading) {
      _processPreloadQueue();
    }
  }

  // Data serialization helpers
  String _serializeData(dynamic data) {
    // Simple JSON serialization (would use proper JSON encoder in production)
    return data.toString();
  }

  T _deserializeData<T>(String data) {
    // Simple JSON deserialization (would use proper JSON decoder in production)
    throw UnimplementedError('Deserialization not implemented');
  }

  // Performance optimization utilities
  Future<void> optimizeImageLoading() async {
    // Preload critical images
    await _preloadCriticalImages();
    
    // Configure image caching
    await _configureImageCache();
  }

  Future<void> _preloadCriticalImages() async {
    final criticalImages = [
      'assets/icons/dayfi_logo.png',
      'assets/images/default_avatar.png',
    ];

    for (final imagePath in criticalImages) {
      try {
        await _preloadImage(imagePath);
      } catch (e) {
        debugPrint('Failed to preload image $imagePath: $e');
      }
    }
  }

  Future<void> _preloadImage(String imagePath) async {
    // Use Flutter's image preloading
    final image = await ui.instantiateImageCodec(
      await _loadImageData(imagePath),
    );
    image.dispose();
  }

  Future<Uint8List> _loadImageData(String imagePath) async {
    // Load image data (simplified)
    return Uint8List.fromList([]);
  }

  Future<void> _configureImageCache() async {
    // Configure Flutter's image cache
    PaintingBinding.instance.imageCache.maximumSize = 100;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50MB
  }

  // Network optimization
  Future<bool> checkConnectivity() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      return false;
    }
  }

  Future<void> optimizeForNetworkCondition() async {
    final isConnected = await checkConnectivity();
    
    if (!isConnected) {
      // Enable offline mode
      await _enableOfflineMode();
    } else {
      // Disable offline mode and sync data
      await _disableOfflineMode();
    }
  }

  Future<void> _enableOfflineMode() async {
    // Implement offline mode logic
    debugPrint('Offline mode enabled');
  }

  Future<void> _disableOfflineMode() async {
    // Implement sync logic
    debugPrint('Offline mode disabled');
  }

  // Performance metrics
  List<PerformanceMetric> getMetrics() => List.unmodifiable(_metrics);

  PerformanceMetric? getLatestMetric() => _metrics.isNotEmpty ? _metrics.last : null;

  // Cleanup
  void dispose() {
    _metricsTimer?.cancel();
    _memoryCache.clear();
    _cacheTimestamps.clear();
    _preloadQueue.clear();
  }
}

// Performance data classes
class PerformanceMetric {
  final DateTime timestamp;
  final int memoryUsage;
  final int cacheSize;
  final double cacheHitRate;

  PerformanceMetric({
    required this.timestamp,
    required this.memoryUsage,
    required this.cacheSize,
    required this.cacheHitRate,
  });
}

class PreloadTask {
  final String key;
  final PreloadPriority priority;
  final Future<dynamic> Function() loader;

  PreloadTask({
    required this.key,
    required this.priority,
    required this.loader,
  });
}

enum PreloadPriority {
  high,
  medium,
  low,
}

// Performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final bool enabled;

  const PerformanceMonitor({
    super.key,
    required this.child,
    this.enabled = true,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  final PerformanceService _performanceService = PerformanceService();
  Duration? _lastFrameTime;
  int _frameCount = 0;
  double _fps = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback(_onFrame);
    }
  }

  void _onFrame(Duration timestamp) {
    if (_lastFrameTime != null) {
      final frameDuration = timestamp.inMicroseconds - _lastFrameTime!.inMicroseconds;
      _fps = 1000000.0 / frameDuration;
      _frameCount++;

      // Log FPS every 60 frames
      if (_frameCount % 60 == 0) {
        debugPrint('FPS: $_fps');
      }
    }

    _lastFrameTime = timestamp;
    WidgetsBinding.instance.addPostFrameCallback(_onFrame);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

// Performance optimized list view
class OptimizedListView extends StatelessWidget {
  final List<dynamic> items;
  final Widget Function(BuildContext context, dynamic item, int index) itemBuilder;
  final ScrollController? controller;
  final bool shrinkWrap;

  const OptimizedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.controller,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index);
      },
    );
  }
}

// Performance optimized image widget
class OptimizedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;

  const OptimizedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ?? const Center(child: CircularProgressIndicator());
      },
      errorBuilder: (context, error, stackTrace) {
        return placeholder ?? const Icon(Icons.error);
      },
    );
  }
}
