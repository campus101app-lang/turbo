// lib/screens/send/send_screen.dart
//
// Payments hub — selection-first nested flow.
// User picks a payment method, then enters a dedicated sub-form.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_app/widgets/app_bottomsheet.dart';

import '../../providers/wallet_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

// ── View states ────────────────────────────────────────────────────────────────

enum _SendView { selection, blockchainUsdc, blockchainNgnt, bankTransfer, paymentRequest }

// ── SendScreen ─────────────────────────────────────────────────────────────────

class SendScreen extends ConsumerStatefulWidget {
  final String? initialAsset;
  final bool insideShell;
  const SendScreen({super.key, this.initialAsset, this.insideShell = false});

  @override
  ConsumerState<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends ConsumerState<SendScreen> {
  _SendView _view = _SendView.selection;

  @override
  void initState() {
    super.initState();
    if (widget.initialAsset == 'NGNT') _view = _SendView.blockchainNgnt;
    if (widget.initialAsset == 'USDC') _view = _SendView.blockchainUsdc;
  }

  void _goBack() => setState(() => _view = _SendView.selection);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: switch (_view) {
            _SendView.selection => _SelectionView(
                key: const ValueKey('selection'),
                onSelect: (v) => setState(() => _view = v),
              ),
            _SendView.blockchainUsdc => _BlockchainSendView(
                key: const ValueKey('usdc'),
                asset: 'USDC',
                onBack: _goBack,
              ),
            _SendView.blockchainNgnt => _BlockchainSendView(
                key: const ValueKey('ngnt'),
                asset: 'NGNT',
                onBack: _goBack,
              ),
            _SendView.bankTransfer => _BankTransferView(
                key: const ValueKey('bank'),
                onBack: _goBack,
              ),
            _SendView.paymentRequest => _PaymentRequestView(
                key: const ValueKey('request'),
                onBack: _goBack,
              ),
          },
        ),
      ),
    );
  }
}

// ── Selection hub ──────────────────────────────────────────────────────────────

class _SelectionView extends ConsumerWidget {
  final void Function(_SendView) onSelect;
  const _SelectionView({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final wallet = ref.watch(walletProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payments',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how you want to send money.',
                style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.45)),
              ),
              const SizedBox(height: 24),

              _MethodCard(
                icon: Icons.account_balance_rounded,
                iconColor: const Color(0xFF008751),
                iconBg: const Color(0xFF008751).withOpacity(0.1),
                title: 'Bank Transfer',
                subtitle: 'Send NGNT to any Nigerian bank account',
                badge: '₦ NGN',
                onTap: () => onSelect(_SendView.bankTransfer),
              ),
              const SizedBox(height: 10),

              _MethodCard(
                icon: Icons.attach_money_rounded,
                iconColor: const Color(0xFF2775CA),
                iconBg: const Color(0xFF2775CA).withOpacity(0.1),
                title: 'Send USDC',
                subtitle: 'Send to DayFi username or Stellar address',
                badge: '\$ USDC',
                balanceLabel: '\$${wallet.usdcBalance.toStringAsFixed(2)}',
                onTap: () => onSelect(_SendView.blockchainUsdc),
              ),
              const SizedBox(height: 10),

              _MethodCard(
                icon: Icons.currency_exchange_rounded,
                iconColor: const Color(0xFF008751),
                iconBg: const Color(0xFF008751).withOpacity(0.1),
                title: 'Send NGNT',
                subtitle: 'Send digital naira via Stellar network',
                badge: '₦ NGNT',
                balanceLabel: '₦${wallet.ngntBalance.toStringAsFixed(2)}',
                onTap: () => onSelect(_SendView.blockchainNgnt),
              ),
              const SizedBox(height: 10),

