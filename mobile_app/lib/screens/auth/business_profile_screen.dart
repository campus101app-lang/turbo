// lib/screens/auth/business_profile_screen.dart
//
// Replaces username_screen.dart entirely.
// Called from otp_screen.dart when step == 'setup_profile' (or 'setup_username').
// Collects: fullName, businessName, businessCategory, businessEmail (optional).
// On submit → calls apiService.setupBusinessProfile() → gets token → creates
// NGNT + USDC trustlines → navigates to biometric screen.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/auth_button.dart';
import '../../widgets/app_background.dart';

const _categories = [
  'Retail & E-commerce',
  'Food & Beverages',
  'Professional Services',
  'Technology',
  'Healthcare',
  'Education',
  'Logistics & Delivery',
  'Construction & Real Estate',
  'Agriculture',
  'Media & Entertainment',
  'Finance & Fintech',
  'Other',
];

class BusinessProfileScreen extends StatefulWidget {
  final String setupToken;
  final Map<String, dynamic>? existingProfile; // Add this parameter

  const BusinessProfileScreen({super.key, required this.setupToken, this.existingProfile});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController    = TextEditingController();
  final _businessNameController= TextEditingController();
  final _businessEmailController = TextEditingController();

  String? _selectedCategory;
  bool _loading = false;
  int  _currentStep = 0;

  final List<String> _steps = [
    'Saving profile...',
    'Creating wallet...',
    'Funding account...',
    'Adding USDC trustline...',
    'Adding NGNT trustline...',
    'Almost done...',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill form with existing profile data if available
    if (widget.existingProfile != null) {
      final profile = widget.existingProfile!;
      _fullNameController.text = profile['fullName'] ?? '';
      _businessNameController.text = profile['businessName'] ?? '';
      _businessEmailController.text = profile['businessEmail'] ?? '';
      _selectedCategory = profile['businessCategory'];
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _businessNameController.dispose();
    _businessEmailController.dispose();
    super.dispose();
  }

  void _showCategoryPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text('Business Category',
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 6),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
                  ),
                  itemBuilder: (ctx, i) {
                    final cat = _categories[i];
                    final selected = cat == _selectedCategory;
                    return ListTile(
                      splashColor: Colors.transparent,
                      title: Text(cat,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                      ),
                      trailing: selected
                          ? Icon(Icons.check_rounded,
                              color: Theme.of(context).colorScheme.primary)
                          : null,
                      onTap: () {
                        setState(() => _selectedCategory = cat);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a business category')),
      );
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);

    try {
      setState(() => _currentStep = 0);
      await Future.delayed(const Duration(milliseconds: 400));

      setState(() => _currentStep = 1);

      // Main call — backend creates wallet + funds it + adds USDC & NGNT trustlines
      final result = await apiService.setupBusinessProfile(
        setupToken:      widget.setupToken,
        fullName:        _fullNameController.text.trim(),
        businessName:    _businessNameController.text.trim(),
        businessCategory: _selectedCategory!,
        businessEmail:   _businessEmailController.text.trim().isEmpty
            ? null
            : _businessEmailController.text.trim(),
      );

      setState(() => _currentStep = 2);
      await Future.delayed(const Duration(milliseconds: 500));
      setState(() => _currentStep = 3);
      await Future.delayed(const Duration(milliseconds: 600));
      setState(() => _currentStep = 4);
      await Future.delayed(const Duration(milliseconds: 700));
      setState(() => _currentStep = 5);
      await Future.delayed(const Duration(milliseconds: 400));

      await apiService.saveToken(result['token']);
      if (mounted) context.go('/auth/biometric');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(apiService.parseError(e)),
            backgroundColor: DayFiColors.red,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  InputDecoration _fieldDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(.35),
        fontSize: 15,
        letterSpacing: -.1,
      ),
      fillColor: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.2),
      filled: true,
      suffixIcon: suffix,
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
        borderSide: BorderSide.none,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    );
  }

  TextStyle get _fieldStyle =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
        color: Theme.of(context).colorScheme.onSurface.withOpacity(.85),
        fontSize: 15,
        letterSpacing: -.1,
      );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canSubmit =
        _fullNameController.text.trim().isNotEmpty &&
        _businessNameController.text.trim().isNotEmpty &&
        _selectedCategory != null;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  if (context.canPop())
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        splashColor: Colors.transparent,
                        highlightColor: Colors.transparent,
                        hoverColor: Colors.transparent,
                        onTap: () => context.pop(),
                        child: const Icon(Icons.arrow_back_ios, size: 20),
                      ),
                    ),

                  const SizedBox(height: 24),

                  Text(
                    'Set up your\nbusiness profile',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.8,
                      fontSize: 36,
                      height: 1.09,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 10),

                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Text(
                      'We\'ll use this to personalise your invoices, expenses, and payment links.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        letterSpacing: -0.3,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // ── Full name ──────────────────────────────────────────────
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: TextFormField(
                      controller: _fullNameController,
                      style: _fieldStyle,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      decoration: _fieldDecoration('Full name'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Business name ──────────────────────────────────────────
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: TextFormField(
                      controller: _businessNameController,
                      style: _fieldStyle,
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() {}),
                      decoration: _fieldDecoration('Business name'),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Required' : null,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Business category picker ───────────────────────────────
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: GestureDetector(
                      onTap: _loading ? null : _showCategoryPicker,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _selectedCategory ?? 'Business category',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: _selectedCategory != null
                                          ? Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(.85)
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(.35),
                                      fontSize: 15,
                                      letterSpacing: -.1,
                                    ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Business email (optional) ──────────────────────────────
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: TextFormField(
                      controller: _businessEmailController,
                      style: _fieldStyle,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _fieldDecoration(
                        'Business email (optional — for invoices)',
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                  ),

                  const Spacer(),

                  AuthButton(
                    label: 'Create my account',
                    onPressed: canSubmit && !_loading ? _continue : null,
                    isLoading: _loading,
                    loadingText: _steps[_currentStep],
                    isValid: canSubmit,
                  ),

                  const SizedBox(height: 6),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Text.rich(
                      TextSpan(
                        text: 'By continuing, I agree to the ',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                          fontSize: 12,
                          height: 1.4,
                        ),
                        children: [
                          TextSpan(
                            text: 'Terms of Service',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  decoration: TextDecoration.underline,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.8),
                                  fontSize: 12,
                                ),
                          ),
                          const TextSpan(text: ' & '),
                          TextSpan(
                            text: 'Privacy Statement',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  decoration: TextDecoration.underline,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withOpacity(0.8),
                                  fontSize: 12,
                                ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}