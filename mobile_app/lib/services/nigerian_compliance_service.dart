// lib/services/nigerian_compliance_service.dart
//
// Nigerian Business Compliance Service
// Handles BVN verification, CAC registration validation, TIN support, and local compliance
//

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum BusinessType {
  individual,
  registeredBusiness,
  otherEntity,
}

enum ComplianceStatus {
  pending,
  verified,
  rejected,
  expired,
  requiresAction,
}

class NigerianComplianceService {
  static final NigerianComplianceService _instance = NigerianComplianceService._internal();
  factory NigerianComplianceService() => _instance;
  NigerianComplianceService._internal();

  static const String _baseUrl = 'https://api.dayfi.me/compliance';
  static const String _bvnVerificationEndpoint = '/bvn/verify';
  static const String _cacValidationEndpoint = '/cac/validate';
  static const String _tinValidationEndpoint = '/tin/validate';
  static const String _complianceReportEndpoint = '/report/generate';

  // Cache keys
  static const String _bvnCacheKey = 'compliance_bvn_cache';
  static const String _cacCacheKey = 'compliance_cac_cache';
  static const String _tinCacheKey = 'compliance_tin_cache';
  static const String _businessProfileKey = 'compliance_business_profile';

  // BVN verification
  Future<BVNVerificationResult> verifyBVN(String bvn, {
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? phoneNumber,
  }) async {
    try {
      // Validate BVN format
      if (!_isValidBVN(bvn)) {
        return BVNVerificationResult(
          isValid: false,
          error: 'Invalid BVN format. BVN must be 11 digits.',
        );
      }

      // Check cache first
      final cachedResult = await _getCachedBVNResult(bvn);
      if (cachedResult != null && !cachedResult.isExpired()) {
        return cachedResult;
      }

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl$_bvnVerificationEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bvn': bvn,
          'firstName': firstName,
          'lastName': lastName,
          'dateOfBirth': dateOfBirth,
          'phoneNumber': phoneNumber,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = BVNVerificationResult.fromJson(data);
        
        // Cache the result
        await _cacheBVNResult(bvn, result);
        
        return result;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return BVNVerificationResult(
          isValid: false,
          error: errorData['message'] as String? ?? 'BVN verification failed',
        );
      }
    } catch (e) {
      debugPrint('BVN verification error: $e');
      return BVNVerificationResult(
        isValid: false,
        error: 'Network error during BVN verification',
      );
    }
  }

  // CAC registration validation
  Future<CACValidationResult> validateCACRegistration({
    required String rcNumber,
    required String businessName,
    String? businessAddress,
    String? incorporationDate,
    String? businessType,
  }) async {
    try {
      // Validate RC number format
      if (!_isValidRCNumber(rcNumber)) {
        return CACValidationResult(
          isValid: false,
          error: 'Invalid RC number format.',
        );
      }

      // Check cache first
      final cachedResult = await _getCachedCACResult(rcNumber);
      if (cachedResult != null && !cachedResult.isExpired()) {
        return cachedResult;
      }

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl$_cacValidationEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'rcNumber': rcNumber,
          'businessName': businessName,
          'businessAddress': businessAddress,
          'incorporationDate': incorporationDate,
          'businessType': businessType,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = CACValidationResult.fromJson(data);
        
        // Cache the result
        await _cacheCACResult(rcNumber, result);
        
        return result;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return CACValidationResult(
          isValid: false,
          error: errorData['message'] as String? ?? 'CAC validation failed',
        );
      }
    } catch (e) {
      debugPrint('CAC validation error: $e');
      return CACValidationResult(
        isValid: false,
        error: 'Network error during CAC validation',
      );
    }
  }

  // TIN validation
  Future<TINValidationResult> validateTIN(String tin, {
    String? businessName,
    String? businessAddress,
    BusinessType? businessType,
  }) async {
    try {
      // Validate TIN format
      if (!_isValidTIN(tin)) {
        return TINValidationResult(
          isValid: false,
          error: 'Invalid TIN format. TIN must be 10 digits.',
        );
      }

      // Check cache first
      final cachedResult = await _getCachedTINResult(tin);
      if (cachedResult != null && !cachedResult.isExpired()) {
        return cachedResult;
      }

      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl$_tinValidationEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tin': tin,
          'businessName': businessName,
          'businessAddress': businessAddress,
          'businessType': businessType?.name,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final result = TINValidationResult.fromJson(data);
        
        // Cache the result
        await _cacheTINResult(tin, result);
        
        return result;
      } else {
        final errorData = jsonDecode(response.body) as Map<String, dynamic>;
        return TINValidationResult(
          isValid: false,
          error: errorData['message'] as String? ?? 'TIN validation failed',
        );
      }
    } catch (e) {
      debugPrint('TIN validation error: $e');
      return TINValidationResult(
        isValid: false,
        error: 'Network error during TIN validation',
      );
    }
  }

  // Complete business compliance check
  Future<BusinessComplianceResult> checkBusinessCompliance({
    required BusinessType businessType,
    String? bvn,
    String? rcNumber,
    String? tin,
    String? businessName,
    String? businessAddress,
  }) async {
    final result = BusinessComplianceResult(
      businessType: businessType,
      status: ComplianceStatus.pending,
      checks: {},
    );

    // BVN check (required for all business types)
    if (bvn != null) {
      final bvnResult = await verifyBVN(bvn);
      result.checks['bvn'] = bvnResult;
      if (!bvnResult.isValid) {
        result.status = ComplianceStatus.requiresAction;
        result.errors.add('BVN verification failed: ${bvnResult.error}');
      }
    } else {
      result.status = ComplianceStatus.requiresAction;
      result.errors.add('BVN is required for business registration');
    }

    // CAC check (required for registered business)
    if (businessType == BusinessType.registeredBusiness) {
      if (rcNumber != null && businessName != null) {
        final cacResult = await validateCACRegistration(
          rcNumber: rcNumber,
          businessName: businessName,
          businessAddress: businessAddress,
        );
        result.checks['cac'] = cacResult;
        if (!cacResult.isValid) {
          result.status = ComplianceStatus.requiresAction;
          result.errors.add('CAC validation failed: ${cacResult.error}');
        }
      } else {
        result.status = ComplianceStatus.requiresAction;
        result.errors.add('RC number and business name required for registered business');
      }
    }

    // TIN check (required for all business types)
    if (tin != null && businessName != null) {
      final tinResult = await validateTIN(tin, businessName: businessName, businessAddress: businessAddress, businessType: businessType);
      result.checks['tin'] = tinResult;
      if (!tinResult.isValid) {
        result.status = ComplianceStatus.requiresAction;
        result.errors.add('TIN validation failed: ${tinResult.error}');
      }
    } else {
      result.status = ComplianceStatus.requiresAction;
      result.errors.add('TIN and business name required for compliance');
    }

    // Update status if all checks passed
    if (result.errors.isEmpty) {
      result.status = ComplianceStatus.verified;
    }

    // Save business profile
    await _saveBusinessProfile(result);

    return result;
  }

  // Generate compliance report
  Future<ComplianceReport> generateComplianceReport(String businessId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_complianceReportEndpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'businessId': businessId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ComplianceReport.fromJson(data);
      } else {
        throw Exception('Failed to generate compliance report');
      }
    } catch (e) {
      debugPrint('Compliance report generation error: $e');
      rethrow;
    }
  }

  // Validation helpers
  bool _isValidBVN(String bvn) {
    return RegExp(r'^\d{11}$').hasMatch(bvn);
  }

  bool _isValidRCNumber(String rcNumber) {
    return RegExp(r'^RC\d{9}$').hasMatch(rcNumber) || 
           RegExp(r'^BN\d{9}$').hasMatch(rcNumber);
  }

  bool _isValidTIN(String tin) {
    return RegExp(r'^\d{10}$').hasMatch(tin);
  }

  // Cache management
  Future<BVNVerificationResult?> _getCachedBVNResult(String bvn) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_bvnCacheKey$bvn';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final data = jsonDecode(cachedData) as Map<String, dynamic>;
        final result = BVNVerificationResult.fromJson(data);
        
        // Check if cache is expired (24 hours)
        final cacheTime = DateTime.parse(data['cacheTime'] as String);
        if (DateTime.now().difference(cacheTime).inHours < 24) {
          return result;
        }
      }
    } catch (e) {
      debugPrint('Error getting cached BVN result: $e');
    }
    return null;
  }

  Future<void> _cacheBVNResult(String bvn, BVNVerificationResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_bvnCacheKey$bvn';
      final data = {
        ...result.toJson(),
        'cacheTime': DateTime.now().toIso8601String(),
      };
      await prefs.setString(cacheKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error caching BVN result: $e');
    }
  }

  Future<CACValidationResult?> _getCachedCACResult(String rcNumber) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacCacheKey$rcNumber';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final data = jsonDecode(cachedData) as Map<String, dynamic>;
        final result = CACValidationResult.fromJson(data);
        
        // Check if cache is expired (7 days)
        final cacheTime = DateTime.parse(data['cacheTime'] as String);
        if (DateTime.now().difference(cacheTime).inDays < 7) {
          return result;
        }
      }
    } catch (e) {
      debugPrint('Error getting cached CAC result: $e');
    }
    return null;
  }

  Future<void> _cacheCACResult(String rcNumber, CACValidationResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_cacCacheKey$rcNumber';
      final data = {
        ...result.toJson(),
        'cacheTime': DateTime.now().toIso8601String(),
      };
      await prefs.setString(cacheKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error caching CAC result: $e');
    }
  }

  Future<TINValidationResult?> _getCachedTINResult(String tin) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_tinCacheKey$tin';
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData != null) {
        final data = jsonDecode(cachedData) as Map<String, dynamic>;
        final result = TINValidationResult.fromJson(data);
        
        // Check if cache is expired (30 days)
        final cacheTime = DateTime.parse(data['cacheTime'] as String);
        if (DateTime.now().difference(cacheTime).inDays < 30) {
          return result;
        }
      }
    } catch (e) {
      debugPrint('Error getting cached TIN result: $e');
    }
    return null;
  }

  Future<void> _cacheTINResult(String tin, TINValidationResult result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = '$_tinCacheKey$tin';
      final data = {
        ...result.toJson(),
        'cacheTime': DateTime.now().toIso8601String(),
      };
      await prefs.setString(cacheKey, jsonEncode(data));
    } catch (e) {
      debugPrint('Error caching TIN result: $e');
    }
  }

  Future<void> _saveBusinessProfile(BusinessComplianceResult profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_businessProfileKey, jsonEncode(profile.toJson()));
    } catch (e) {
      debugPrint('Error saving business profile: $e');
    }
  }

  Future<BusinessComplianceResult?> getBusinessProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileData = prefs.getString(_businessProfileKey);
      
      if (profileData != null) {
        final data = jsonDecode(profileData) as Map<String, dynamic>;
        return BusinessComplianceResult.fromJson(data);
      }
    } catch (e) {
      debugPrint('Error getting business profile: $e');
    }
    return null;
  }

  // Clear compliance cache
  Future<void> clearComplianceCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = [
        _bvnCacheKey,
        _cacCacheKey,
        _tinCacheKey,
        _businessProfileKey,
      ];

      for (final key in keys) {
        // Remove all keys with this prefix
        final allKeys = prefs.getKeys();
        for (final k in allKeys) {
          if (k.startsWith(key)) {
            await prefs.remove(k);
          }
        }
      }
    } catch (e) {
      debugPrint('Error clearing compliance cache: $e');
    }
  }
}

