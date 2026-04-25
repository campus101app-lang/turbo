// lib/providers/organization_provider.dart
//
// Organization Provider for DayFi
// Manages organization state and operations
//

import 'package:flutter_riverpod/flutter_riverpod.dart';

class OrganizationState {
  final Map<String, dynamic>? organization;
  final List<Map<String, dynamic>> members;
  final List<Map<String, dynamic>> departments;
  final bool isLoading;
  final String? error;

  OrganizationState({
    this.organization,
    this.members = const [],
    this.departments = const [],
    this.isLoading = false,
    this.error,
  });

  OrganizationState copyWith({
    Map<String, dynamic>? organization,
    List<Map<String, dynamic>>? members,
    List<Map<String, dynamic>>? departments,
    bool? isLoading,
    String? error,
  }) {
    return OrganizationState(
      organization: organization ?? this.organization,
      members: members ?? this.members,
      departments: departments ?? this.departments,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class OrganizationProvider extends StateNotifier<OrganizationState> {
  OrganizationProvider() : super(OrganizationState());

  Future<void> loadOrganizationData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      final organization = {
        'id': '1',
        'name': 'DayFi Technologies Ltd',
        'email': 'info@dayfi.com',
        'phone': '+234-123-456-7890',
        'address': '123 Tech Hub, Lagos, Nigeria',
        'website': 'https://dayfi.com',
        'logo': 'assets/images/logo.png',
        'industry': 'Financial Technology',
        'size': '50-100',
        'type': 'Limited Liability Company',
        'registrationNumber': 'RC123456',
        'taxId': 'TIN789012',
        'createdAt': '2020-01-01',
        'status': 'active',
      };

      final members = [
        {
          'id': '1',
          'name': 'John Doe',
          'email': 'john@dayfi.com',
          'role': 'CEO',
          'department': 'Management',
          'joinedAt': '2020-01-01',
          'status': 'active',
        },
        {
          'id': '2',
          'name': 'Jane Smith',
          'email': 'jane@dayfi.com',
          'role': 'CTO',
          'department': 'Technology',
          'joinedAt': '2020-02-01',
          'status': 'active',
        },
      ];

      final departments = [
        {
          'id': '1',
          'name': 'Management',
          'description': 'Executive management team',
          'headId': '1',
          'memberCount': 2,
        },
        {
          'id': '2',
          'name': 'Technology',
          'description': 'Software development and IT',
          'headId': '2',
          'memberCount': 15,
        },
        {
          'id': '3',
          'name': 'Finance',
          'description': 'Financial operations and accounting',
          'headId': null,
          'memberCount': 8,
        },
      ];

      state = state.copyWith(
        organization: organization,
        members: members,
        departments: departments,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> updateOrganization(Map<String, dynamic> updates) async {
    state = state.copyWith(isLoading: true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      final updatedOrganization = {
        ...state.organization!,
        ...updates,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      state = state.copyWith(
        organization: updatedOrganization,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> addMember(Map<String, dynamic> memberData) async {
    state = state.copyWith(isLoading: true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      final newMember = {
        ...memberData,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'joinedAt': DateTime.now().toIso8601String().split('T')[0],
        'status': 'active',
      };

      state = state.copyWith(
        members: [...state.members, newMember],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> removeMember(String memberId) async {
    state = state.copyWith(isLoading: true);

    try {
      await Future.delayed(const Duration(seconds: 1));

      final updatedMembers = state.members.where((member) => member['id'] != memberId).toList();

      state = state.copyWith(
        members: updatedMembers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Provider
final organizationProvider = StateNotifierProvider<OrganizationProvider, OrganizationState>(
  (ref) => OrganizationProvider(),
);
