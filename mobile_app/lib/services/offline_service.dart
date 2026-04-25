// lib/services/offline_service.dart
//
// Offline Service for Nigerian Market
// Handles local data storage, transaction queuing, and sync conflict resolution
//

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// part 'offline_service.g.dart'; // Temporarily commented out - run build_runner to generate

enum OfflineOperationType {
  createInvoice,
  updateInvoice,
  createPayment,
  createExpense,
  updateCustomer,
  createProduct,
  updateOrder,
}

enum SyncStatus {
  pending,
  syncing,
  synced,
  failed,
  conflict,
}

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  late Box _operationBox;
  late Box _dataBox;
  late Box _conflictBox;
  
  bool _isInitialized = false;
  StreamController<SyncStatus>? _syncStatusController;
  Timer? _syncTimer;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      await Hive.initFlutter();
      
      // Register adapters - commented out until build_runner generates them
      // Hive.registerAdapter(OfflineOperationAdapter());
      // Hive.registerAdapter(OfflineDataAdapter());
      // Hive.registerAdapter(SyncConflictAdapter());
      
      // Open boxes
      _operationBox = await Hive.openBox('offline_operations');
      _dataBox = await Hive.openBox('offline_data');
      _conflictBox = await Hive.openBox('sync_conflicts');
      
      _isInitialized = true;
      
      // Start periodic sync
      _startPeriodicSync();
      
      debugPrint('Offline service initialized successfully');
    } catch (e) {
      debugPrint('Error initializing offline service: $e');
      rethrow;
    }
  }

  // Queue operation for offline sync
  Future<void> queueOperation(OfflineOperation operation) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _operationBox.add(operation);
      debugPrint('Queued offline operation: ${operation.type} (${operation.id})');
      
      // Try to sync immediately if online
      if (await _isOnline()) {
        _processPendingOperations();
      }
    } catch (e) {
      debugPrint('Error queuing operation: $e');
    }
  }

  // Store data locally
  Future<void> storeLocalData(String key, Map<String, dynamic> data) async {
    if (!_isInitialized) await initialize();
    
    try {
      final offlineData = OfflineData(
        key: key,
        data: jsonEncode(data),
        timestamp: DateTime.now(),
        isDirty: false,
      );
      
      await _dataBox.put(key, offlineData);
      debugPrint('Stored local data: $key');
    } catch (e) {
      debugPrint('Error storing local data: $e');
    }
  }

  // Get local data
  Future<Map<String, dynamic>?> getLocalData(String key) async {
    if (!_isInitialized) await initialize();
    
    try {
      final offlineData = _dataBox.get(key);
      if (offlineData != null) {
        return jsonDecode(offlineData.data) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting local data: $e');
      return null;
    }
  }

  // Check if data exists locally
  Future<bool> hasLocalData(String key) async {
    if (!_isInitialized) await initialize();
    return _dataBox.containsKey(key);
  }

  // Sync pending operations
  Future<SyncResult> syncPendingOperations() async {
    if (!_isInitialized) await initialize();
    
    try {
      final operations = _operationBox.values.where((op) => op.status == SyncStatus.pending).toList();
      
      if (operations.isEmpty) {
        return SyncResult(success: true, syncedCount: 0, errors: []);
      }

      _notifySyncStatus(SyncStatus.syncing);
      
      int syncedCount = 0;
      final List<String> errors = [];
      
      for (final operation in operations) {
        try {
          final success = await _syncOperation(operation);
          if (success) {
            operation.status = SyncStatus.synced;
            operation.syncedAt = DateTime.now();
            await operation.save();
            syncedCount++;
          } else {
            operation.status = SyncStatus.failed;
            operation.lastError = 'Sync failed';
            await operation.save();
            errors.add('Failed to sync ${operation.type}: ${operation.id}');
          }
        } catch (e) {
          operation.status = SyncStatus.failed;
          operation.lastError = e.toString();
          await operation.save();
          errors.add('Error syncing ${operation.type}: ${operation.id}: $e');
        }
      }
      
      _notifySyncStatus(SyncStatus.synced);
      
      return SyncResult(
        success: errors.isEmpty,
        syncedCount: syncedCount,
        errors: errors,
      );
    } catch (e) {
      _notifySyncStatus(SyncStatus.failed);
      debugPrint('Error syncing operations: $e');
      return SyncResult(success: false, syncedCount: 0, errors: [e.toString()]);
    }
  }

  // Handle sync conflicts
  Future<void> handleConflict(SyncConflict conflict) async {
    if (!_isInitialized) await initialize();
    
    try {
      await _conflictBox.add(conflict);
      debugPrint('Stored sync conflict: ${conflict.operationId}');
      
      // Notify user about conflict
      // This would typically trigger a UI notification
    } catch (e) {
      debugPrint('Error handling conflict: $e');
    }
  }

  // Resolve conflict
  Future<void> resolveConflict(String conflictId, ConflictResolution resolution) async {
    if (!_isInitialized) await initialize();
    
    try {
      final conflict = _conflictBox.get(conflictId);
      if (conflict != null) {
        switch (resolution) {
          case ConflictResolution.useLocal:
            await _applyLocalResolution(conflict);
            break;
          case ConflictResolution.useRemote:
            await _applyRemoteResolution(conflict);
            break;
          case ConflictResolution.merge:
            await _applyMergeResolution(conflict);
            break;
        }
        
        await _conflictBox.delete(conflictId);
        debugPrint('Resolved conflict: $conflictId with $resolution');
      }
    } catch (e) {
      debugPrint('Error resolving conflict: $e');
    }
  }

  // Get sync statistics
  Future<SyncStats> getSyncStats() async {
    if (!_isInitialized) await initialize();
    
    try {
      final pendingOperations = _operationBox.values.where((op) => op.status == SyncStatus.pending).length;
      final failedOperations = _operationBox.values.where((op) => op.status == SyncStatus.failed).length;
      final syncedOperations = _operationBox.values.where((op) => op.status == SyncStatus.synced).length;
      final conflicts = _conflictBox.length;
      
      return SyncStats(
        pendingOperations: pendingOperations,
        failedOperations: failedOperations,
        syncedOperations: syncedOperations,
        conflicts: conflicts,
        lastSyncTime: _getLastSyncTime(),
      );
    } catch (e) {
      debugPrint('Error getting sync stats: $e');
      return SyncStats(pendingOperations: 0, failedOperations: 0, syncedOperations: 0, conflicts: 0);
    }
  }

  // Clear offline data
  Future<void> clearOfflineData() async {
    if (!_isInitialized) await initialize();
    
    try {
      await _operationBox.clear();
      await _dataBox.clear();
      await _conflictBox.clear();
      debugPrint('Cleared all offline data');
    } catch (e) {
      debugPrint('Error clearing offline data: $e');
    }
  }

  // Private methods
  Future<bool> _isOnline() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();
      return connectivityResult != ConnectivityResult.none;
    } catch (e) {
      return false;
    }
  }

  Future<void> _startPeriodicSync() async {
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      if (await _isOnline()) {
        await _processPendingOperations();
      }
    });
  }

  Future<void> _processPendingOperations() async {
    final operations = _operationBox.values.where((op) => op.status == SyncStatus.pending).toList();
    
    for (final operation in operations.take(10)) { // Process in batches of 10
      await _syncOperation(operation);
    }
  }

  Future<bool> _syncOperation(OfflineOperation operation) async {
    try {
      // This would make the actual API call
      // For now, we'll simulate the sync
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Simulate 90% success rate
      if (DateTime.now().millisecond % 10 != 0) {
        return true;
      } else {
        throw Exception('Simulated sync failure');
      }
    } catch (e) {
      debugPrint('Error syncing operation ${operation.id}: $e');
      return false;
    }
  }

  DateTime? _getLastSyncTime() {
    final operations = _operationBox.values.where((op) => op.status == SyncStatus.synced);
    if (operations.isEmpty) return null;
    
    return operations
        .map((op) => op.syncedAt)
        .where((time) => time != null)
        .reduce((a, b) => a!.isAfter(b!) ? a : b);
  }

  void _notifySyncStatus(SyncStatus status) {
    _syncStatusController?.add(status);
  }

  Future<void> _applyLocalResolution(SyncConflict conflict) async {
    // Apply local version of data
    if (conflict.localData != null) {
      await storeLocalData(conflict.dataKey, conflict.localData!);
    }
  }

  Future<void> _applyRemoteResolution(SyncConflict conflict) async {
    // Apply remote version of data
    if (conflict.remoteData != null) {
      await storeLocalData(conflict.dataKey, conflict.remoteData!);
    }
  }

  Future<void> _applyMergeResolution(SyncConflict conflict) async {
    // Merge local and remote data
    if (conflict.localData != null && conflict.remoteData != null) {
      final mergedData = _mergeData(conflict.localData!, conflict.remoteData!);
      await storeLocalData(conflict.dataKey, mergedData);
    }
  }

  Map<String, dynamic> _mergeData(Map<String, dynamic> local, Map<String, dynamic> remote) {
    // Simple merge strategy - in production, this would be more sophisticated
    final merged = Map<String, dynamic>.from(remote);
    
    // Merge timestamps - use the most recent
    if (local.containsKey('updatedAt') && remote.containsKey('updatedAt')) {
      final localTime = DateTime.parse(local['updatedAt'] as String);
      final remoteTime = DateTime.parse(remote['updatedAt'] as String);
      
      if (localTime.isAfter(remoteTime)) {
        merged.addAll(local);
      }
    }
    
    return merged;
  }

  // Cleanup
  void dispose() {
    _syncTimer?.cancel();
    _syncStatusController?.close();
    _operationBox.close();
    _dataBox.close();
    _conflictBox.close();
  }
}

