// lib/screens/auth/business_onboarding_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';

enum AccountType {
  individual,
  registeredBusiness,
  otherEntity,
}

enum BusinessType {
  soleProprietorship,
  limitedLiability,
  publicLimited,
  partnership,
  ngo,
  religiousOrg,
  trust,
  other,
}

class BusinessOnboardingScreen extends ConsumerStatefulWidget {
  final String setupToken;

  const BusinessOnboardingScreen({super.key, required this.setupToken});

  @override
  ConsumerState<BusinessOnboardingScreen> createState() => _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState extends ConsumerState<BusinessOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Form data
  AccountType _selectedAccountType = AccountType.individual;
  BusinessType? _selectedBusinessType;
  
  // Individual Account fields
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bvnController = TextEditingController();
  final _businessDescriptionController = TextEditingController();
  
  // Registered Business fields
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _cacNumberController = TextEditingController();
  final _tinController = TextEditingController();
  final _directorNameController = TextEditingController();
  final _directorBvnController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessEmailController = TextEditingController();
  
  // Other Entity fields
  final _organizationNameController = TextEditingController();
  final _organizationTypeController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _organizationAddressController = TextEditingController();
  final _signatoryNameController = TextEditingController();
  final _signatoryBvnController = TextEditingController();
  final _organizationPhoneController = TextEditingController();
  final _organizationEmailController = TextEditingController();
  