              _MethodCard(
                icon: Icons.link_rounded,
                iconColor: const Color(0xFF9C27B0),
                iconBg: const Color(0xFF9C27B0).withOpacity(0.1),
                title: 'Request Money',
                subtitle: 'Create a payment link to share via WhatsApp',
                badge: 'Link',
                onTap: () => onSelect(_SendView.paymentRequest),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MethodCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor, iconBg;
  final String title, subtitle, badge;
  final String? balanceLabel;
  final VoidCallback onTap;

  const _MethodCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.badge,
    this.balanceLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.onSurface.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.bricolageGrotesque(
                          fontSize: 15, fontWeight: FontWeight.w700, color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: iconColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.45)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (balanceLabel != null)
                  Text(
                    balanceLabel!,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 13, fontWeight: FontWeight.w600, color: cs.primary,
                    ),
                  ),
                const SizedBox(height: 2),
                Icon(Icons.arrow_forward_ios_rounded, size: 13, color: cs.onSurface.withOpacity(0.3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Blockchain send sub-flow ───────────────────────────────────────────────────

class _BlockchainSendView extends ConsumerStatefulWidget {
  final String asset;
  final VoidCallback onBack;
  const _BlockchainSendView({super.key, required this.asset, required this.onBack});

  @override
  ConsumerState<_BlockchainSendView> createState() => _BlockchainSendViewState();
}

class _BlockchainSendViewState extends ConsumerState<_BlockchainSendView> {
  final _toCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _memoCtrl = TextEditingController();

  bool _loading = false, _resolving = false, _invalidAmount = false;
  String? _amountError, _recipientError;
  Map<String, dynamic>? _resolvedRecipient;
  Timer? _debounce;

  @override
  void dispose() {
    _toCtrl.dispose();
    _amountCtrl.dispose();
    _memoCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  double get _available {
    final w = ref.read(walletProvider);
    return widget.asset == 'NGNT' ? w.ngntBalance : w.usdcBalance;
  }

  void _onAmountChanged(String v) {
    _debounce?.cancel();
    setState(() { _amountError = null; _invalidAmount = false; });
    if (v.isEmpty || double.tryParse(v) == null) return;
    _debounce = Timer(const Duration(milliseconds: 400), _validateAmount);
  }

  void _validateAmount() {
    final amt = double.tryParse(_amountCtrl.text.trim());
    setState(() {
      if (amt == null || amt <= 0) {
        _invalidAmount = true;
        _amountError = 'Enter a valid amount';
      } else if (amt > _available + 0.0001) {
        _invalidAmount = true;
        _amountError = 'Insufficient balance. Available: ${_available.toStringAsFixed(2)} ${widget.asset}';
      } else {
        _invalidAmount = false;
        _amountError = null;
      }
    });
  }

  Future<void> _resolveRecipient(String value) async {
    if (value.length < 3) {
      setState(() { _resolvedRecipient = null; _recipientError = null; });
      return;
    }
    setState(() { _resolving = true; _recipientError = null; _resolvedRecipient = null; });
    try {
      final result = await ref.read(walletProvider.notifier).resolveRecipient(value);
      if (mounted) {
        setState(() {
          _resolvedRecipient = result;
          if (result == null) _recipientError = 'Username or address not found';
        });
      }
    } catch (_) {
      if (mounted) setState(() => _recipientError = 'Username or address not found');
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  bool get _canSend {
    return !_loading &&
        !_invalidAmount &&
        _amountCtrl.text.trim().isNotEmpty &&
        _toCtrl.text.trim().isNotEmpty;
  }

  Future<void> _send() async {
    _validateAmount();
    if (!_canSend) return;

    final to = _toCtrl.text.trim();
    final amount = double.parse(_amountCtrl.text.trim());

    setState(() => _loading = true);

    showDayFiBottomSheet(
      context: context,
      isDismissible: false,
      child: _loadingSheet(context, 'Sending...', 'Processing your payment'),
    );

    try {
      final result = await apiService.sendFunds(
        to: _resolvedRecipient?['stellarAddress'] ?? to,
        amount: amount,
        asset: widget.asset,
        memo: _memoCtrl.text.trim().isEmpty ? null : _memoCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        _showSuccess(
          '${_amountCtrl.text} ${widget.asset} sent successfully.',
          txHash: result['transaction']?['hash'],
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        _showError(apiService.parseError(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess(String msg, {String? txHash}) {
    showDayFiBottomSheet(
      context: context,
      child: _successSheet(context, 'Sent!', msg, txHash: txHash),
    );
  }

  void _showError(String msg) {
    showDayFiBottomSheet(
      context: context,
      child: _errorSheet(context, msg, onRetry: _send),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final assetColor = widget.asset == 'USDC' ? const Color(0xFF2775CA) : const Color(0xFF008751);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubHeader(
                onBack: widget.onBack,
                icon: widget.asset == 'USDC' ? Icons.attach_money_rounded : Icons.currency_exchange_rounded,
                iconColor: assetColor,
                title: 'Send ${widget.asset}',
                subtitle: widget.asset == 'USDC'
                    ? 'To any DayFi username or Stellar address'
                    : 'Digital naira via Stellar network',
              ),
              const SizedBox(height: 24),

              // Balance chip
              _BalanceChip(asset: widget.asset, balance: _available),
              const SizedBox(height: 20),

              // Recipient
              _label(context, 'Recipient'),
              const SizedBox(height: 6),
              _inputField(
                context,
                controller: _toCtrl,
                hint: 'DayFi username or Stellar address',
                onChanged: (v) {
                  setState(() {});
                  if (v.length > 2) _resolveRecipient(v);
                },
                suffix: _resolving
                    ? const _InputSpinner()
                    : _resolvedRecipient != null
                    ? Icon(Icons.check_circle_rounded, color: DayFiColors.green, size: 18)
                    : null,
              ),
              if (_recipientError != null)
                _fieldHint(context, _recipientError!, color: cs.error)
              else if (_resolvedRecipient != null)
                _fieldHint(
                  context,
                  _resolvedRecipient!['username'] ?? 'Recipient found on-chain',
                  color: DayFiColors.green,
                ),
              const SizedBox(height: 16),

              // Amount
              _label(context, 'Amount'),
              const SizedBox(height: 6),
              _inputField(
                context,
                controller: _amountCtrl,
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefix: widget.asset == 'USDC' ? '\$ ' : '₦ ',
                suffix: GestureDetector(
                  onTap: () {
                    _amountCtrl.text = _available.toStringAsFixed(2);
                    _validateAmount();
                  },
                  child: Text('MAX', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary)),
                ),
                onChanged: _onAmountChanged,
              ),
              if (_amountError != null)
                _fieldHint(context, _amountError!, color: const Color(0xFFFFA726))
              else
                _fieldHint(context, 'Available: ${_available.toStringAsFixed(2)} ${widget.asset}'),
              const SizedBox(height: 16),

              // Memo
              _label(context, 'Memo (optional)'),
              const SizedBox(height: 6),
              _inputField(
                context,
                controller: _memoCtrl,
                hint: 'Add a note',
                maxLength: 28,
              ),
              const SizedBox(height: 28),

              _PrimaryButton(
                label: 'Send ${widget.asset}',
                enabled: _canSend,
                loading: _loading,
                onTap: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bank transfer sub-flow ─────────────────────────────────────────────────────

class _BankTransferView extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const _BankTransferView({super.key, required this.onBack});

  @override
  ConsumerState<_BankTransferView> createState() => _BankTransferViewState();
}

class _BankTransferViewState extends ConsumerState<_BankTransferView> {
  final _accountCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  List<Map<String, String>> _banks = [];
  String? _bankCode, _bankName, _resolvedName;
  bool _loading = false, _invalidAmount = false;
  String? _amountError;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadBanks();
  }

  @override
  void dispose() {
    _accountCtrl.dispose();
    _amountCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  double get _available => ref.read(walletProvider).ngntBalance;

  Future<void> _loadBanks() async {
    try {
      final res = await apiService.getNigeriaBanks();
      final raw = List<Map<String, dynamic>>.from(res['banks'] ?? []);
      if (!mounted) return;
      setState(() {
        _banks = raw.map((e) => {'code': '${e['code']}', 'name': '${e['name']}'}).toList();
      });
    } catch (_) {}
  }

  void _onAmountChanged(String v) {
    _debounce?.cancel();
    setState(() { _amountError = null; _invalidAmount = false; });
    if (v.isEmpty || double.tryParse(v) == null) return;
    _debounce = Timer(const Duration(milliseconds: 400), _validateAmount);
  }

  void _validateAmount() {
    final amt = double.tryParse(_amountCtrl.text.trim());
    setState(() {
      if (amt == null || amt <= 0) {
        _invalidAmount = true;
        _amountError = 'Enter a valid amount';
      } else if (amt > _available + 0.0001) {
        _invalidAmount = true;
        _amountError = 'Insufficient NGNT balance. Available: ₦${_available.toStringAsFixed(2)}';
      } else {
        _invalidAmount = false;
        _amountError = null;
      }
    });
  }

  Future<void> _resolveAccount(String number) async {
    if (number.length != 10 || _bankCode == null) return;
    try {
      final r = await apiService.resolveBankAccount(bankCode: _bankCode!, accountNumber: number);
      if (mounted) setState(() => _resolvedName = r['accountName']?.toString());
    } catch (_) {
      if (mounted) setState(() => _resolvedName = null);
    }
  }

  bool get _canSend =>
      !_loading &&
      !_invalidAmount &&
      _bankCode != null &&
      _accountCtrl.text.trim().length == 10 &&
      (_resolvedName?.isNotEmpty ?? false) &&
      _amountCtrl.text.trim().isNotEmpty;

  Future<void> _send() async {
    _validateAmount();
    if (!_canSend) return;

    final amount = double.parse(_amountCtrl.text.trim());
    setState(() => _loading = true);

    showDayFiBottomSheet(
      context: context,
      isDismissible: false,
      child: _loadingSheet(context, 'Sending...', 'Initiating bank transfer'),
    );

    try {
      final idempotencyKey =
          '${_bankCode}_${_accountCtrl.text.trim()}_${amount.toStringAsFixed(2)}_${DateTime.now().millisecondsSinceEpoch}';
      final result = await apiService.withdrawToBank(
        ngntAmount: amount,
        bankCode: _bankCode!,
        accountNumber: _accountCtrl.text.trim(),
        accountName: _resolvedName!,
        idempotencyKey: idempotencyKey,
      );
      if (mounted) {
        Navigator.pop(context);
        final status = (result['status'] as String?)?.toLowerCase() ?? '';
        final isPending = status == 'pending';
        showDayFiBottomSheet(
          context: context,
          child: _successSheet(
            context,
            isPending ? 'Transfer Pending' : 'Transfer Sent',
            isPending
                ? 'Your bank transfer is processing. We\'ll update your transactions shortly.'
                : '₦${_amountCtrl.text} sent to $_resolvedName · $_bankName',
            txRef: result['txRef'],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        showDayFiBottomSheet(
          context: context,
          child: _errorSheet(context, apiService.parseError(e), onRetry: _send),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubHeader(
                onBack: widget.onBack,
                icon: Icons.account_balance_rounded,
                iconColor: const Color(0xFF008751),
                title: 'Bank Transfer',
                subtitle: 'Send NGNT to any Nigerian bank account',
              ),
              const SizedBox(height: 24),

              _BalanceChip(asset: 'NGNT', balance: _available),
              const SizedBox(height: 20),

              // Bank selector
              _label(context, 'Bank'),
              const SizedBox(height: 6),
              Container(
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _bankCode,
                    isExpanded: true,
                    hint: Text('Select bank', style: TextStyle(color: cs.onSurface.withOpacity(0.4), fontSize: 14)),
                    items: _banks.map((b) => DropdownMenuItem(value: b['code'], child: Text(b['name'] ?? ''))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _bankCode = v;
                        _bankName = _banks.firstWhere((b) => b['code'] == v, orElse: () => {})['name'];
                        _resolvedName = null;
                      });
                      if (_accountCtrl.text.length == 10) _resolveAccount(_accountCtrl.text);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Account number
              _label(context, 'Account Number'),
              const SizedBox(height: 6),
              _inputField(
                context,
                controller: _accountCtrl,
                hint: '10-digit account number',
                keyboardType: TextInputType.number,
                maxLength: 10,
                onChanged: (v) {
                  setState(() => _resolvedName = null);
                  _resolveAccount(v);
                },
                suffix: _resolvedName != null
                    ? Icon(Icons.check_circle_rounded, color: DayFiColors.green, size: 18)
                    : null,
              ),
              if (_resolvedName != null)
                _fieldHint(context, '$_resolvedName · ${_bankName ?? ''}', color: DayFiColors.green)
              else
                _fieldHint(context, 'Account name will appear here after resolution'),
              const SizedBox(height: 16),

              // Amount
              _label(context, 'Amount (NGNT)'),
              const SizedBox(height: 6),
              _inputField(
                context,
                controller: _amountCtrl,
                hint: '0.00',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefix: '₦ ',
                suffix: GestureDetector(
                  onTap: () {
                    _amountCtrl.text = _available.toStringAsFixed(2);
                    _validateAmount();
                  },
                  child: Text('MAX', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: cs.primary)),
                ),
                onChanged: _onAmountChanged,
              ),
              if (_amountError != null)
                _fieldHint(context, _amountError!, color: const Color(0xFFFFA726))
              else
                _fieldHint(context, 'Available: ₦${_available.toStringAsFixed(2)} NGNT'),
              const SizedBox(height: 28),

              _PrimaryButton(
                label: 'Send to Bank',
                enabled: _canSend,
                loading: _loading,
                onTap: _send,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Payment request sub-flow ───────────────────────────────────────────────────

class _PaymentRequestView extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  const _PaymentRequestView({super.key, required this.onBack});

  @override
  ConsumerState<_PaymentRequestView> createState() => _PaymentRequestViewState();
}

class _PaymentRequestViewState extends ConsumerState<_PaymentRequestView> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _loading = false;
  String? _generatedLink;
  String? _error;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _createRequest() async {
    final amt = double.tryParse(_amountCtrl.text.trim());
    if (amt == null || amt <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final note = _noteCtrl.text.trim();
      final res = await apiService.createRequest({
        'amount': amt,
        'asset': 'NGNT',
        if (note.isNotEmpty) 'note': note,
      });
      if (mounted) {
        final reqNumber = res['request']?['requestNumber'] ?? res['requestNumber'] ?? '';
        setState(() {
          _generatedLink = 'https://dayfi.me/pay/$reqNumber';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = apiService.parseError(e); _loading = false; });
    }
  }

  void _copyLink() {
    if (_generatedLink == null) return;
    Clipboard.setData(ClipboardData(text: _generatedLink!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied to clipboard'), duration: Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SubHeader(
                onBack: widget.onBack,
                icon: Icons.link_rounded,
                iconColor: const Color(0xFF9C27B0),
                title: 'Request Money',
                subtitle: 'Create a shareable payment link',
              ),
              const SizedBox(height: 24),

              if (_generatedLink != null) ...[
                // Success state
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DayFiColors.green.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: DayFiColors.green.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: DayFiColors.green, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Payment link created',
                            style: GoogleFonts.bricolageGrotesque(
                              fontSize: 15, fontWeight: FontWeight.w700, color: DayFiColors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: cs.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: cs.onSurface.withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _generatedLink!,
                                style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.7)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _copyLink,
                              child: Icon(Icons.copy_rounded, size: 18, color: cs.onSurface.withOpacity(0.5)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _PrimaryButton(
                              label: 'Copy Link',
                              enabled: true,
                              loading: false,
                              onTap: _copyLink,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 48),
                                side: BorderSide(color: cs.onSurface.withOpacity(0.15)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => setState(() => _generatedLink = null),
                              child: Text('New Request', style: TextStyle(fontSize: 14, color: cs.onSurface)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                _label(context, 'Amount (USDC)'),
                const SizedBox(height: 6),
                _inputField(
                  context,
                  controller: _amountCtrl,
                  hint: '0.00',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefix: '\$ ',
                ),
                if (_error != null) _fieldHint(context, _error!, color: cs.error),
                const SizedBox(height: 16),

                _label(context, 'Note (optional)'),
                const SizedBox(height: 6),
                _inputField(
                  context,
                  controller: _noteCtrl,
                  hint: 'What is this for?',
                  maxLength: 100,
                ),
                const SizedBox(height: 28),

                _PrimaryButton(
                  label: 'Generate Payment Link',
                  enabled: !_loading,
                  loading: _loading,
                  onTap: _createRequest,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared widgets ─────────────────────────────────────────────────────────────

class _SubHeader extends StatelessWidget {
  final VoidCallback onBack;
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;

  const _SubHeader({
    required this.onBack,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_back_ios_new_rounded, size: 14, color: cs.onSurface.withOpacity(0.5)),
              const SizedBox(width: 4),
              Text('Payments', style: TextStyle(fontSize: 13, color: cs.onSurface.withOpacity(0.5))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: cs.onSurface,
                  ),
                ),
                Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(0.45))),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _BalanceChip extends ConsumerWidget {
  final String asset;
  final double balance;
  const _BalanceChip({required this.asset, required this.balance});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final prefix = asset == 'USDC' ? '\$' : '₦';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 14, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            'Balance: $prefix${balance.toStringAsFixed(2)} $asset',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
          ),
        ],
      ),
    );
  }
}

class _InputSpinner extends StatelessWidget {
  const _InputSpinner();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.all(12),
    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
  );
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool enabled, loading;
  final VoidCallback onTap;

  const _PrimaryButton({
    required this.label,
    required this.enabled,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = enabled && !loading;
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: active ? cs.onSurface : cs.onSurface.withOpacity(0.2),
          foregroundColor: cs.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: active ? onTap : null,
        child: loading
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: cs.surface),
              )
            : Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Helper builders ────────────────────────────────────────────────────────────

Widget _label(BuildContext context, String text) {
  final cs = Theme.of(context).colorScheme;
  return Text(
    text,
    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurface.withOpacity(0.55), letterSpacing: 0.3),
  );
}

Widget _fieldHint(BuildContext context, String text, {Color? color}) {
  final cs = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.only(top: 5, left: 2),
    child: Text(
      text,
      style: TextStyle(fontSize: 11, color: color ?? cs.onSurface.withOpacity(0.4)),
    ),
  );
}

Widget _inputField(
  BuildContext context, {
  required TextEditingController controller,
  required String hint,
  TextInputType? keyboardType,
  String? prefix,
  Widget? suffix,
  int? maxLength,
  void Function(String)? onChanged,
}) {
  final cs = Theme.of(context).colorScheme;
  return TextField(
    controller: controller,
    keyboardType: keyboardType,
    maxLength: maxLength,
    onChanged: onChanged,
    style: const TextStyle(fontSize: 15),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.3), fontSize: 15),
      prefixText: prefix,
      suffixIcon: suffix,
      filled: true,
      fillColor: cs.onSurface.withOpacity(0.06),
      counterText: '',
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cs.primary.withOpacity(0.4), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    ),
  );
}

// ── Shared bottom sheet bodies ─────────────────────────────────────────────────

Widget _loadingSheet(BuildContext ctx, String title, String subtitle) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
        const SizedBox(height: 20),
        Text(title, style: Theme.of(ctx).textTheme.displaySmall?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -1)),
        const SizedBox(height: 8),
        Text(subtitle, style: TextStyle(fontSize: 15, color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5)), textAlign: TextAlign.center),
      ],
    ),
  );
}

Widget _successSheet(BuildContext ctx, String title, String subtitle, {String? txHash, String? txRef}) {
  final cs = Theme.of(ctx).colorScheme;
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 48),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Lottie.asset('assets/animations/success.json', width: 110, height: 110, repeat: false),
        Text(title, style: Theme.of(ctx).textTheme.displaySmall?.copyWith(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -1)),
        const SizedBox(height: 10),
        Text(subtitle, style: TextStyle(fontSize: 15, color: cs.onSurface.withOpacity(0.55), height: 1.4), textAlign: TextAlign.center),
        if (txHash != null) ...[
          const SizedBox(height: 6),
          Text('Tx: ${txHash.substring(0, 12)}...', style: Theme.of(ctx).textTheme.bodySmall),
        ],
        if (txRef != null) ...[
          const SizedBox(height: 4),
          Text('Ref: $txRef', style: Theme.of(ctx).textTheme.bodySmall),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.onSurface,
              foregroundColor: cs.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    ),
  );
}

Widget _errorSheet(BuildContext ctx, String message, {required VoidCallback onRetry}) {
  final cs = Theme.of(ctx).colorScheme;
  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: cs.error.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(Icons.error_outline_rounded, color: cs.error, size: 28),
        ),
        const SizedBox(height: 16),
        Text('Transaction failed', style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(message, style: TextStyle(fontSize: 14, color: cs.onSurface.withOpacity(0.5), height: 1.4), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: cs.onSurface, foregroundColor: cs.surface, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () { Navigator.pop(ctx); onRetry(); },
            child: const Text('Retry', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 10),
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Dismiss', style: TextStyle(color: cs.onSurface.withOpacity(0.5)))),
      ],
    ),
  );
}
