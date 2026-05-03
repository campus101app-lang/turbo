// lib/screens/auth/business_profile_screen.dart
//
// Replaces username_screen.dart entirely.
// Called from otp_screen.dart when step == 'setup_profile' (or 'setup_username').
// Collects: fullName, businessName, businessCategory, referralCode (optional).
// On submit → calls apiService.setupBusinessProfile() → gets token → creates
// NGNT + USDC trustlines → navigates to biometric screen.

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  'I\'m an individual / freelancer',
  'Other',
];

class BusinessProfileScreen extends StatefulWidget {
  final String setupToken;
  final bool isNewUser;
  final Map<String, dynamic> existingData;

  const BusinessProfileScreen({
    super.key,
    required this.setupToken,
    this.isNewUser = true,
    this.existingData = const {},
  });

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  OverlayEntry? _categoryOverlay;
  final _categoryKey = GlobalKey();

  String? _selectedCategory;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingData.isNotEmpty) {
      _fullNameController.text = widget.existingData['fullName'] ?? '';
      _businessNameController.text = widget.existingData['businessName'] ?? '';
      _referralCodeController.text = widget.existingData['referralCode'] ?? '';
      _selectedCategory = widget.existingData['businessCategory'];
    }
  }

  @override
  void dispose() {
    _categoryOverlay?.remove();
    _fullNameController.dispose();
    _businessNameController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  void _showCategoryPicker() {
    if (_categoryOverlay != null) {
      _categoryOverlay!.remove();
      _categoryOverlay = null;
      return;
    }

    final box = _categoryKey.currentContext!.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final size = box.size;

    _categoryOverlay = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                _categoryOverlay?.remove();
                _categoryOverlay = null;
                setState(() {});
              },
            ),
          ),
          Positioned(
            left: offset.dx,
            top: offset.dy + size.height + 4,
            width: size.width,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surface,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    shrinkWrap: true,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.06),
                    ),
                    itemBuilder: (ctx, i) {
                      final cat = _categories[i];
                      final selected = cat == _selectedCategory;
                      return InkWell(
                        onTap: () {
                          setState(() => _selectedCategory = cat);
                          _categoryOverlay?.remove();
                          _categoryOverlay = null;
                          setState(() {});
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 11,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  cat,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        fontSize: 14,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: selected
                                            ? Theme.of(context)
                                                .colorScheme
                                                .primary
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                      ),
                                ),
                              ),
                              if (selected)
                                Icon(
                                  Icons.check_rounded,
                                  size: 16,
                                  color:
                                      Theme.of(context).colorScheme.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    Overlay.of(context).insert(_categoryOverlay!);
    setState(() {});
  }

  // ── Submit ─────────────────────────────────────────────────────────────────

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select what you do')),
      );
      return;
    }
    if (_loading) return;
    setState(() => _loading = true);

    try {
      final result = await apiService.setupBusinessProfile(
        setupToken: widget.setupToken,
        fullName: _fullNameController.text.trim(),
        businessName: _businessNameController.text.trim(),
        businessCategory: _selectedCategory!,
        referralCode: _referralCodeController.text.trim().isEmpty
            ? null
            : _referralCodeController.text.trim().toUpperCase(),
      );

      if (!mounted) return;

      context.pushReplacement(
        '/auth/business-onboarding',
        extra: {
          'setupToken': result['setupToken'] ?? '',
          'isNewUser': widget.isNewUser,
        },
      );
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
            color:
                Theme.of(context).colorScheme.onSurface.withOpacity(.35),
            fontSize: 15,
            letterSpacing: -.1,
          ),
      fillColor:
          Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.1),
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
      contentPadding:
          const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
    );
  }

  TextStyle get _fieldStyle =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 15,
            letterSpacing: -.1,
          );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final canSubmit = _fullNameController.text.trim().isNotEmpty &&
        _businessNameController.text.trim().isNotEmpty &&
        _selectedCategory != null;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Align(
              alignment: Alignment.topCenter,
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
                            child:
                                const Icon(Icons.arrow_back_ios, size: 20),
                          ),
                        ),

                      const SizedBox(height: 24),

                      Text(
                        'Your profile',
                        style: Theme.of(context)
                            .textTheme
                            .labelLarge!
                            .copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1,
                              height: 1.09,
                            ),
                        textAlign: TextAlign.center,
                      )
                          .animate()
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 8),

                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Text(
                          'A few things to help personalize your experience.',
                          style:
                              Theme.of(context).textTheme.bodyMedium!.copyWith(
                                    fontSize: 16,
                                    letterSpacing: -.5,
                                    height: 1.3,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Full name ────────────────────────────────────────────
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: TextFormField(
                          controller: _fullNameController,
                          style: _fieldStyle,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => setState(() {}),
                          decoration: _fieldDecoration('Full name'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // ── Display name ─────────────────────────────────────────
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: TextFormField(
                          controller: _businessNameController,
                          style: _fieldStyle,
                          textCapitalization: TextCapitalization.words,
                          onChanged: (_) => setState(() {}),
                          decoration: _fieldDecoration('Display name'),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Required'
                              : null,
                        ),
                      ),

                      // const SizedBox(height: 12),

                      // // ── What do you do picker ────────────────────────────────
                      // ConstrainedBox(
                      //   constraints: const BoxConstraints(maxWidth: 360),
                      //   child: GestureDetector(
                      //     key: _categoryKey,
                      //     onTap: _loading ? null : _showCategoryPicker,
                      //     child: Container(
                      //       width: double.infinity,
                      //       padding: const EdgeInsets.only(
                      //         left: 14,
                      //         top: 12,
                      //         bottom: 12,
                      //         right: 10,
                      //       ),
                      //       decoration: BoxDecoration(
                      //         color: Theme.of(context)
                      //             .textTheme
                      //             .bodySmall
                      //             ?.color
                      //             ?.withOpacity(0.1),
                      //         borderRadius: BorderRadius.circular(12),
                      //       ),
                      //       child: Row(
                      //         children: [
                      //           Expanded(
                      //             child: Text(
                      //               _selectedCategory ?? 'What do you do?',
                      //               style: Theme.of(context)
                      //                   .textTheme
                      //                   .bodyMedium
                      //                   ?.copyWith(
                      //                     color: _selectedCategory != null
                      //                         ? Theme.of(context)
                      //                             .colorScheme
                      //                             .onSurface
                      //                         : Theme.of(context)
                      //                             .colorScheme
                      //                             .onSurface
                      //                             .withOpacity(.35),
                      //                     fontSize: 15,
                      //                     letterSpacing: -.1,
                      //                   ),
                      //             ),
                      //           ),
                      //           Icon(
                      //             Icons.keyboard_arrow_down_rounded,
                      //             color: Theme.of(context)
                      //                 .colorScheme
                      //                 .onSurface
                      //                 .withOpacity(0.2),
                      //           ),
                      //         ],
                      //       ),
                      //     ),
                      //   ),
                      // ),

                      const SizedBox(height: 12),

                      // ── Referral code (optional) ─────────────────────────────
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: TextFormField(
                          controller: _referralCodeController,
                          style: _fieldStyle,
                          textCapitalization: TextCapitalization.characters,
                          decoration:
                              _fieldDecoration('Referral code (optional)'),
                        ),
                      ),

                      const SizedBox(height: 48),

                      AuthButton(
                        label: 'Continue',
                        onPressed:
                            canSubmit && !_loading ? _continue : null,
                        isLoading: _loading,
                        isValid: canSubmit,
                      ),

                      const SizedBox(height: 6),

                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Text.rich(
                          TextSpan(
                            text: 'By continuing, I agree to the ',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withOpacity(0.85),
                                      fontSize: 12,
                                      height: 1.4,
                                      letterSpacing: -.05,
                                    ),
                            children: [
                              TextSpan(
                                text: 'Terms of Service',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      decoration: TextDecoration.underline,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 12,
                                      letterSpacing: -.05,
                                    ),
                              ),
                              const TextSpan(text: ' & '),
                              TextSpan(
                                text: 'Privacy Statement',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      decoration: TextDecoration.underline,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      fontSize: 12,
                                      letterSpacing: -.05,
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
        ),
      ),
    );
  }
}