// lib/screens/receive/receive_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/widgets/app_background.dart';
import 'package:mobile_app/widgets/app_bottomsheet.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

// ─── Asset image mapping ──────────────────────────────────────────────────────

final Map<String, String> _assetEmojis = {
  'USDC': 'assets/images/usdc.png',
  'XLM': 'assets/images/stellar.png',
  'NGNT': 'assets/images/ngnt.png',
};

// ─── Virtual account model ────────────────────────────────────────────────────

class _VirtualAccount {
  final String accountNumber;
  final String bankName;
  final String accountName;

  const _VirtualAccount({
    required this.accountNumber,
    required this.bankName,
    required this.accountName,
  });

  factory _VirtualAccount.fromMap(Map<String, dynamic> m) => _VirtualAccount(
    accountNumber: m['accountNumber'] as String,
    bankName: m['bankName'] as String,
    accountName: m['accountName'] as String,
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class ReceiveScreen extends StatefulWidget {
  final String? initialAsset;
  const ReceiveScreen({super.key, this.initialAsset});

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen> {
  // 0 = Blockchains  1 = dayfi.me Username  2 = Fund with NGN
  int _selectedTab = 0;

  // ── Blockchain / username data
  Map<String, dynamic>? _addressData;
  Map<String, dynamic>? _rawAssets;
  bool _loading = true;
  String? _selectedAssetCode;
  String? _selectedNetworkKey;

  // ── Virtual account data
  _VirtualAccount? _virtualAccount;
  bool _vaLoading = false; // spinner while fetching/creating
  bool _vaChecked = false; // true once we've attempted GET at least once

  // ── BVN form state
  final _bvnController = TextEditingController();
  bool _submittingBvn = false;
  String? _bvnError;

  @override
  void initState() {
    super.initState();
    _selectedNetworkKey = 'stellar';
    if (widget.initialAsset != null) {
      _selectedAssetCode = widget.initialAsset;
      // If opened directly with NGNT, land on the NGN tab
      if (widget.initialAsset == 'NGNT') _selectedTab = 2;
    }
    _loadInitialData();
  }

  @override
  void dispose() {
    _bvnController.dispose();
    super.dispose();
  }

  double _getEmojiHeight(String? path) =>
      path == 'assets/images/stellar.png' ? 38 : 40;

  // ─── Load blockchain + address data ──────────────────────

  Future<void> _loadInitialData() async {
    try {
      final results = await Future.wait([
        apiService.getAddress(),
        apiService.getNetworkConfig(),
      ]);
      final addressData = results[0];
      final configData = results[1];

      if (mounted) {
        setState(() {
          _addressData = addressData;
          _rawAssets =
              configData['assets'] as Map<String, dynamic>? ??
              {
                'USDC': ['stellar'],
                'XLM': ['stellar'],
              };
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _rawAssets = {
            'USDC': ['stellar'],
            'XLM': ['stellar'],
          };
        });
      }
    }
  }

  // ─── Load virtual account ─────────────────────────────────

  Future<void> _loadVirtualAccount() async {
    if (_vaChecked) return; // already fetched this session
    setState(() => _vaLoading = true);
    try {
      final data = await apiService.getVirtualAccount();
      if (mounted) {
        setState(() {
          _vaChecked = true;
          _vaLoading = false;
          if (data['exists'] == true) {
            _virtualAccount = _VirtualAccount.fromMap(data);
          }
        });
      }
    } catch (_) {
      if (mounted)
        setState(() {
          _vaLoading = false;
          _vaChecked = true;
        });
    }
  }

  // ─── Create virtual account with BVN ─────────────────────

  Future<void> _submitBvn() async {
    final bvn = _bvnController.text.trim();
    if (bvn.length != 11 || !RegExp(r'^\d{11}$').hasMatch(bvn)) {
      setState(() => _bvnError = 'Enter a valid 11-digit BVN');
      return;
    }
    setState(() {
      _submittingBvn = true;
      _bvnError = null;
    });
    try {
      final data = await apiService.createVirtualAccount(bvn: bvn);
      if (mounted) {
        setState(() {
          _submittingBvn = false;
          _virtualAccount = _VirtualAccount.fromMap(data);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submittingBvn = false;
          _bvnError = apiService.parseError(e);
        });
      }
    }
  }

  // ─── Helpers ─────────────────────────────────────────────

  void _copy(String text, [String label = 'Copied to clipboard']) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(label)));
  }

  void _share(String text) => Share.share(text);

  String _getAddressForNetwork() {
    if (_selectedNetworkKey == null) return '';
    switch (_selectedNetworkKey) {
      case 'stellar':
        return _addressData?['stellarAddress'] ?? '';
      default:
        return _addressData?['evmAddress'] ?? '';
    }
  }

  // ─── Currency picker bottom sheet ─────────────────────────