// Hive models
@HiveType(typeId: 0)
class OfflineOperation extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  OfflineOperationType type;
  
  @HiveField(2)
  Map<String, dynamic> data;
  
  @HiveField(3)
  SyncStatus status;
  
  @HiveField(4)
  DateTime createdAt;
  
  @HiveField(5)
  DateTime? syncedAt;
  
  @HiveField(6)
  String? lastError;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.data,
    this.status = SyncStatus.pending,
    required this.createdAt,
    this.syncedAt,
    this.lastError,
  });
}

@HiveType(typeId: 1)
class OfflineData extends HiveObject {
  @HiveField(0)
  String key;
  
  @HiveField(1)
  String data;
  
  @HiveField(2)
  DateTime timestamp;
  
  @HiveField(3)
  bool isDirty;

  OfflineData({
    required this.key,
    required this.data,
    required this.timestamp,
    this.isDirty = false,
  });
}

@HiveType(typeId: 2)
class SyncConflict extends HiveObject {
  @HiveField(0)
  String id;
  
  @HiveField(1)
  String operationId;
  
  @HiveField(2)
  String dataKey;
  
  @HiveField(3)
  Map<String, dynamic>? localData;
  
  @HiveField(4)
  Map<String, dynamic>? remoteData;
  
  @HiveField(5)
  DateTime createdAt;