// Compliance result classes
class BVNVerificationResult {
  final bool isValid;
  final String? bvn;
  final String? firstName;
  final String? lastName;
  final String? dateOfBirth;
  final String? phoneNumber;
  final String? bank;
  final String? error;
  final DateTime? verifiedAt;

  BVNVerificationResult({
    required this.isValid,
    this.bvn,
    this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.phoneNumber,
    this.bank,
    this.error,
    this.verifiedAt,
  });

  factory BVNVerificationResult.fromJson(Map<String, dynamic> json) {
    return BVNVerificationResult(
      isValid: json['isValid'] as bool,
      bvn: json['bvn'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      bank: json['bank'] as String?,
      error: json['error'] as String?,
      verifiedAt: json['verifiedAt'] != null 
          ? DateTime.parse(json['verifiedAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'bvn': bvn,
      'firstName': firstName,
      'lastName': lastName,
      'dateOfBirth': dateOfBirth,
      'phoneNumber': phoneNumber,
      'bank': bank,
      'error': error,
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }

  bool isExpired() {
    if (verifiedAt == null) return true;
    return DateTime.now().difference(verifiedAt!).inDays > 1;
  }
}

class CACValidationResult {
  final bool isValid;
  final String? rcNumber;
  final String? businessName;
  final String? businessAddress;
  final String? incorporationDate;
  final String? businessType;
  final String? registeredOffice;
  final String? error;
  final DateTime? validatedAt;

  CACValidationResult({
    required this.isValid,
    this.rcNumber,
    this.businessName,
    this.businessAddress,
    this.incorporationDate,
    this.businessType,
    this.registeredOffice,
    this.error,
    this.validatedAt,
  });

  factory CACValidationResult.fromJson(Map<String, dynamic> json) {
    return CACValidationResult(
      isValid: json['isValid'] as bool,
      rcNumber: json['rcNumber'] as String?,
      businessName: json['businessName'] as String?,
      businessAddress: json['businessAddress'] as String?,
      incorporationDate: json['incorporationDate'] as String?,
      businessType: json['businessType'] as String?,
      registeredOffice: json['registeredOffice'] as String?,
      error: json['error'] as String?,
      validatedAt: json['validatedAt'] != null 
          ? DateTime.parse(json['validatedAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'rcNumber': rcNumber,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'incorporationDate': incorporationDate,
      'businessType': businessType,
      'registeredOffice': registeredOffice,
      'error': error,
      'validatedAt': validatedAt?.toIso8601String(),
    };
  }

  bool isExpired() {
    if (validatedAt == null) return true;
    return DateTime.now().difference(validatedAt!).inDays > 7;
  }
}

class TINValidationResult {
  final bool isValid;
  final String? tin;
  final String? businessName;
  final String? businessAddress;
  final String? taxOffice;
  final String? error;
  final DateTime? validatedAt;

  TINValidationResult({
    required this.isValid,
    this.tin,
    this.businessName,
    this.businessAddress,
    this.taxOffice,
    this.error,
    this.validatedAt,
  });

  factory TINValidationResult.fromJson(Map<String, dynamic> json) {
    return TINValidationResult(
      isValid: json['isValid'] as bool,
      tin: json['tin'] as String?,
      businessName: json['businessName'] as String?,
      businessAddress: json['businessAddress'] as String?,
      taxOffice: json['taxOffice'] as String?,
      error: json['error'] as String?,
      validatedAt: json['validatedAt'] != null 
          ? DateTime.parse(json['validatedAt'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isValid': isValid,
      'tin': tin,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'taxOffice': taxOffice,
      'error': error,
      'validatedAt': validatedAt?.toIso8601String(),
    };
  }

  bool isExpired() {
    if (validatedAt == null) return true;
    return DateTime.now().difference(validatedAt!).inDays > 30;
  }
}

class BusinessComplianceResult {
  final BusinessType businessType;
  ComplianceStatus status;
  final Map<String, dynamic> checks;
  final List<String> errors;
  DateTime? lastChecked;

  BusinessComplianceResult({
    required this.businessType,
    required this.status,
    required this.checks,
    this.errors = const [],
    this.lastChecked,
  });

  factory BusinessComplianceResult.fromJson(Map<String, dynamic> json) {
    return BusinessComplianceResult(
      businessType: BusinessType.values.firstWhere(
        (e) => e.name == json['businessType'],
        orElse: () => BusinessType.individual,
      ),
      status: ComplianceStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ComplianceStatus.pending,
      ),
      checks: json['checks'] as Map<String, dynamic>,
      errors: (json['errors'] as List<dynamic>).map((e) => e as String).toList(),
      lastChecked: json['lastChecked'] != null 
          ? DateTime.parse(json['lastChecked'] as String) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessType': businessType.name,
      'status': status.name,
      'checks': checks,
      'errors': errors,
      'lastChecked': lastChecked?.toIso8601String(),
    };
  }

  bool isCompliant() => status == ComplianceStatus.verified && errors.isEmpty;
}

class ComplianceReport {
  final String reportId;
  final String businessId;
  final DateTime generatedAt;
  final Map<String, dynamic> complianceData;
  final List<String> recommendations;
  final String? pdfUrl;

  ComplianceReport({
    required this.reportId,
    required this.businessId,
    required this.generatedAt,
    required this.complianceData,
    required this.recommendations,
    this.pdfUrl,
  });

  factory ComplianceReport.fromJson(Map<String, dynamic> json) {
    return ComplianceReport(
      reportId: json['reportId'] as String,
      businessId: json['businessId'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      complianceData: json['complianceData'] as Map<String, dynamic>,
      recommendations: (json['recommendations'] as List<dynamic>).map((e) => e as String).toList(),
      pdfUrl: json['pdfUrl'] as String?,
    );
  }
}