  void _showCurrencyPicker() {
    if (_rawAssets == null) return;
    final currencies = _rawAssets!.keys.toList();
    showDayFiBottomSheet(
      context: context,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Opacity(opacity: 0, child: Icon(Icons.close)),
                Text(
                  'Choose Currency to Receive',
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
            ...currencies.map((code) {
              final emoji = _assetEmojis[code] ?? 'assets/images/default.png';
              return InkWell(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
                hoverColor: Colors.transparent,
                onTap: () {
                  setState(() {
                    _selectedAssetCode = code;
                    _selectedNetworkKey = 'stellar';
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
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(54),
                        child: Image.asset(
                          emoji,
                          height: _getEmojiHeight(emoji),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        code,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
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

  // ─── Build ────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: Text(
            'Receive Funds',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(
                context,
              ).textTheme.bodyLarge?.color?.withOpacity(.95),
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
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SizedBox(
                  width: MediaQuery.of(context).size.width,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // ── Tab switcher ────────────────────────────────
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).textTheme.bodySmall?.color?.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _Tab(
                                label: 'Blockchains',
                                selected: _selectedTab == 0,
                                onTap: () => setState(() => _selectedTab = 0),
                              ),
                              // _Tab(
                              //   label: 'dayfi.me',
                              //   selected: _selectedTab == 1,
                              //   onTap: () => setState(() => _selectedTab = 1),
                              // ),
                              _Tab(
                                label: 'Fund NGN',
                                selected: _selectedTab == 1,
                                onTap: () {
                                  setState(() => _selectedTab = 1);
                                  _loadVirtualAccount();
                                },
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 6),

                        if (_selectedTab == 0) _buildBlockchainTab(),
                        // if (_selectedTab == 1) _buildUsernameTab(),
                        if (_selectedTab == 1) _buildNgnTab(),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // ─── Tab 0: Blockchain ────────────────────────────────────

  Widget _buildBlockchainTab() {
    final address = _getAddressForNetwork();
    final ready = _selectedAssetCode != null && address.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Receive on Stellar',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose the currency below to get\nyour unique receiving address and QR code.',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 14,
            letterSpacing: -.1,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        Center(
          child: SizedBox(
            width: (MediaQuery.of(context).size.width * .5) - 8,
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              hoverColor: Colors.transparent,
              onTap: _showCurrencyPicker,
              child: _DropdownBox(
                emoji: _selectedAssetCode != null
                    ? _assetEmojis[_selectedAssetCode]
                    : null,
                label: _selectedAssetCode ?? 'Choose Currency',
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (!ready) ...[
          const SizedBox(height: 24),
          SvgPicture.asset(
            'assets/icons/svgs/qrcode.svg',
            height: 80,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.15),
          ),
          const SizedBox(height: 6),
          Text(
            'Waiting for selection...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Once you select a currency,\nyour QR code will appear here.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ] else ...[
          Center(child: _QRCard(data: address)),
          const SizedBox(height: 20),
          Text(
            'Stellar network',
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontSize: 13.5,
              letterSpacing: -.1,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          _AddressBox(
            text: address.length > 16
                ? '${address.substring(0, 10)}...${address.substring(address.length - 10)}'
                : address,
            onCopy: () => _copy(address),
          ),
          const SizedBox(height: 32),
          _ActionButtons(
            onShare: () => _share(address),
            onCopy: () => _copy(address),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }

  // ─── Tab 1: dayfi.me Username ─────────────────────────────

  Widget _buildUsernameTab() {
    final username = _addressData?['dayfiUsername'] ?? '';
    final qrData = 'https://dayfi.me/pay/$username';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Receive via dayfi.me',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Share this QR or your dayfi.me username.\nAnyone can send you USDC instantly.',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 14,
            letterSpacing: -.1,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        _QRCard(data: qrData),
        const SizedBox(height: 20),
        Text(
          'Stellar Network',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 13.5,
            letterSpacing: -.1,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        _AddressBox(text: username, onCopy: () => _copy(username)),
        const SizedBox(height: 32),
        _ActionButtons(
          onShare: () => _share('Send me USDC at $username'),
          onCopy: () => _copy(username),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ─── Tab 2: Fund with NGN (Virtual Account) ───────────────

  Widget _buildNgnTab() {
    // Still loading the GET check
    if (_vaLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    // Virtual account exists — show persistent details
    if (_virtualAccount != null) {
      return _buildVirtualAccountDetails(_virtualAccount!);
    }

    // No virtual account yet — collect BVN
    return _buildBvnForm();
  }

  // ── Virtual account details ───────────────────────────────

  Widget _buildVirtualAccountDetails(_VirtualAccount va) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Header
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF008751).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              '₦',
              style: TextStyle(fontSize: 24, color: Color(0xFF008751)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Fund with Bank Transfer',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Transfer NGN to this account. Your NGNT\nbalance will update automatically.',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 14,
            letterSpacing: -.1,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // Account details card
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).textTheme.bodySmall?.color?.withOpacity(0.07),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF008751).withOpacity(0.15),
              ),
            ),
            child: Column(
              children: [
                _VaDetailRow(
                  label: 'Bank Name',
                  value: va.bankName,
                  icon: Icons.account_balance_rounded,
                ),
                const SizedBox(height: 6),
                _VaDetailRow(
                  label: 'Account Number',
                  value: va.accountNumber,
                  icon: Icons.tag_rounded,
                  onCopy: () =>
                      _copy(va.accountNumber, 'Account number copied'),
                ),
                const SizedBox(height: 6),
                _VaDetailRow(
                  label: 'Account Name',
                  value: va.accountName,
                  icon: Icons.person_rounded,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Info note
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF008751).withOpacity(0.07),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: const Color(0xFF008751).withOpacity(0.8),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is your dedicated DayFi funding account. '
                    'Transfers from any Nigerian bank reflect within minutes.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12.5,
                      height: 1.4,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 28),

        // Share + Copy buttons
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
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
                  onPressed: () => _share(
                    'Bank: ${va.bankName}\n'
                    'Account Number: ${va.accountNumber}\n'
                    'Account Name: ${va.accountName}',
                  ),
                  icon: Icon(
                    Icons.ios_share,
                    size: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(.90),
                  ),
                  label: Text(
                    'Share',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(.90),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
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
                  onPressed: () => _copy(
                    '${va.bankName}\n${va.accountNumber}\n${va.accountName}',
                    'Account details copied',
                  ),
                  icon: Icon(
                    Icons.copy,
                    size: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(.90),
                  ),
                  label: Text(
                    'Copy',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(.90),
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }

  // ── BVN collection form ───────────────────────────────────

  Widget _buildBvnForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF008751).withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Center(
            child: Text(
              '₦',
              style: TextStyle(fontSize: 24, color: Color(0xFF008751)),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Fund your NGN Balance',
          style: Theme.of(context).textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll create a dedicated bank account for you.\nTransfers credit your NGNT wallet automatically.',
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
            fontSize: 14,
            letterSpacing: -.1,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),

        // BVN field
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bank Verification Number (BVN)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bvnController,
                keyboardType: TextInputType.number,
                maxLength: 11,
                onChanged: (_) {
                  if (_bvnError != null) setState(() => _bvnError = null);
                },
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: '• • • • • • • • • • •',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(.3),
                    fontSize: 15,
                  ),
                  counterText: '',
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.1),
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
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 16,
                  ),
                  errorText: _bvnError,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.35),
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      'Your BVN is used only for account creation and is never stored.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11.5,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
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
              onPressed: _submittingBvn ? null : _submitBvn,
              child: _submittingBvn
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    )
                  : Text(
                      'Create My Virtual Account',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(.90),
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ─── Virtual account detail row ───────────────────────────────────────────────

class _VaDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onCopy;

  const _VaDetailRow({
    required this.label,
    required this.value,
    required this.icon,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF008751).withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF008751)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.45),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  letterSpacing: onCopy != null ? 1.5 : 0,
                ),
              ),
            ],
          ),
        ),
        if (onCopy != null)
          InkWell(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
            hoverColor: Colors.transparent,
            onTap: onCopy,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.copy_rounded,
                size: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.45),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Shared sub-widgets ───────────────────────────────────────────────────────

class _Tab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withOpacity(.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: selected
                ? Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(.85)
                : null,
            fontWeight: FontWeight.w500,
            fontSize: 13,
            letterSpacing: -.1,
          ),
        ),
      ),
    );
  }
}

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
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
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

class _QRCard extends StatelessWidget {
  final String data;
  const _QRCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 225,
      child: PrettyQrView.data(
        data: data.isEmpty ? 'dayfi' : data,
        decoration: PrettyQrDecoration(
          shape: PrettyQrSmoothSymbol(
            color: Theme.of(
              context,
            ).textTheme.bodyLarge!.color!.withOpacity(0.85),
          ),
        ),
      ),
    );
  }
}

class _AddressBox extends StatelessWidget {
  final String text;
  final VoidCallback onCopy;
  const _AddressBox({required this.text, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      onTap: onCopy,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.02),
          ),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(.90),
            fontSize: 13.5,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback onCopy;
  const _ActionButtons({required this.onShare, required this.onCopy});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Row(
        children: [
          Expanded(
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
              onPressed: onShare,
              icon: Icon(
                Icons.ios_share,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.90),
              ),
              label: Text(
                'Share',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(.90),
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
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
              onPressed: onCopy,
              icon: Icon(
                Icons.copy,
                size: 18,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.90),
              ),
              label: Text(
                'Copy',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(.90),
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