  SyncConflict({
    required this.id,
    required this.operationId,
    required this.dataKey,
    this.localData,
    this.remoteData,
    required this.createdAt,
  });
}

// Supporting classes
class SyncResult {
  final bool success;
  final int syncedCount;
  final List<String> errors;

  SyncResult({
    required this.success,
    required this.syncedCount,
    required this.errors,
  });
}

class SyncStats {
  final int pendingOperations;
  final int failedOperations;
  final int syncedOperations;
  final int conflicts;
  final DateTime? lastSyncTime;

  SyncStats({
    required this.pendingOperations,
    required this.failedOperations,
    required this.syncedOperations,
    required this.conflicts,
    this.lastSyncTime,
  });

  int get totalOperations => pendingOperations + failedOperations + syncedOperations;
  double get syncRate => totalOperations > 0 ? (syncedOperations / totalOperations) * 100 : 0;
}

enum ConflictResolution {
  useLocal,
  useRemote,
  merge,
}

// Offline operation factory
class OfflineOperationFactory {
  static OfflineOperation createInvoice({
    required String invoiceId,
    required Map<String, dynamic> invoiceData,
  }) {
    return OfflineOperation(
      id: invoiceId,
      type: OfflineOperationType.createInvoice,
      data: invoiceData,
      createdAt: DateTime.now(),
    );
  }

