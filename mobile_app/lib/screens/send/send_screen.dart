// lib/screens/send/send_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_app/widgets/app_bottomsheet.dart';
import 'dart:async';
import '../../models/asset.dart';
import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';

class SendScreen extends ConsumerStatefulWidget {
  final String? initialAsset;
  const SendScreen({super.key, this.initialAsset});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  final _toController = TextEditingController();
  final _amountController = TextEditingController();
  final _memoController = TextEditingController();

  String _selectedAsset = 'USDC';
  bool _loading = false;
  bool _resolving = false;
  bool _invalidAmount = false;
  String? _amountError;
  Map<String, dynamic>? _resolvedRecipient;
  String? _recipientError;
  Timer? _debounce;
  String _sendRail = 'blockchain';
  List<Map<String, String>> _banks = [];
  String? _selectedBankCode;
  String? _selectedBankName;
  final _bankAccountController = TextEditingController();
  String? _resolvedBankAccountName;
  String? _lastBankTransferStatus;

  @override
  void initState() {
    super.initState();
    if (widget.initialAsset != null) {
      _selectedAsset = widget.initialAsset!;
    } else {
      // Auto-select USDC if user has balance, otherwise default to USDC
      final wallet = ref.read(walletProvider);
      if (wallet.usdcBalance > 0) {
        _selectedAsset = 'USDC';
      }
    }
    _amountController.addListener(
      () => _onAmountChanged(_amountController.text),
    );
    _toController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _toController.dispose();
    _amountController.dispose();
    _memoController.dispose();
    _bankAccountController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onAmountChanged(String val) {
    _debounce?.cancel();
    setState(() {
      _amountError = null;
      _invalidAmount = false;
    });
    if (val.isEmpty || double.tryParse(val) == null) return;
    _debounce = Timer(const Duration(milliseconds: 500), _validateAmount);
  }

  void _validateAmount() {
    final amount = double.tryParse(_amountController.text.trim());
    final available = _availableBalance(_selectedAsset);

    setState(() {
      if (amount == null) {
        _invalidAmount = false;
        _amountError = null;
      } else if (amount <= 0) {
        _invalidAmount = true;
        _amountError = 'Amount must be greater than 0';
      } else if (amount > available + 0.0001) {
        // ← epsilon tolerance
        _invalidAmount = true;
        _amountError =
            'Insufficient balance. Available: ${available.toStringAsFixed(2)} $_selectedAsset';
      } else {
        _invalidAmount = false;
        _amountError = null;
      }
    });
  }

  double _availableBalance(String asset) {
    final wallet = ref.read(walletProvider);
    if (asset == 'NGNT') return wallet.ngntBalance;
    return wallet.usdcBalance;
  }

  Future<void> _loadBanks() async {
    if (_banks.isNotEmpty) return;
    try {
      final res = await apiService.getNigeriaBanks();
      final raw = List<Map<String, dynamic>>.from(res['banks'] ?? []);
      if (!mounted) return;
      setState(() {
        _banks = raw
            .map((e) => {'code': '${e['code']}', 'name': '${e['name']}'})
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _resolveRecipient(String value) async {
    if (value.length < 3) {
      setState(() {
        _resolvedRecipient = null;
        _recipientError = null;
      });
      return;
    }
    setState(() {
      _resolving = true;
      _recipientError = null;
      _resolvedRecipient = null;
    });
    try {
      final result = await ref
          .read(walletProvider.notifier)
          .resolveRecipient(value);
      if (mounted) {
        if (result != null) {
          setState(() => _resolvedRecipient = result);
        } else {
          setState(() => _recipientError = 'Username or address not found');
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _recipientError = 'Username or address not found');
      }
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _send() async {
    final to = _toController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    final missingRecipient = _sendRail == 'blockchain' && to.isEmpty;
    if (missingRecipient || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid recipient and amount')),
      );
      return;
    }

    // Check for validation errors
    if (_invalidAmount) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_amountError ?? 'Invalid amount')));
      return;
    }

    setState(() => _loading = true);

    // Show loading dialog that persists
    if (!mounted) return;

    showDayFiBottomSheet(
      context: context,
      isDismissible: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 24),

            const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),

            const SizedBox(height: 24),

            Text(
              'Sending...',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Processing your payment',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 17,
                letterSpacing: -.5,
                height: 1.3,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );

    try {
      Map<String, dynamic> result;
      if (_sendRail == 'bank') {
        if (_selectedAsset != 'NGNT') {
          throw Exception('Bank transfer is available for NGNT only');
        }
        if (_selectedBankCode == null || _bankAccountController.text.trim().length != 10) {
          throw Exception('Select bank and enter a valid 10-digit account number');
        }
        if (_resolvedBankAccountName == null || _resolvedBankAccountName!.isEmpty) {
          throw Exception('Resolve beneficiary account before sending');
        }
        final idempotencyKey =
            '${_selectedBankCode}_${_bankAccountController.text.trim()}_${amount.toStringAsFixed(2)}_${DateTime.now().millisecondsSinceEpoch}';
        result = await apiService.withdrawToBank(
          ngntAmount: amount,
          bankCode: _selectedBankCode!,
          accountNumber: _bankAccountController.text.trim(),
          accountName: _resolvedBankAccountName!,
          idempotencyKey: idempotencyKey,
        );
        _lastBankTransferStatus = (result['status'] as String?)?.toLowerCase();
      } else {
        result = await apiService.sendFunds(
          to: _resolvedRecipient?['stellarAddress'] ?? to,
          amount: amount,
          asset: _selectedAsset,
          memo: _memoController.text.trim().isEmpty
              ? null
              : _memoController.text.trim(),
        );
      }
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        _showSendSuccess(result);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog

        // Show error with retry option
        showDayFiBottomSheet(
          context: context,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),

                Center(
                  child: Text(
                    'This transaction could not be completed. ${apiService.parseError(e)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 17,
                      letterSpacing: -.5,
                      height: 1.3,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),

                // Retry
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(MediaQuery.of(context).size.width, 48),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(.90),
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _send();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 20),
                    label: Text(
                      'Retry',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(.95),
                        fontSize: 15,
                      ),
                    ),
                  ),
                // .animate().fadeIn(delay: 500.ms),
                ),

