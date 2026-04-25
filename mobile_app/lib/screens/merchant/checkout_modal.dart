// lib/screens/merchant/checkout_modal.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_app/screens/merchant/checkout_screen.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager_ndef/nfc_manager_ndef.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/inventory_item.dart';
import '../../providers/inventory_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

// ─── Checkout Modal ─────────────────────────────────────────────────────────────

class CheckoutModal extends ConsumerStatefulWidget {
  const CheckoutModal({super.key});

  @override
  ConsumerState<CheckoutModal> createState() => _CheckoutModalState();
}

class _CheckoutModalState extends ConsumerState<CheckoutModal> {
  // Checkout URI state
  String? _stellarUri;
  String? _memo;
  double? _totalUsdc;
  bool _loadingUri = false;

  // Payment detection
  bool _paymentReceived = false;
  String? _txHash;
  StreamSubscription? _horizonSub;

  // NFC
  bool _nfcActive = false;
  bool _nfcAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkNfc();
  }

  @override
  void dispose() {
    _horizonSub?.cancel();
    NfcManager.instance.stopSession().catchError((_) {});
    super.dispose();
  }

  Future<void> _checkNfc() async {
    try {
      final available = await NfcManager.instance.isAvailable();
      if (mounted) setState(() => _nfcAvailable = available);
    } catch (_) {}
  }

  // ─── Build checkout URI from cart ──────────────────────────────────────────

  Future<void> _generateUri() async {
    final cart = ref.read(cartProvider);
    final inventory = ref.read(inventoryProvider).items;

    if (cart.isEmpty) return;

    setState(() {
      _loadingUri = true;
      _stellarUri = null;
    });

    try {
      final cartItems = cart.entries.map((e) {
        final item = inventory.firstWhere((i) => i.id == e.key);
        return {
          'id': item.id,
          'name': item.name,
          'qty': e.value,
          'priceUsdc': item.priceUsdc,
        };
      }).toList();

      final total = cart.entries.fold<double>(0, (sum, e) {
        final item = inventory.firstWhere((i) => i.id == e.key);
        return sum + (item.priceUsdc * e.value);
      });

      final result = await apiService.getCheckoutUri(
        items: cartItems.cast<Map<String, dynamic>>(),
        totalUsdc: total,
      );

      setState(() {
        _stellarUri = result['uri'] as String;
        _memo = result['memo'] as String?;
        _totalUsdc = total;
        _loadingUri = false;
      });

      // Start listening for payment on Horizon
      _startPaymentListener(result['destination'] as String, total);
    } catch (e) {
      setState(() => _loadingUri = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: DayFiColors.red,
          ),
        );
      }
    }
  }

  // ─── Horizon payment listener (polls every 3s) ─────────────────────────────

  void _startPaymentListener(String destination, double expectedAmount) {
    _horizonSub?.cancel();

    const interval = Duration(seconds: 3);
    const network = String.fromEnvironment(
      'STELLAR_NETWORK',
      defaultValue: 'mainnet',
    );
    const horizon = network == 'testnet'
        ? 'https://horizon-testnet.stellar.org'
        : 'https://horizon.stellar.org';

    DateTime? listenSince;

    _horizonSub = Stream.periodic(interval)
        .asyncMap((_) async {
          listenSince ??= DateTime.now().subtract(const Duration(seconds: 10));

          try {
            // Fetch recent payments to seller address
            final url = Uri.parse(
              '$horizon/accounts/$destination/payments'
              '?order=desc&limit=5',
            );
            final response = await apiService.rawGet(url.toString());
            final records = (response['_embedded']?['records'] as List?) ?? [];

            for (final tx in records) {
              final type = tx['type'] as String?;
              final amount = double.tryParse(tx['amount'] ?? '0') ?? 0;
              final asset = tx['asset_code'] as String?;
              final txTime = DateTime.tryParse(tx['created_at'] ?? '');

              final isUsdc = asset == 'USDC';
              final isCorrect = (amount - expectedAmount).abs() < 0.01;
              final isRecent = txTime != null && txTime.isAfter(listenSince!);

              if (isUsdc && isCorrect && isRecent) {
                return tx['transaction_hash'] as String?;
              }
            }
          } catch (_) {}
          return null;
        })
        .listen((hash) async {
          if (hash != null && !_paymentReceived) {
            _horizonSub?.cancel();
            setState(() {
              _paymentReceived = true;
              _txHash = hash;
            });

            // Stop NFC
            if (_nfcActive) {
              NfcManager.instance.stopSession().catchError((_) {});
              setState(() => _nfcActive = false);
            }

            // Deduct stock
            final cart = ref.read(cartProvider);
            await ref.read(inventoryProvider.notifier).deductCartStock(cart);

            // Clear cart
            ref.read(cartProvider.notifier).state = {};
          }
        });
  }

  // ─── NFC tag emulation ─────────────────────────────────────────────────────

  Future<void> _startNfc() async {
    if (_stellarUri == null || !_nfcAvailable) return;

    try {
      await NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          // 1. Get the NDEF interface from the tag
          final ndef = Ndef.from(tag);

          // 2. Check if the tag supports NDEF and is writable
          if (ndef == null || !ndef.isWritable) {
            print('Tag is not NDEF compatible or is read-only');
            await NfcManager.instance.stopSession(
              errorMessageIos: "Tag not writable",
            );
            return;
          }

          // 3. Create the NDEF message
          final message = NdefMessage(
            records: [
              NdefRecord(
                typeNameFormat: TypeNameFormat.wellKnown,
                type: Uint8List.fromList([0x55]),
                identifier: Uint8List.fromList([]),
                payload: Uint8List.fromList([0x00, ..._stellarUri!.codeUnits]),
              ),
            ],
          );

          try {
            // 4. Write to the tag
            await ndef.write(message: message);
            print('Success: Stellar URI written to tag');
            await NfcManager.instance.stopSession();
          } catch (e) {
            await NfcManager.instance.stopSession(
              errorMessageIos: "Write failed: $e",
            );
          }
        },
        pollingOptions: {NfcPollingOption.iso14443},
      );

      setState(() => _nfcActive = true);
    } catch (e) {
      setState(() => _nfcActive = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('NFC error: $e'),
            backgroundColor: DayFiColors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopNfc() async {
    await NfcManager.instance.stopSession().catchError((_) {});
    setState(() => _nfcActive = false);
  }

  // ─── Share receipt via WhatsApp ─────────────────────────────────────────────

  void _shareReceipt() {
    const network = String.fromEnvironment(
      'STELLAR_NETWORK',
      defaultValue: 'mainnet',
    );
    final url = 'https://stellar.expert/explorer/$network/tx/$_txHash';
    final text = '✅ Payment received!\n\nView receipt: $url';

    Share.share(text);
  }

  void _openExplorer() {
    const network = String.fromEnvironment(
      'STELLAR_NETWORK',
      defaultValue: 'mainnet',
    );
    launchUrl(
      Uri.parse('https://stellar.expert/explorer/$network/tx/$_txHash'),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_paymentReceived) return _buildPaidContent(context);

    final cart = ref.watch(cartProvider);
    final inventory = ref.watch(inventoryProvider).items;

    return Column(
      children: [
        // Header
        _ModalHeader(
          title: 'Checkout',
          step: 0,
          totalSteps: 0,
          onBack: null,
          onClose: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 24),
        // Content
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Cart ──────────────────────────────────────────────────
                _CartSection(
                  cart: cart,
                  inventory: inventory,
                  onChanged: (_) => setState(() {
                    _stellarUri = null;
                  }),
                ),
                const SizedBox(height: 20),

                if (cart.isNotEmpty) ...[
                  // ── Generate / show QR ────────────────────────────────
                  if (_stellarUri == null) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(.9),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _loadingUri ? null : _generateUri,
                        child: _loadingUri
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                'Generate Payment QR',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 15,
                                    ),
                              ),
                      ),
                    ),
                  ] else ...[
                    // ── Total ─────────────────────────────────────────────
                    Text(
                      '\$${_totalUsdc!.toStringAsFixed(2)} USDC',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontSize: 36,
                            fontWeight: FontWeight.w400,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Waiting for payment...',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── QR Code ───────────────────────────────────────────
                    SizedBox(
                      width: 220,
                      child: PrettyQrView.data(
                        data: _stellarUri!,
                        decoration: PrettyQrDecoration(
                          shape: PrettyQrSmoothSymbol(
                            color: Theme.of(
                              context,
                            ).textTheme.bodyLarge!.color!.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── NFC toggle ────────────────────────────────────────
                    if (_nfcAvailable) ...[
                      _NfcToggle(
                        isActive: _nfcActive,
                        onToggle: _nfcActive ? _stopNfc : _startNfc,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // ── Memo ──────────────────────────────────────────────
                    if (_memo != null)
                      Text(
                        'Memo: $_memo',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Payment received content ───────────────────────────────────────────────

  Widget _buildPaidContent(BuildContext context) {
    return Column(
      children: [
        // Header
        _ModalHeader(
          title: 'Payment Received',
          step: 0,
          totalSteps: 0,
          onBack: null,
          onClose: () => Navigator.of(context).pop(),
        ),
        const SizedBox(height: 24),
        // Content
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 40,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Payment Received',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 28,
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${_totalUsdc?.toStringAsFixed(2) ?? '—'} USDC',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_txHash != null)
                    InkWell(
                      splashColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      onTap: _openExplorer,
                      child: Text(
                        '${_txHash!.substring(0, 8)}...${_txHash!.substring(_txHash!.length - 8)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.3),
                          fontSize: 12,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                  // Share via WhatsApp
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(.9),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _shareReceipt,
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Share Receipt'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(.3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _paymentReceived = false;
                          _stellarUri = null;
                          _txHash = null;
                        });
                      },
                      child: const Text('New Sale'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Cart Section ─────────────────────────────────────────────────────────────

class _CartSection extends ConsumerWidget {
  final Map<String, int> cart;
  final List<InventoryItem> inventory;
  final ValueChanged<Map<String, int>> onChanged;

  const _CartSection({
    required this.cart,
    required this.inventory,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Items',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        ...inventory.map((item) {
          final qty = cart[item.id] ?? 0;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: qty > 0
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: qty > 0
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.1,
                        ),
                      ),
                      Text(
                        '\$${item.priceUsdc.toStringAsFixed(2)} · ${item.stock} in stock',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                    ],
                  ),
                ),
                // Qty stepper
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (qty > 0) ...[
                      _CartBtn(
                        icon: Icons.remove,
                        onTap: () {
                          final newCart = Map<String, int>.from(cart);
                          if (qty <= 1) {
                            newCart.remove(item.id);
                          } else {
                            newCart[item.id] = qty - 1;
                          }
                          ref.read(cartProvider.notifier).state = newCart;
                          onChanged(newCart);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          '$qty',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                        ),
                      ),
                    ],
                    _CartBtn(
                      icon: Icons.add,
                      onTap: item.stock <= qty
                          ? null
                          : () {
                              final newCart = Map<String, int>.from(cart);
                              newCart[item.id] = qty + 1;
                              ref.read(cartProvider.notifier).state = newCart;
                              onChanged(newCart);
                            },
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _CartBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _CartBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(onTap == null ? 0.04 : 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: Theme.of(
            context,
          ).colorScheme.onSurface.withOpacity(onTap == null ? 0.2 : 0.7),
        ),
      ),
    );
  }
}

// ─── Modal Helper Components ───────────────────────────────────────────────────

class _ModalHeader extends StatelessWidget {
  final String title;
  final int step;
  final int totalSteps;
  final VoidCallback? onBack;
  final VoidCallback onClose;

  const _ModalHeader({
    required this.title,
    required this.step,
    required this.totalSteps,
    this.onBack,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (onBack != null)
          _SmallIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack!,
          )
        else
          const SizedBox(width: 36),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
        _SmallIconButton(icon: Icons.close_rounded, onTap: onClose),
      ],
    );
  }
}

class _SmallIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _SmallIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 18,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
        ),
      ),
    );
  }
}

// ─── NFC toggle button ────────────────────────────────────────────────────────

class _NfcToggle extends StatelessWidget {
  final bool isActive;
  final VoidCallback onToggle;
  const _NfcToggle({required this.isActive, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.green.withOpacity(0.12)
              : Theme.of(context).colorScheme.onSurface.withOpacity(0.07),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isActive
                ? Colors.green.withOpacity(0.3)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.nfc_rounded,
              size: 18,
              color: isActive
                  ? Colors.green
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(width: 8),
            Text(
              isActive ? 'NFC Active — tap buyer\'s phone' : 'Enable NFC Pay',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 13,
                color: isActive
                    ? Colors.green
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
