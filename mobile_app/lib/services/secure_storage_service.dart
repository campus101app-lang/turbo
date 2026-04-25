// lib/services/secure_storage_service.dart
//
// Secure Storage Service for DayFi
// Handles secure storage of sensitive data using FlutterSecureStorage
//

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  late final FlutterSecureStorage _secureStorage;

  void initialize() {
    _secureStorage = kIsWeb 
        ? const FlutterSecureStorage()
        : const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
          );
  }

  // Store data securely
  Future<void> storeString(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
    } catch (e) {
      debugPrint('Error storing secure data: $e');
      rethrow;
    }
  }

  // Retrieve data
  Future<String?> getString(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      debugPrint('Error retrieving secure data: $e');
      return null;
    }
  }

  // Store encrypted data
  Future<void> storeEncryptedString(String key, String value) async {
    try {
      final encrypted = _encryptData(value);
      await _secureStorage.write(key: key, value: encrypted);
    } catch (e) {
      debugPrint('Error storing encrypted data: $e');
      rethrow;
    }
  }

  // Retrieve and decrypt data
  Future<String?> getEncryptedString(String key) async {
    try {
      final encrypted = await _secureStorage.read(key: key);
      if (encrypted == null) return null;
      return _decryptData(encrypted);
    } catch (e) {
      debugPrint('Error retrieving encrypted data: $e');
      return null;
    }
  }

  // Delete data
  Future<void> delete(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      debugPrint('Error deleting secure data: $e');
      rethrow;
    }
  }

  // Clear all data
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing secure data: $e');
      rethrow;
    }
  }

  // Check if key exists
  Future<bool> containsKey(String key) async {
    try {
      final value = await _secureStorage.read(key: key);
      return value != null;
    } catch (e) {
      debugPrint('Error checking secure key: $e');
      return false;
    }
  }

  // Get all keys
  Future<Map<String, String>> getAll() async {
    try {
      return await _secureStorage.readAll();
    } catch (e) {
      debugPrint('Error retrieving all secure data: $e');
      return {};
    }
  }

  // Simple encryption (for demo purposes)
  String _encryptData(String data) {
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return base64.encode(digest.bytes);
  }

  // Simple decryption (for demo purposes - in real app, use proper encryption)
  String _decryptData(String encryptedData) {
    // This is a placeholder - in real implementation, use proper encryption/decryption
    return encryptedData;
  }
}