                const SizedBox(height: 8),

                // Dismiss
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size(MediaQuery.of(context).size.width, 48),
                      side: const BorderSide(
                        color: Colors.transparent,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Center(
                      child: Text(
                        'Dismiss',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(.95),
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                // .animate().fadeIn(delay: 500.ms),
                ),
              ],
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSendSuccess(Map<String, dynamic> result) {
    final bankStatus = (_lastBankTransferStatus ?? '').toLowerCase();
    final isBank = _sendRail == 'bank';
    final isPending = isBank && bankStatus == 'pending';
    final isFailed = isBank && bankStatus == 'failed';
    final title = isBank
        ? (isPending ? 'Transfer Pending' : isFailed ? 'Transfer Failed' : 'Transfer Sent')
        : 'Sent!';
    final subtitle = isBank
        ? (isPending
            ? 'Your bank transfer is processing. We will update your transactions shortly.'
            : isFailed
                ? 'Bank transfer failed. Please retry with correct beneficiary details.'
                : '${_amountController.text} $_selectedAsset transfer submitted successfully.')
        : '${_amountController.text} $_selectedAsset sent successfully.';
    showDayFiBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),

            // ── Lottie success ──────────────────────────────
            Lottie.asset(
              'assets/animations/success.json',
              width: 120,
              height: 120,
              repeat: false,
            ),

            const SizedBox(height: 4),

            Text(
              title,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 10),

            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 17,
                letterSpacing: -.5,
                height: 1.3,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              textAlign: TextAlign.center,
            ),