  bool _isLoading = false;
  bool _agreeToTerms = false;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _bvnController.dispose();
    _businessDescriptionController.dispose();
    _businessNameController.dispose();
    _businessAddressController.dispose();
    _cacNumberController.dispose();
    _tinController.dispose();
    _directorNameController.dispose();
    _directorBvnController.dispose();
    _businessPhoneController.dispose();
    _businessEmailController.dispose();
    _organizationNameController.dispose();
    _organizationTypeController.dispose();
    _registrationNumberController.dispose();
    _organizationAddressController.dispose();
    _signatoryNameController.dispose();
    _signatoryBvnController.dispose();
    _organizationPhoneController.dispose();
    _organizationEmailController.dispose();
    super.dispose();
  }

  List<Widget> _buildPages() {
    switch (_selectedAccountType) {
      case AccountType.individual:
        return [
          _buildAccountTypeSelection(),
          _buildIndividualAccountInfo(),
          _buildTermsAndConditions(),
        ];
      case AccountType.registeredBusiness:
        return [
          _buildAccountTypeSelection(),
          _buildBusinessTypeSelection(),
          _buildRegisteredBusinessInfo(),
          _buildTermsAndConditions(),
        ];
      case AccountType.otherEntity:
        return [
          _buildAccountTypeSelection(),
          _buildOtherEntityTypeSelection(),
          _buildOtherEntityInfo(),
          _buildTermsAndConditions(),
        ];
    }
  }

  int get totalPages => _buildPages().length;

  void _nextPage() {
    if (_currentPage < totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage++);
    } else {
      _submitOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentPage--);
    }
  }

  Widget _buildAccountTypeSelection() {
    return _OnboardingPage(
      title: 'What type of account are you creating?',
      subtitle: 'Select the option that best describes your business',
      children: [
        _AccountTypeCard(
          icon: Icons.person,
          title: 'Individual Account',
          subtitle: 'For unregistered businesses. Anyone selling, building, or offering services without formal CAC registration.',
          isSelected: _selectedAccountType == AccountType.individual,
          onTap: () {
            setState(() => _selectedAccountType = AccountType.individual);
            _nextPage();
          },
        ),
        const SizedBox(height: 16),
        _AccountTypeCard(
          icon: Icons.business,
          title: 'Registered Business Account',
          subtitle: 'For CAC-registered businesses. Companies officially registered with the Corporate Affairs Commission.',
          isSelected: _selectedAccountType == AccountType.registeredBusiness,
          onTap: () {
            setState(() => _selectedAccountType = AccountType.registeredBusiness);
            _nextPage();
          },
        ),
        const SizedBox(height: 16),
        _AccountTypeCard(
          icon: Icons.handshake,
          title: 'Other Entities',
          subtitle: 'For Non-profits, Trusts, Religious Organisations and other entities.',
          isSelected: _selectedAccountType == AccountType.otherEntity,
          onTap: () {
            setState(() => _selectedAccountType = AccountType.otherEntity);
            _nextPage();
          },
        ),
      ],
    );
  }

  Widget _buildIndividualAccountInfo() {
    return _OnboardingPage(
      title: 'Tell us about yourself',
      subtitle: 'We need some information to set up your account',
      children: [
        _buildTextField(
          controller: _firstNameController,
          label: 'First Name',
          icon: Icons.person,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _lastNameController,
          label: 'Last Name',
          icon: Icons.person,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _addressController,
          label: 'Home Address',
          icon: Icons.home,
          maxLines: 2,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _bvnController,
          label: 'Bank Verification Number (BVN)',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty == true) return 'Required';
            if (value?.length != 11) return 'BVN must be 11 digits';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _businessDescriptionController,
          label: 'What do you do? (Business Description)',
          icon: Icons.work,
          maxLines: 3,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildBusinessTypeSelection() {
    return _OnboardingPage(
      title: 'Business Type',
      subtitle: 'Select your business registration type',
      children: [
        _BusinessTypeCard(
          title: 'Sole Proprietorship',
          isSelected: _selectedBusinessType == BusinessType.soleProprietorship,
          onTap: () => setState(() => _selectedBusinessType = BusinessType.soleProprietorship),
        ),
        const SizedBox(height: 12),
        _BusinessTypeCard(
          title: 'Limited Liability Company',
          isSelected: _selectedBusinessType == BusinessType.limitedLiability,
          onTap: () => setState(() => _selectedBusinessType = BusinessType.limitedLiability),
        ),
        const SizedBox(height: 12),
        _BusinessTypeCard(
          title: 'Public Limited Company',
          isSelected: _selectedBusinessType == BusinessType.publicLimited,
          onTap: () => setState(() => _selectedBusinessType = BusinessType.publicLimited),
        ),
        const SizedBox(height: 12),
        _BusinessTypeCard(
          title: 'Partnership',
          isSelected: _selectedBusinessType == BusinessType.partnership,
          onTap: () => setState(() => _selectedBusinessType = BusinessType.partnership),
        ),
      ],
    );
  }

  Widget _buildRegisteredBusinessInfo() {
    return _OnboardingPage(
      title: 'Business Information',
      subtitle: 'Provide your registered business details',
      children: [
        _buildTextField(
          controller: _businessNameController,
          label: 'Business Name (as registered with CAC)',
          icon: Icons.business,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _businessAddressController,
          label: 'Business Address',
          icon: Icons.location_on,
          maxLines: 2,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _cacNumberController,
          label: 'CAC Registration Number',
          icon: Icons.verified,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _tinController,
          label: 'Tax Identification Number (TIN)',
          icon: Icons.description,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _directorNameController,
          label: 'Director/Owner Full Name',
          icon: Icons.person,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _directorBvnController,
          label: 'Director/Owner BVN',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty == true) return 'Required';
            if (value?.length != 11) return 'BVN must be 11 digits';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _businessPhoneController,
          label: 'Business Phone Number',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _businessEmailController,
          label: 'Business Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildOtherEntityTypeSelection() {
    return _OnboardingPage(
      title: 'Organization Type',
      subtitle: 'Select your organization type',
      children: [
        _BusinessTypeCard(
          title: 'NGO / Non-Profit',
          isSelected: _selectedBusinessType == BusinessType.ngo,
          onTap: () => setState(() => _selectedBusinessType = BusinessType.ngo),
        ),
        const SizedBox(height: 12),
        _BusinessTypeCard(
          title: 'Religious Organisation',
          isSelected: _selectedBusinessType == BusinessType.religiousOrg,
          onTap: () => setState(() => _selectedBusinessType = BusinessType.religiousOrg),
        ),
        const SizedBox(height: 12),
        _BusinessTypeCard(
          title: 'Trust',
          isSelected: _selectedBusinessType == BusinessType.trust,
          onTap: () => setState(() => _selectedBusinessType = BusinessType.trust),
        ),
        const SizedBox(height: 12),
        _BusinessTypeCard(
          title: 'Other',
          isSelected: _selectedBusinessType == BusinessType.other,
          onTap: () => setState(() => _selectedBusinessType = BusinessType.other),
        ),
      ],
    );
  }

  Widget _buildOtherEntityInfo() {
    return _OnboardingPage(
      title: 'Organization Information',
      subtitle: 'Provide your organization details',
      children: [
        _buildTextField(
          controller: _organizationNameController,
          label: 'Organization Name',
          icon: Icons.business,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _organizationAddressController,
          label: 'Registered Address',
          icon: Icons.location_on,
          maxLines: 2,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _registrationNumberController,
          label: 'Registration Number (if applicable)',
          icon: Icons.verified,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _signatoryNameController,
          label: 'Authorized Signatory Full Name',
          icon: Icons.person,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _signatoryBvnController,
          label: 'Authorized Signatory BVN',
          icon: Icons.credit_card,
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value?.isEmpty == true) return 'Required';
            if (value?.length != 11) return 'BVN must be 11 digits';
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _organizationPhoneController,
          label: 'Organization Phone',
          icon: Icons.phone,
          keyboardType: TextInputType.phone,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _organizationEmailController,
          label: 'Organization Email',
          icon: Icons.email,
          keyboardType: TextInputType.emailAddress,
          validator: (value) => value?.isEmpty == true ? 'Required' : null,
        ),
      ],
    );
  }

  Widget _buildTermsAndConditions() {
    return _OnboardingPage(
      title: 'Terms and Conditions',
      subtitle: 'Please review and accept our terms',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By creating an account, you agree to:',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...[
                '• Terms of Service',
                '• Privacy Policy',
                '• Anti-Money Laundering (AML) Policy',
                '• BVN verification for compliance',
                '• Nigerian financial regulations',
              ].map((term) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  term,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Checkbox(
              value: _agreeToTerms,
              onChanged: (value) => setState(() => _agreeToTerms = value ?? false),
            ),
            Expanded(
              child: Text(
                'I agree to the Terms and Conditions',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _agreeToTerms && !_isLoading ? _submitOnboarding : null,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
          child: _isLoading
              ? const CircularProgressIndicator()
              : const Text('Complete Setup'),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int? maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }

  Future<void> _submitOnboarding() async {
    if (!_agreeToTerms) return;

    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> profileData = {
        'accountType': _selectedAccountType.name,
      };

      switch (_selectedAccountType) {
        case AccountType.individual:
          profileData.addAll({
            'fullName': '${_firstNameController.text} ${_lastNameController.text}',
            'phone': _phoneController.text,
            'homeAddress': _addressController.text,
            'bvn': _bvnController.text,
            'businessCategory': _businessDescriptionController.text,
          });
          break;
        case AccountType.registeredBusiness:
          profileData.addAll({
            'businessName': _businessNameController.text,
            'businessAddress': _businessAddressController.text,
            'businessType': _selectedBusinessType?.name,
            'cacRegistrationNumber': _cacNumberController.text,
            'taxIdentificationNumber': _tinController.text,
            'phone': _businessPhoneController.text,
            'businessEmail': _businessEmailController.text,
          });
          break;
        case AccountType.otherEntity:
          profileData.addAll({
            'businessName': _organizationNameController.text,
            'businessAddress': _organizationAddressController.text,
            'businessType': 'OTHER_ENTITY',
            'phone': _organizationPhoneController.text,
            'businessEmail': _organizationEmailController.text,
          });
          break;
      }

      // Submit to API
      String fullName = '';
      String businessName = '';
      String businessCategory = '';
      String? businessEmail;

      switch (_selectedAccountType) {
        case AccountType.individual:
          fullName = '${_firstNameController.text} ${_lastNameController.text}';
          businessName = fullName; // Use full name as business name for individuals
          businessCategory = _businessDescriptionController.text;
          break;
        case AccountType.registeredBusiness:
          fullName = _directorNameController.text;
          businessName = _businessNameController.text;
          businessCategory = _selectedBusinessType?.name ?? 'Business';
          businessEmail = _businessEmailController.text.trim().isEmpty 
              ? null 
              : _businessEmailController.text.trim();
          break;
        case AccountType.otherEntity:
          fullName = _signatoryNameController.text;
          businessName = _organizationNameController.text;
          businessCategory = 'Other Entity';
          businessEmail = _organizationEmailController.text.trim().isEmpty 
              ? null 
              : _organizationEmailController.text.trim();
          break;
      }

      await apiService.setupBusinessProfile(
        setupToken: widget.setupToken,
        fullName: fullName,
        businessName: businessName,
        businessCategory: businessCategory,
        businessEmail: businessEmail,
      );
      
      // Navigate to dashboard
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        IconButton(
                          onPressed: _previousPage,
                          icon: const Icon(Icons.arrow_back),
                        ),
                      const Spacer(),
                      Text(
                        'Business Setup',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_currentPage > 0) const SizedBox(width: 48),
                    ],
                  ),
                ),
                
                // Progress indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / totalPages,
                    backgroundColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // PageView
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: _buildPages(),
                  ),
                ),
                
                // Navigation buttons
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (_currentPage > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _previousPage,
                            child: const Text('Previous'),
                          ),
                        ),
                      if (_currentPage > 0) const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _currentPage < totalPages - 1 ? _nextPage : null,
                          child: Text(_currentPage < totalPages - 1 ? 'Next' : 'Complete'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _OnboardingPage({
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _AccountTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? Colors.white
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _BusinessTypeCard extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _BusinessTypeCard({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
          ],
        ),
      ),
    );
  }
}