  static OfflineOperation updateInvoice({
    required String invoiceId,
    required Map<String, dynamic> invoiceData,
  }) {
    return OfflineOperation(
      id: invoiceId,
      type: OfflineOperationType.updateInvoice,
      data: invoiceData,
      createdAt: DateTime.now(),
    );
  }

  static OfflineOperation createPayment({
    required String paymentId,
    required Map<String, dynamic> paymentData,
  }) {
    return OfflineOperation(
      id: paymentId,
      type: OfflineOperationType.createPayment,
      data: paymentData,
      createdAt: DateTime.now(),
    );
  }

  static OfflineOperation createExpense({
    required String expenseId,
    required Map<String, dynamic> expenseData,
  }) {
    return OfflineOperation(
      id: expenseId,
      type: OfflineOperationType.createExpense,
      data: expenseData,
      createdAt: DateTime.now(),
    );
  }

  static OfflineOperation updateCustomer({
    required String customerId,
    required Map<String, dynamic> customerData,
  }) {
    return OfflineOperation(
      id: customerId,
      type: OfflineOperationType.updateCustomer,
      data: customerData,
      createdAt: DateTime.now(),
    );
  }

  static OfflineOperation createProduct({
    required String productId,
    required Map<String, dynamic> productData,
  }) {
    return OfflineOperation(
      id: productId,
      type: OfflineOperationType.createProduct,
      data: productData,
      createdAt: DateTime.now(),
    );
  }

  static OfflineOperation updateOrder({
    required String orderId,
    required Map<String, dynamic> orderData,
  }) {
    return OfflineOperation(
      id: orderId,
      type: OfflineOperationType.updateOrder,
      data: orderData,
      createdAt: DateTime.now(),
    );
  }
}

// Offline status widget
class OfflineStatusIndicator extends StatefulWidget {
  const OfflineStatusIndicator({super.key});

  @override
  State<OfflineStatusIndicator> createState() => _OfflineStatusIndicatorState();
}

class _OfflineStatusIndicatorState extends State<OfflineStatusIndicator> {
  final OfflineService _offlineService = OfflineService();
  bool _isOnline = true;
  SyncStats? _syncStats;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _loadSyncStats();
  }

  Future<void> _checkConnectivity() async {
    final connectivity = await Connectivity().checkConnectivity();
    setState(() {
      _isOnline = connectivity != ConnectivityResult.none;
    });
  }

  Future<void> _loadSyncStats() async {
    final stats = await _offlineService.getSyncStats();
    setState(() {
      _syncStats = stats;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOnline) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 16, color: Colors.orange),
            const SizedBox(width: 8),
            Text(
              'Offline',
              style: TextStyle(
                color: Colors.orange,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (_syncStats != null && _syncStats!.pendingOperations > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.blue.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sync, size: 16, color: Colors.blue),
            const SizedBox(width: 8),
            Text(
              '${_syncStats!.pendingOperations} pending',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_done, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            'Synced',
            style: TextStyle(
              color: Colors.green,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
