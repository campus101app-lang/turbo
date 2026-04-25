// lib/services/security_service.dart
//
// Security Service for Mobile App
// Handles biometric authentication, secure storage, and security features
//

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = kIsWeb 
      ? const FlutterSecureStorage()
      : const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );
  
  // Security settings
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _sessionTimeoutKey = 'session_timeout';
  static const String _encryptionKeyKey = 'encryption_key';
  static const String _failedAttemptsKey = 'failed_attempts';
  static const String _lockoutTimeKey = 'lockout_time';

  // Session management
  DateTime? _lastAuthTime;
  Timer? _sessionTimer;
  static const Duration _defaultSessionTimeout = Duration(minutes: 5);

  // Rate limiting
  int _failedAttempts = 0;
  DateTime? _lockoutTime;
  static const int _maxFailedAttempts = 5;
  static const Duration _lockoutDuration = Duration(minutes: 15);

  // Encryption
  encrypt.Encrypter? _encrypter;
  final encrypt.IV _iv = encrypt.IV.fromLength(16);

  Future<void> initialize() async {
    await _initializeEncryption();
    await _loadSecuritySettings();
    _startSessionMonitoring();
  }

  // Biometric authentication
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) {
      // Web doesn't support biometric authentication
      return false;
    }
    
    try {
      final isAvailable = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      debugPrint('Biometric availability check error: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) {
      // Web doesn't support biometric authentication
      return [];
    }
    
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      debugPrint('Get available biometrics error: $e');
      return [];
    }
  }

  Future<bool> authenticateWithBiometrics({
    String? reason,
    bool useErrorDialogs = true,
    bool stickyAuth = false,
    bool biometricOnly = false,
  }) async {
    if (kIsWeb) {
      // Web doesn't support biometric authentication
      throw SecurityException('Biometric authentication not available on web');
    }

    // Check rate limiting
    if (_isLockedOut()) {
      throw SecurityException('Account temporarily locked due to too many failed attempts');
    }

    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw SecurityException('Biometric authentication not available');
      }

      final isAuthenticated = await _auth.authenticate(
        localizedReason: reason ?? 'Authenticate to access DayFi',
        options: AuthenticationOptions(
          useErrorDialogs: useErrorDialogs,
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
              );

      if (isAuthenticated) {
        _resetFailedAttempts();
        _updateLastAuthTime();
        return true;
      } else {
        _incrementFailedAttempts();
        return false;
      }
    } on PlatformException catch (e) {
      _incrementFailedAttempts();
      debugPrint('Biometric authentication error: $e');
      throw SecurityException('Authentication failed: ${e.message}');
    } catch (e) {
      _incrementFailedAttempts();
      debugPrint('Unexpected authentication error: $e');
      throw SecurityException('Authentication failed');
    }
  }

  Future<bool> enableBiometricAuthentication() async {
    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        throw SecurityException('Biometric authentication not available on this device');
      }

      // Test biometric authentication
      final isAuthenticated = await authenticateWithBiometrics(
        reason: 'Enable biometric authentication for DayFi',
      );

      if (isAuthenticated) {
        await _secureStorage.write(
          key: _biometricEnabledKey,
          value: 'true',
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Enable biometric error: $e');
      return false;
    }
  }

  Future<bool> disableBiometricAuthentication() async {
    try {
      await _secureStorage.delete(key: _biometricEnabledKey);
      return true;
    } catch (e) {
      debugPrint('Disable biometric error: $e');
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _secureStorage.read(key: _biometricEnabledKey);
      return value == 'true';
    } catch (e) {
      debugPrint('Check biometric enabled error: $e');
      return false;
    }
  }

  // Secure storage
  Future<void> storeSecureData(String key, String value) async {
    try {
      final encryptedValue = _encryptData(value);
      await _secureStorage.write(key: key, value: encryptedValue);
    } catch (e) {
      debugPrint('Store secure data error: $e');
      throw SecurityException('Failed to store secure data');
    }
  }

  Future<String?> getSecureData(String key) async {
    try {
      final encryptedValue = await _secureStorage.read(key: key);
      if (encryptedValue == null) return null;
      
      return _decryptData(encryptedValue);
    } catch (e) {
      debugPrint('Get secure data error: $e');
      throw SecurityException('Failed to retrieve secure data');
    }
  }

  Future<void> deleteSecureData(String key) async {
    try {
      await _secureStorage.delete(key: key);
    } catch (e) {
      debugPrint('Delete secure data error: $e');
      throw SecurityException('Failed to delete secure data');
    }
  }

  Future<void> clearAllSecureData() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      debugPrint('Clear secure data error: $e');
      throw SecurityException('Failed to clear secure data');
    }
  }

  // Session management
  void _updateLastAuthTime() {
    _lastAuthTime = DateTime.now();
    _resetSessionTimer();
  }

  void _resetSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = Timer(_defaultSessionTimeout, () {
      _onSessionTimeout();
    });
  }

  void _onSessionTimeout() {
    _sessionTimer = null;
    // Notify app about session timeout
    debugPrint('Session timeout - user needs to re-authenticate');
  }

  bool isSessionValid({Duration? customTimeout}) {
    if (_lastAuthTime == null) return false;
    
    final timeout = customTimeout ?? _defaultSessionTimeout;
    final elapsed = DateTime.now().difference(_lastAuthTime!);
    return elapsed < timeout;
  }

  void extendSession() {
    if (isSessionValid()) {
      _updateLastAuthTime();
    }
  }

  void _startSessionMonitoring() {
    // Monitor app lifecycle for session management
    // This would be integrated with app lifecycle callbacks
  }

  // Rate limiting
  bool _isLockedOut() {
    if (_lockoutTime == null) return false;
    
    final now = DateTime.now();
    if (now.difference(_lockoutTime!) > _lockoutDuration) {
      _lockoutTime = null;
      _failedAttempts = 0;
      return false;
    }
    
    return true;
  }

  void _incrementFailedAttempts() {
    _failedAttempts++;
    
    if (_failedAttempts >= _maxFailedAttempts) {
      _lockoutTime = DateTime.now();
      _secureStorage.write(key: _failedAttemptsKey, value: _failedAttempts.toString());
      _secureStorage.write(key: _lockoutTimeKey, value: _lockoutTime!.toIso8601String());
    }
  }

  void _resetFailedAttempts() {
    _failedAttempts = 0;
    _lockoutTime = null;
    _secureStorage.delete(key: _failedAttemptsKey);
    _secureStorage.delete(key: _lockoutTimeKey);
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final failedAttemptsStr = await _secureStorage.read(key: _failedAttemptsKey);
      final lockoutTimeStr = await _secureStorage.read(key: _lockoutTimeKey);
      
      if (failedAttemptsStr != null) {
        _failedAttempts = int.parse(failedAttemptsStr);
      }
      
      if (lockoutTimeStr != null) {
        _lockoutTime = DateTime.parse(lockoutTimeStr);
      }
    } catch (e) {
      debugPrint('Load security settings error: $e');
    }
  }

  // Encryption
  Future<void> _initializeEncryption() async {
    try {
      // Generate or retrieve encryption key
      String? encryptionKey = await _secureStorage.read(key: _encryptionKeyKey);
      
      if (encryptionKey == null) {
        // Use the prefix 'encrypt.' here
        final key = encrypt.Key.fromSecureRandom(32);
        encryptionKey = key.base64;
        await _secureStorage.write(key: _encryptionKeyKey, value: encryptionKey);
      }
      
      // Use the prefix 'encrypt.' for Key, Encrypter, and AES
      final key = encrypt.Key.fromBase64(encryptionKey);
      _encrypter = encrypt.Encrypter(encrypt.AES(key));
      
    } catch (e) {
      debugPrint('Initialize encryption error: $e');
      throw SecurityException('Failed to initialize encryption');
    }
  }

  String _encryptData(String data) {
    if (_encrypter == null) {
      throw SecurityException('Encryption not initialized');
    }
    
    try {
      final encrypted = _encrypter!.encrypt(data, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('Encryption error: $e');
      throw SecurityException('Failed to encrypt data');
    }
  }

  String _decryptData(String encryptedData) {
    if (_encrypter == null) {
      throw SecurityException('Encryption not initialized');
    }
    
    try {
      final encrypted = encrypt.Encrypted.fromBase64(encryptedData);
      return _encrypter!.decrypt(encrypted, iv: _iv);
    } catch (e) {
      debugPrint('Decryption error: $e');
      throw SecurityException('Failed to decrypt data');
    }
  }

  // Security utilities
  Future<bool> isDeviceSecure() async {
    try {
      // Check if device has secure features enabled
      final isSecure = await _auth.isDeviceSupported();
      
      // Additional checks could include:
      // - Screen lock enabled
      // - Device encryption
      // - Root/jailbreak detection
      
      return isSecure;
    } catch (e) {
      debugPrint('Device security check error: $e');
      return false;
    }
  }

  Future<SecurityScore> getSecurityScore() async {
    int score = 0;
    final List<String> recommendations = [];

    // Check biometric authentication
    final biometricEnabled = await isBiometricEnabled();
    if (biometricEnabled) {
      score += 25;
    } else {
      recommendations.add('Enable biometric authentication for enhanced security');
    }

    // Check device security
    final deviceSecure = await isDeviceSecure();
    if (deviceSecure) {
      score += 25;
    } else {
      recommendations.add('Enable device security features (screen lock, encryption)');
    }

    // Check session timeout
    final sessionValid = isSessionValid();
    if (sessionValid) {
      score += 25;
    } else {
      recommendations.add('Session timeout - re-authenticate to continue');
    }

    // Check failed attempts
    if (_failedAttempts == 0) {
      score += 25;
    } else {
      recommendations.add('Multiple failed authentication attempts detected');
    }

    return SecurityScore(
      score: score,
      maxScore: 100,
      recommendations: recommendations,
    );
  }

  // Data integrity
  String generateDataHash(String data) {
    return sha256.convert(utf8.encode(data)).toString();
  }

  Future<bool> verifyDataIntegrity(String key, String expectedHash) async {
    try {
      final data = await getSecureData(key);
      if (data == null) return false;
      
      final actualHash = generateDataHash(data);
      return actualHash == expectedHash;
    } catch (e) {
      debugPrint('Data integrity verification error: $e');
      return false;
    }
  }

  // Cleanup
  void dispose() {
    _sessionTimer?.cancel();
  }
}

// Security exceptions
class SecurityException implements Exception {
  final String message;
  
  const SecurityException(this.message);
  
  @override
  String toString() => 'SecurityException: $message';
}

// Security score
class SecurityScore {
  final int score;
  final int maxScore;
  final List<String> recommendations;

  SecurityScore({
    required this.score,
    required this.maxScore,
    required this.recommendations,
  });

  double get percentage => (score / maxScore) * 100;
  
  SecurityLevel get level {
    if (percentage >= 80) return SecurityLevel.excellent;
    if (percentage >= 60) return SecurityLevel.good;
    if (percentage >= 40) return SecurityLevel.fair;
    return SecurityLevel.poor;
  }
}

enum SecurityLevel {
  excellent,
  good,
  fair,
  poor,
}