            if (result['transaction']?['hash'] != null) ...[
              const SizedBox(height: 8),
              Text(
                'Tx: ${(result['transaction']['hash'] as String).substring(0, 12)}...',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(letterSpacing: 0.2),
              ),
            ],
            if (isBank && result['txRef'] != null) ...[
              const SizedBox(height: 6),
              Text(
                'Ref: ${result['txRef']}',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),

            // ── Done button ─────────────────────────────────
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                minimumSize: Size(MediaQuery.of(context).size.width, 48),
                side: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(.90),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                context.go('/mainshell');
              },
              child: Text(
                'Done',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(.95),
                  fontSize: 15,
                ),
              ),
            ),
                // .animate().fadeIn(delay: 500.ms),
          ],
        ),
      ),
    );
  }

  double _getEmojiHeight(String? emoji) {
    return emoji == 'assets/images/stellar.png' ? 38 : 40;
  }

  // ─── Asset bottom sheet ─────────────────────────────

  void _showAssetPicker() {
    const assets = kAssetList;

    showDayFiBottomSheet(
      context: context,
      // backgroundColor: Theme.of(context).colorScheme.surface,
      // shape: const RoundedRectangleBorder(
      //   borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      // ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Opacity(opacity: 0, child: Icon(Icons.close)),
                Text(
                  'Choose Asset to Send',
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    fontSize: 16,
                    letterSpacing: -.1,
                  ),
                ),
                InkWell(
                  splashColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ...assets.map((assetCode) {
              final asset = kAssets[assetCode]!;

              return InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                onTap: () {
                  setState(() {
                    _selectedAsset = assetCode;
                    _amountController.clear();
                    _amountError = null;
                    _invalidAmount = false;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    // border: Border.all(
                    //   color: isSelected
                    //       ? Theme.of(ctx).colorScheme.primary.withOpacity(0.3)
                    //       : Theme.of(
                    //           ctx,
                    //         ).colorScheme.onSurface.withOpacity(0.1),
                    // ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(54),
                        child: Image.asset(
                          asset.emoji,
                          height: _getEmojiHeight(asset.emoji),
                        ),
                      ),
                      const SizedBox(width: 14),

                      Text(
                        assetCode,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildSendBalanceInfo(String assetCode) {
    final available = _availableBalance(assetCode);

    // Show error if amount is invalid
    if (_invalidAmount && _amountError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _amountError!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: const Color(0xFFFFA726),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }

    // Show available balance
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'Available: ${available.toStringAsFixed(2)} $assetCode',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  bool get _canSendBankRail {
    return _selectedAsset == 'NGNT' &&
        _selectedBankCode != null &&
        _bankAccountController.text.trim().length == 10 &&
        (_resolvedBankAccountName?.isNotEmpty ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            '',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color!.withOpacity(.95),
              fontWeight: FontWeight.w500,
              fontSize: 16,
              letterSpacing: -0.1,
            ),
          ),
          leading: InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back_ios, size: 20),
          ),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Send USDC or NGNT',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center,
                      ),
                // .animate().fadeIn(),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        'Enter a username or wallet address.\nWe\'ll automatically detect and handle the transfer.',
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          fontSize: 14,
                          letterSpacing: -.1,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                // .animate().fadeIn(delay: 15.ms),
                    ),
                    const SizedBox(height: 24),

                    // Currency + Network dropdowns
                    Center(
                      child: SizedBox(
                        width: (MediaQuery.of(context).size.width * .5) - 8,
                        child: InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          onTap: _showAssetPicker,
                          child: _DropdownBox(
                            emoji: kAssets[_selectedAsset]!.emoji,
                            label: _selectedAsset,
                          ),
                        ),
                      ),
                // .animate().fadeIn(delay: 25.ms),
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _railChip('blockchain', 'Blockchain')),
                        const SizedBox(width: 8),
                        Expanded(child: _railChip('bank', 'Nigerian Bank')),
                      ],
                    ),
                    const SizedBox(height: 12),

                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: TextField(
                        controller: _toController,
                        autocorrect: false,
                        enabled: _sendRail == 'blockchain',
                        onChanged: (v) {
                          if (_sendRail == 'blockchain' && v.length > 2) _resolveRecipient(v);
                        },
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(.85),
                          fontSize: 15,
                          letterSpacing: -.1,
                        ),
                        decoration: InputDecoration(
                          hintStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(.35),
                                fontSize: 15,
                                letterSpacing: -.1,
                              ),
                          fillColor: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.1),
                          hintText: _sendRail == 'bank'
                              ? 'Blockchain recipient disabled on bank rail'
                              : 'Type recipient\'s username or wallet address',
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
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: _resolving
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    height: 16,
                                    width: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : _resolvedRecipient != null
                              ? Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SvgPicture.asset(
                                    'assets/icons/svgs/circle_check.svg',
                                    color: DayFiColors.green,
                                    height: 16,
                                  ),
                                )
                              : null,

                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 10,
                          ),
                        ),
                      ),
                // .animate().fadeIn(delay: 50.ms),
                    ),

                    if (_recipientError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          _recipientError!,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                fontSize: 12,
                              ),
                        ),
                      )
                    else if (_resolvedRecipient != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          _resolvedRecipient!['username'] ??
                              _resolvedRecipient!['address'] ??
                              'Recipient found on-chain',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: DayFiColors.green,
                                fontSize: 12,
                              ),
                        ),
                      ),

                    if (_sendRail == 'bank') ...[
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: DropdownButtonFormField<String>(
                          value: _selectedBankCode,
                          onTap: _loadBanks,
                          items: _banks
                              .map(
                                (b) => DropdownMenuItem<String>(
                                  value: b['code'],
                                  child: Text(b['name'] ?? ''),
                                ),
                              )
                              .toList(),
                          onChanged: (v) {
                            Map<String, String>? selected;
                            for (final b in _banks) {
                              if (b['code'] == v) {
                                selected = b;
                                break;
                              }
                            }
                            setState(() {
                              _selectedBankCode = v;
                              _selectedBankName = selected?['name'];
                              _resolvedBankAccountName = null;
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Select bank',
                            filled: true,
                            fillColor: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: TextField(
                          controller: _bankAccountController,
                          keyboardType: TextInputType.number,
                          maxLength: 10,
                          decoration: InputDecoration(
                            hintText: '10-digit account number',
                            counterText: '',
                            filled: true,
                            fillColor: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.1),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) async {
                            if (v.length == 10 && _selectedBankCode != null) {
                              try {
                                final r = await apiService.resolveBankAccount(
                                  bankCode: _selectedBankCode!,
                                  accountNumber: v,
                                );
                                if (mounted) {
                                  setState(() => _resolvedBankAccountName = r['accountName']?.toString());
                                }
                              } catch (_) {
                                if (mounted) setState(() => _resolvedBankAccountName = null);
                              }
                            } else {
                              setState(() => _resolvedBankAccountName = null);
                            }
                          },
                        ),
                      ),
                      if (_resolvedBankAccountName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 4),
                          child: Text(
                            '${_resolvedBankAccountName!} • ${_selectedBankName ?? ''}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: DayFiColors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      if (_resolvedBankAccountName == null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2, left: 4),
                          child: Text(
                            'Select bank + enter account number to resolve beneficiary',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],

                    const SizedBox(height: 20),

                    // Amount
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: TextField(
                        controller: _amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(.85),
                          fontSize: 15,
                          letterSpacing: -.1,
                        ),
                        decoration: InputDecoration(
                          hintStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(.35),
                                fontSize: 15,
                                letterSpacing: -.1,
                              ),
                          fillColor: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.1),
                          hintText: 'Enter amount (0.00)',
                          prefixText: _selectedAsset == 'USDC' ? '\$ ' : '',
                          suffixText: _selectedAsset,
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
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 10,
                          ),
                        ),
                      ),
                // .animate().fadeIn(delay: 100.ms),
                    ),

                    const SizedBox(height: 4),
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      onTap: () {
                        final maxAmount = _availableBalance(_selectedAsset);
                        _amountController.text = maxAmount.toStringAsFixed(
                          2,
                        );
                      },
                      child: _buildSendBalanceInfo(
                        kAssets[_selectedAsset]!.code,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Memo
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: TextField(
                        controller: _memoController,
                        maxLength: 28,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(.85),
                          fontSize: 15,
                          letterSpacing: -.1,
                        ),
                        decoration: InputDecoration(
                          hintStyle: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(.35),
                                fontSize: 15,
                                letterSpacing: -.1,
                              ),
                          fillColor: Theme.of(
                            context,
                          ).textTheme.bodySmall?.color?.withOpacity(0.1),
                          hintText: "Add memo (optional)",
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
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 10,
                          ),
                          counterText: '',
                        ),
                      ),
                // .animate().fadeIn(delay: 100.ms),
                    ),

                    const SizedBox(height: 20),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize:  Size(MediaQuery.of(context).size.width, 48),
                          side: BorderSide(
                            color:
                                _loading ||
                                    _invalidAmount ||
                                    _amountController.text.isEmpty ||
                                    (_sendRail == 'blockchain' &&
                                        _toController.text.trim().isEmpty) ||
                                    (_sendRail == 'bank' && !_canSendBankRail)
                                ? Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(.45)
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(.90),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed:
                            _loading ||
                                _invalidAmount ||
                                _amountController.text.isEmpty ||
                                (_sendRail == 'blockchain' &&
                                    _toController.text.trim().isEmpty) ||
                                (_sendRail == 'bank' && !_canSendBankRail)
                            ? null
                            : _send,
                        child: Text(
                          _sendRail == 'bank' ? 'Send to Bank' : 'Send',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color:
                                    _loading ||
                                        _invalidAmount ||
                                        _amountController.text.isEmpty ||
                                        (_sendRail == 'blockchain' &&
                                            _toController.text.trim().isEmpty) ||
                                        (_sendRail == 'bank' && !_canSendBankRail)
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(.45)
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(.90),
                                fontSize: 15,
                              ),
                        ),
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
    );
  }

  Widget _railChip(String value, String label) {
    final selected = _sendRail == value;
    return GestureDetector(
      onTap: () => setState(() => _sendRail = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── DropdownBox Widget ───────────────────────────────────────

class _DropdownBox extends StatelessWidget {
  final String? emoji;
  final String label;

  const _DropdownBox({this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: emoji != null ? 8 : 16,
        vertical: emoji != null ? 7.5 : 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.050),
        ),
      ),
      child: Row(
        children: [
          if (emoji != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(54),
              child: Image.asset(emoji!, height: 24),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.90),
                fontSize: 13.5,
                letterSpacing: -.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down,
            size: 20,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}

