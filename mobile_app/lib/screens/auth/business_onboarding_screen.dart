// lib/screens/auth/business_onboarding_screen.dart
//
// Step 2 of 2 in onboarding.
// Collects KYC / compliance data based on account type chosen.
// Design matches email_screen / otp_screen / business_profile_screen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/widgets/app_background.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_button.dart';

enum AccountType { individual, registeredBusiness, otherEntity }

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
  final bool isNewUser;

  const BusinessOnboardingScreen({
    super.key,
    required this.setupToken,
    this.isNewUser = true,
  });

  @override
  ConsumerState<BusinessOnboardingScreen> createState() =>
      _BusinessOnboardingScreenState();
}

class _BusinessOnboardingScreenState
    extends ConsumerState<BusinessOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  AccountType _selectedAccountType = AccountType.individual;
  BusinessType? _selectedBusinessType;

  // Individual
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _bvnController = TextEditingController();
  final _businessDescriptionController = TextEditingController();

  // Registered Business
  final _businessNameController = TextEditingController();
  final _businessAddressController = TextEditingController();
  final _cacNumberController = TextEditingController();
  final _tinController = TextEditingController();
  final _directorNameController = TextEditingController();
  final _directorBvnController = TextEditingController();
  final _businessPhoneController = TextEditingController();
  final _businessEmailController = TextEditingController();

  // Other Entity
  final _organizationNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _organizationAddressController = TextEditingController();
  final _signatoryNameController = TextEditingController();
  final _signatoryBvnController = TextEditingController();
  final _organizationPhoneController = TextEditingController();
  final _organizationEmailController = TextEditingController();

  bool _isLoading = false;
  bool _agreeToTerms = false;

  List<_PageDef>? _pages;
  final _formKeys = <int, GlobalKey<FormState>>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _pages = _buildPageDefs();
  }

  void _rebuildPages() {
    setState(() {
      _pages = _buildPageDefs();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final c in [
      _firstNameController, _lastNameController, _phoneController,
      _addressController, _bvnController, _businessDescriptionController,
      _businessNameController, _businessAddressController, _cacNumberController,
      _tinController, _directorNameController, _directorBvnController,
      _businessPhoneController, _businessEmailController,
      _organizationNameController, _registrationNumberController,
      _organizationAddressController, _signatoryNameController,
      _signatoryBvnController, _organizationPhoneController,
      _organizationEmailController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── Page definitions ──────────────────────────────────────────────────────

  List<_PageDef> _buildPageDefs() {
    switch (_selectedAccountType) {
      case AccountType.individual:
        return [
          _PageDef(title: 'Account type', widget: _buildAccountTypeSelection()),
          _PageDef(title: 'Your details', widget: _buildIndividualInfo()),
          _PageDef(title: 'Review & agree', widget: _buildTermsPage()),
        ];
      case AccountType.registeredBusiness:
        return [
          _PageDef(title: 'Account type', widget: _buildAccountTypeSelection()),
          _PageDef(title: 'Business type', widget: _buildBusinessTypeSelection()),
          _PageDef(title: 'Business details', widget: _buildRegisteredBusinessInfo()),
          _PageDef(title: 'Review & agree', widget: _buildTermsPage()),
        ];
      case AccountType.otherEntity:
        return [
          _PageDef(title: 'Account type', widget: _buildAccountTypeSelection()),
          _PageDef(title: 'Entity type', widget: _buildOtherEntityTypeSelection()),
          _PageDef(title: 'Entity details', widget: _buildOtherEntityInfo()),
          _PageDef(title: 'Review & agree', widget: _buildTermsPage()),
        ];
    }
  }

  int get _totalPages => _pages?.length ?? 1;
  bool get _isLastPage => _currentPage == _totalPages - 1;
  bool get _isTypePage =>
      _currentPage == 1 &&
      _selectedAccountType != AccountType.individual; // business-type step

  // ─── Navigation ────────────────────────────────────────────────────────────

  void _nextPage() {
    if (_isLastPage) {
      _submitOnboarding();
      return;
    }
    // Validate current form if it has one
    final key = _formKeys[_currentPage];
    if (key != null && !(key.currentState?.validate() ?? true)) return;

    _pageController.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage++);
  }

  void _previousPage() {
    if (_currentPage == 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
    setState(() => _currentPage--);
  }

  // ─── "Next" button label / enabled ────────────────────────────────────────

  String get _nextLabel {
    if (_isLastPage) return _isLoading ? 'Setting up…' : 'Complete Setup';
    return 'Continue';
  }

  bool get _nextEnabled {
    if (_isLoading) return false;
    if (_isLastPage) return _agreeToTerms;
    if (_currentPage == 0) return true; // account type always chosen
    if (_isTypePage) return _selectedBusinessType != null;
    return true;
  }

  // ─── Page builders ─────────────────────────────────────────────────────────

  Widget _buildAccountTypeSelection() {
    return _ScrollPage(
      children: [
        _TypeCard(
          icon: Icons.person_outline_rounded,
          title: 'Individual Account',
          subtitle:
              'For unregistered businesses — freelancers, traders, or anyone operating without CAC registration.',
          isSelected: _selectedAccountType == AccountType.individual,
          onTap: () {
            setState(() => _selectedAccountType = AccountType.individual);
            _rebuildPages();
            Future.delayed(const Duration(milliseconds: 120), _nextPage);
          },
        ),
        const SizedBox(height: 12),
        _TypeCard(
          icon: Icons.business_outlined,
          title: 'Registered Business',
          subtitle:
              'For CAC-registered companies officially incorporated with the Corporate Affairs Commission.',
          isSelected: _selectedAccountType == AccountType.registeredBusiness,
          onTap: () {
            setState(() => _selectedAccountType = AccountType.registeredBusiness);
            _rebuildPages();
            Future.delayed(const Duration(milliseconds: 120), _nextPage);
          },
        ),
        const SizedBox(height: 12),
        _TypeCard(
          icon: Icons.handshake_outlined,
          title: 'Other Entities',
          subtitle:
              'For NGOs, trusts, religious organisations, and other non-commercial entities.',
          isSelected: _selectedAccountType == AccountType.otherEntity,
          onTap: () {
            setState(() => _selectedAccountType = AccountType.otherEntity);
            _rebuildPages();
            Future.delayed(const Duration(milliseconds: 120), _nextPage);
          },
        ),
      ],
    );
  }

  Widget _buildIndividualInfo() {
    final key = _formKeys.putIfAbsent(1, () => GlobalKey<FormState>());
    return Form(
      key: key,
      child: _ScrollPage(
        children: [
          // Subtle info banner
          _InfoBanner(
            'This information is for your personal profile and is used for identity verification (KYC).',
          ),
          const SizedBox(height: 20),
          _Field(
            controller: _firstNameController,
            hint: 'First name',
            textCapitalization: TextCapitalization.words,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _lastNameController,
            hint: 'Last name',
            textCapitalization: TextCapitalization.words,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _phoneController,
            hint: 'Phone number (e.g. 08012345678)',
            keyboardType: TextInputType.phone,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _addressController,
            hint: 'Home address',
            maxLines: 2,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _bvnController,
            hint: 'Bank Verification Number (BVN)',
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (v.trim().length != 11) return 'BVN must be 11 digits';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _businessDescriptionController,
            hint: 'What do you do? (e.g. I sell clothes online)',
            maxLines: 3,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessTypeSelection() {
    return _ScrollPage(
      children: [
        _InfoBanner('Select how your business is registered with the CAC.'),
        const SizedBox(height: 20),
        for (final entry in [
          (BusinessType.soleProprietorship, 'Sole Proprietorship',
              'Business name registered under one individual owner.'),
          (BusinessType.limitedLiability, 'Limited Liability Company (LLC)',
              'Private company with limited liability — most common for SMEs.'),
          (BusinessType.publicLimited, 'Public Limited Company (PLC)',
              'Publicly listed company with shares traded on the market.'),
          (BusinessType.partnership, 'Partnership',
              'Two or more persons running a business together.'),
        ]) ...[
          _TypeCard(
            title: entry.$2,
            subtitle: entry.$3,
            isSelected: _selectedBusinessType == entry.$1,
            onTap: () => setState(() => _selectedBusinessType = entry.$1),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildRegisteredBusinessInfo() {
    final key = _formKeys.putIfAbsent(2, () => GlobalKey<FormState>());
    return Form(
      key: key,
      child: _ScrollPage(
        children: [
          _InfoBanner(
            'We need your director\'s details for regulatory compliance. '
            'This is separate from your business profile.',
          ),
          const SizedBox(height: 20),

          _SectionLabel('Business Details'),
          const SizedBox(height: 10),
          _Field(
            controller: _businessNameController,
            hint: 'Business name (as on CAC certificate)',
            textCapitalization: TextCapitalization.words,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _businessAddressController,
            hint: 'Registered business address',
            maxLines: 2,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _cacNumberController,
            hint: 'CAC Registration Number (RC/BN Number)',
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _tinController,
            hint: 'Tax Identification Number (TIN)',
            keyboardType: TextInputType.number,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _businessPhoneController,
            hint: 'Business phone number',
            keyboardType: TextInputType.phone,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _businessEmailController,
            hint: 'Business email (optional)',
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 28),
          _SectionLabel('Director / Owner Details'),
          const SizedBox(height: 4),
          Text(
            'Required for KYC. This person must be listed on the CAC documents.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.45),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _directorNameController,
            hint: 'Director\'s full legal name',
            textCapitalization: TextCapitalization.words,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _directorBvnController,
            hint: 'Director\'s BVN',
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (v.trim().length != 11) return 'BVN must be 11 digits';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOtherEntityTypeSelection() {
    return _ScrollPage(
      children: [
        _InfoBanner('Select the type that best describes your organisation.'),
        const SizedBox(height: 20),
        for (final entry in [
          (BusinessType.ngo, 'NGO / Non-Profit',
              'Registered not-for-profit pursuing a social mission.'),
          (BusinessType.religiousOrg, 'Religious Organisation',
              'Church, mosque, or other registered faith-based body.'),
          (BusinessType.trust, 'Trust',
              'Legal arrangement where assets are held for beneficiaries.'),
          (BusinessType.other, 'Other Entity',
              'Any other registered entity not listed above.'),
        ]) ...[
          _TypeCard(
            title: entry.$2,
            subtitle: entry.$3,
            isSelected: _selectedBusinessType == entry.$1,
            onTap: () => setState(() => _selectedBusinessType = entry.$1),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }

  Widget _buildOtherEntityInfo() {
    final key = _formKeys.putIfAbsent(2, () => GlobalKey<FormState>());
    return Form(
      key: key,
      child: _ScrollPage(
        children: [
          _InfoBanner(
            'Provide details of your authorised signatory — the person legally '
            'empowered to operate this account on behalf of the organisation.',
          ),
          const SizedBox(height: 20),

          _SectionLabel('Organisation Details'),
          const SizedBox(height: 10),
          _Field(
            controller: _organizationNameController,
            hint: 'Organisation name',
            textCapitalization: TextCapitalization.words,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _organizationAddressController,
            hint: 'Registered address',
            maxLines: 2,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _registrationNumberController,
            hint: 'Registration number (if applicable)',
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _organizationPhoneController,
            hint: 'Organisation phone number',
            keyboardType: TextInputType.phone,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _organizationEmailController,
            hint: 'Organisation email (optional)',
            keyboardType: TextInputType.emailAddress,
          ),

          const SizedBox(height: 28),
          _SectionLabel('Authorised Signatory'),
          const SizedBox(height: 4),
          Text(
            'This person acts on behalf of the organisation and is accountable for this account.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.45),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          _Field(
            controller: _signatoryNameController,
            hint: 'Signatory\'s full legal name',
            textCapitalization: TextCapitalization.words,
            validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _signatoryBvnController,
            hint: 'Signatory\'s BVN',
            keyboardType: TextInputType.number,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Required';
              if (v.trim().length != 11) return 'BVN must be 11 digits';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTermsPage() {
    return _ScrollPage(
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'By completing setup, you confirm that:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withOpacity(0.85),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              for (final item in [
                ('✦', 'All information provided is true and accurate'),
                ('✦', 'You agree to our Terms of Service & Privacy Policy'),
                ('✦', 'You consent to BVN verification for identity checks'),
                ('✦', 'You will comply with CBN and Nigerian AML regulations'),
                ('✦',
                    'You understand DayFi may request additional documents for compliance'),
              ])
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 10,
                          height: 1.8,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.65),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Agree checkbox
        GestureDetector(
          onTap: () => setState(() => _agreeToTerms = !_agreeToTerms),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _agreeToTerms
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _agreeToTerms
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: _agreeToTerms
                    ? const Icon(Icons.check_rounded,
                        color: Colors.white, size: 14)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'I have read and I agree to all the above',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submitOnboarding() async {
    if (!_agreeToTerms || _isLoading) return;
    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> payload = {
        'setupToken': widget.setupToken,
        'accountType': _selectedAccountType.name,
      };

      switch (_selectedAccountType) {
        case AccountType.individual:
          payload.addAll({
            'fullName':
                '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
            'phone': _phoneController.text.trim(),
            'homeAddress': _addressController.text.trim(),
            'bvn': _bvnController.text.trim(),
            'businessDescription': _businessDescriptionController.text.trim(),
          });
          break;
        case AccountType.registeredBusiness:
          payload.addAll({
            'fullName': _directorNameController.text.trim(),
            'businessName': _businessNameController.text.trim(),
            'businessAddress': _businessAddressController.text.trim(),
            'businessType': _selectedBusinessType?.name,
            'cacRegistrationNumber': _cacNumberController.text.trim(),
            'taxIdentificationNumber': _tinController.text.trim(),
            'bvn': _directorBvnController.text.trim(),
            'phone': _businessPhoneController.text.trim(),
            'businessEmail': _businessEmailController.text.trim().isEmpty
                ? null
                : _businessEmailController.text.trim(),
          });
          break;
        case AccountType.otherEntity:
          payload.addAll({
            'fullName': _signatoryNameController.text.trim(),
            'businessName': _organizationNameController.text.trim(),
            'businessAddress': _organizationAddressController.text.trim(),
            'businessType': _selectedBusinessType?.name ?? 'other',
            'registrationNumber': _registrationNumberController.text.trim(),
            'bvn': _signatoryBvnController.text.trim(),
            'phone': _organizationPhoneController.text.trim(),
            'businessEmail': _organizationEmailController.text.trim().isEmpty
                ? null
                : _organizationEmailController.text.trim(),
          });
          break;
      }

      final result = await apiService.setupBusinessOnboarding(payload);

      if (result['token'] != null) {
        await apiService.saveToken(result['token']);
      }

      if (!mounted) return;
      widget.isNewUser ? context.go('/auth/biometric') : context.go('/mainshell');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiService.parseError(e)),
            backgroundColor: DayFiColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final pages = _pages;
    if (pages == null) return const SizedBox.shrink();

    final pageTitle = pages[_currentPage].title;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Header ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 16, 16, 0),
                child: Row(
                  children: [
                    if (_currentPage > 0)
                      InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        onTap: _previousPage,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(Icons.arrow_back_ios, size: 20),
                        ),
                      )
                    else
                      const SizedBox(width: 36),
                    const Spacer(),
                    Text(
                      'Business Setup',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    // Step counter
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentPage + 1}/${_totalPages}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Progress bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / _totalPages,
                    minHeight: 3,
                    backgroundColor:
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(primary),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Page title & subtitle ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _pageHeadline,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Text(
                        _pageSubheadline,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              letterSpacing: -0.3,
                              height: 1.35,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── PageView ─────────────────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: pages.map((p) => p.widget).toList(),
                ),
              ),

              // ── Bottom CTA ───────────────────────────────────────────────
              // Only show explicit Next button on non-selection pages
              // (selection pages auto-advance on tap)
              if (_currentPage != 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: AuthButton(
                    label: _nextLabel,
                    onPressed: _nextEnabled ? _nextPage : null,
                    isLoading: _isLoading,
                    loadingText: 'Setting up…',
                    isValid: _nextEnabled,
                  ),
                ),

              const SizedBox(height: 6),

              // Terms line (matches email screen)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text.rich(
                    TextSpan(
                      text: 'Step 2 of 2 — KYC & compliance. Your data is ',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.45),
                            fontSize: 11,
                            height: 1.4,
                          ),
                      children: [
                        TextSpan(
                          text: 'encrypted and never sold.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                decoration: TextDecoration.underline,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.65),
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  String get _pageHeadline {
    switch (_currentPage) {
      case 0:
        return 'What type of\naccount?';
      default:
        if (_selectedAccountType == AccountType.individual) {
          switch (_currentPage) {
            case 1:
              return 'About you';
            case 2:
              return 'Almost done';
          }
        } else if (_selectedAccountType == AccountType.registeredBusiness) {
          switch (_currentPage) {
            case 1:
              return 'Business type';
            case 2:
              return 'Business\ndetails';
            case 3:
              return 'Almost done';
          }
        } else {
          switch (_currentPage) {
            case 1:
              return 'Entity type';
            case 2:
              return 'Organisation\ndetails';
            case 3:
              return 'Almost done';
          }
        }
        return 'Setup';
    }
  }

  String get _pageSubheadline {
    switch (_currentPage) {
      case 0:
        return 'Choose the option that best describes your business.';
      default:
        if (_selectedAccountType == AccountType.individual) {
          switch (_currentPage) {
            case 1:
              return 'Your personal and business details for identity verification.';
            case 2:
              return 'Review and accept to complete your account setup.';
          }
        } else if (_selectedAccountType == AccountType.registeredBusiness) {
          switch (_currentPage) {
            case 1:
              return 'How is your business registered with the CAC?';
            case 2:
              return 'Your business details plus your director\'s info for KYC.';
            case 3:
              return 'Review and accept to complete your account setup.';
          }
        } else {
          switch (_currentPage) {
            case 1:
              return 'Select the category that matches your organisation.';
            case 2:
              return 'Organisation details plus your authorised signatory\'s info.';
            case 3:
              return 'Review and accept to complete your account setup.';
          }
        }
        return '';
    }
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _PageDef {
  final String title;
  final Widget widget;
  const _PageDef({required this.title, required this.widget});
}

class _ScrollPage extends StatelessWidget {
  final List<Widget> children;
  const _ScrollPage({required this.children});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 16,
            color: Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.65),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Theme.of(context).colorScheme.primary.withOpacity(0.85),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const _Field({
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.maxLines,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      textCapitalization: textCapitalization,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.85),
            fontSize: 15,
            letterSpacing: -.1,
          ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(.35),
              fontSize: 15,
              letterSpacing: -.1,
            ),
        fillColor:
            Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.2),
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: DayFiColors.error.withOpacity(0.6),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: DayFiColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      ),
      validator: validator,
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeCard({
    this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? primary.withOpacity(0.1) : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? primary : Colors.white.withOpacity(0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? Colors.white : Colors.white.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? primary : Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.45),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AnimatedOpacity(
              opacity: isSelected ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.check_circle_rounded, color: primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}