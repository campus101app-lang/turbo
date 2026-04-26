// lib/screens/shell/main_shell.dart
//
// Persistent shell — side nav + top bar NEVER disappear.
// Every destination (8 tabs + Send / Receive / Swap / Settings / Security)
// renders inside an IndexedStack in the content area.
//
// On mobile (< 768 px) the original top-tab layout is preserved.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mobile_app/providers/shell_navigation_provider.dart';
import 'package:mobile_app/providers/user_provider.dart';
import 'package:mobile_app/providers/wallet_provider.dart';
import 'package:mobile_app/screens/accounts/accounts_screen.dart';
import 'package:mobile_app/screens/cards/cards_screen.dart';
import 'package:mobile_app/screens/expenses/expenses_screen.dart';
import 'package:mobile_app/screens/home/home_screen.dart';
import 'package:mobile_app/screens/invoices/invoices_screen.dart';
import 'package:mobile_app/screens/merchant/checkout_screen.dart';
import 'package:mobile_app/screens/merchant/merchant_dashboard.dart';
import 'package:mobile_app/screens/receive/receive_screen.dart';
import 'package:mobile_app/screens/security/security_screen.dart';
import 'package:mobile_app/screens/send/send_screen.dart';
import 'package:mobile_app/screens/settings/settings_screen.dart';
import 'package:mobile_app/screens/swap/swap_screen.dart';
import 'package:mobile_app/screens/transactions/transactions_screen.dart';
import 'package:mobile_app/screens/workflows/workflows_screen.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/widgets/app_background.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mobile_app/screens/merchant/add_product_screen.dart';
import 'package:mobile_app/screens/merchant/product_detail_screen.dart';

// ── Constants ──────────────────────────────────────────────────────────────────

const _kWebBreakpoint = 768.0;

const _tabLabels = [
  'Billing', // 0
  'Expenses', // 1
  'Shop', // 2
  'Transactions', // 3
  'Home', // 4
  'Accounts', // 5
  'Cards', // 6
  'Workflows', // 7
];

const _tabIcons = [
  Icons.receipt_long_outlined,
  Icons.attach_money_outlined,
  Icons.storefront_outlined,
  Icons.swap_horiz_outlined,
  Icons.home_outlined,
  Icons.account_balance_wallet_outlined,
  Icons.credit_card_outlined,
  Icons.account_tree_outlined,
];

const List<int?> _tabBadges = [3, null, null, null, null, null, null, null];

const _navGroups = [
  (label: 'main', indices: [4, 3, 5, 6]),
  (label: 'business', indices: [0, 1, 2, 7]),
];

// ── MainShell ──────────────────────────────────────────────────────────────────

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _sideNavCollapsed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabLabels.length,
      vsync: this,
      initialIndex: 4,
      animationDuration: Duration.zero,
    );
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Navigation helpers ─────────────────────────────────────────────────────

  void _selectTab(int tabIndex) {
    ref.read(shellNavProvider.notifier).goTo(ShellDest.values[tabIndex]);
    if (_tabController.index != tabIndex) {
      _tabController.animateTo(tabIndex);
    }
  }

  void _navigate(ShellDest dest) =>
      ref.read(shellNavProvider.notifier).goTo(dest);

  void _goBack() => ref.read(shellNavProvider.notifier).goBack();

  // ── Shared IndexedStack ────────────────────────────────────────────────────
  //
  // SendScreen / ReceiveScreen / SwapScreen / SettingsScreen / SecurityScreen
  // each accept an `insideShell` flag — when true they skip their own
  // AppBackground + Scaffold wrapper so the shell's Scaffold hosts them.

  Widget get _stack {
    final dest = ref.watch(shellNavProvider);
    return IndexedStack(
      index: dest.index,
      children: const [
        InvoicesScreen(), // 0
        ExpensesScreen(), // 1
        MerchantDashboard(), // 2
        TransactionsScreen(), // 3
        HomeScreen(), // 4
        AccountsScreen(), // 5
        CardsScreen(), // 6
        WorkflowsScreen(), // 7
        SendScreen(insideShell: true), // 8
        ReceiveScreen(insideShell: true), // 9
        SwapScreen(insideShell: true), // 10
        SettingsScreen(insideShell: true), // 11
        SecurityScreen(insideShell: true), // 12
        CheckoutScreen(insideShell: true), // 13
        AddProductScreen(insideShell: true), // 14
        EditProductScreen(insideShell: true), // 15
        ProductDetailScreen(insideShell: true), // 16
      ],
    );
  }

  // ── Menu overlay (mobile) ──────────────────────────────────────────────────

  void _openMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, animation, _) => _MenuOverlay(
          animation: animation,
          onNavigate: (dest) {
            Navigator.of(ctx).pop();
            if (dest != null) _navigate(dest);
          },
          onTestFund: () async {
            Navigator.of(ctx).pop();
            try {
              await apiService.testFundWallet();
              await ref.read(walletProvider.notifier).refresh();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Wallet funded with 1.0 XLM'),
                    backgroundColor: Color(0xFF4CAF50),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ Fund failed: $e'),
                    backgroundColor: const Color(0xFFE53935),
                    duration: const Duration(seconds: 3),
                  ),
                );
              }
            }
          },
        ),
        transitionsBuilder: (ctx, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 180),
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isWeb = MediaQuery.sizeOf(context).width >= _kWebBreakpoint;
    return isWeb ? _buildWebShell() : _buildMobileShell();
  }

  // ── Web shell ──────────────────────────────────────────────────────────────

  Widget _buildWebShell() {
    final dest = ref.watch(shellNavProvider);
    final notifier = ref.read(shellNavProvider.notifier);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            _SideNav(
              activeDest: dest,
              collapsed: _sideNavCollapsed,
              onSelectTab: _selectTab,
              onNavigate: _navigate,
              onToggleCollapse: () =>
                  setState(() => _sideNavCollapsed = !_sideNavCollapsed),
            ),
            Expanded(
              child: Column(
                children: [
                  _WebTopBar(
                    dest: dest,
                    onBack: notifier.isSubScreen ? _goBack : null,
                    onNavigate: _navigate,
                  ),
                  Expanded(child: _stack),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mobile shell ───────────────────────────────────────────────────────────

  Widget _buildMobileShell() {
    final dest = ref.watch(shellNavProvider);
    final isSubScreen = ref.read(shellNavProvider.notifier).isSubScreen;

    return Stack(
      children: [
        AppBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              bottom: false,
              child: SizedBox.expand(
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(32),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(32),
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Content area
                              Positioned.fill(
                                child: isSubScreen
                                    ? _stack
                                    : TabBarView(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        controller: _tabController,
                                        children: const [
                                          InvoicesScreen(),
                                          ExpensesScreen(),
                                          MerchantDashboard(),
                                          TransactionsScreen(),
                                          HomeScreen(),
                                          AccountsScreen(),
                                          CardsScreen(),
                                          WorkflowsScreen(),
                                        ],
                                      ),
                              ),
                              // Header overlay — only on main tabs
                              if (!isSubScreen)
                                _HeaderOverlay(
                                  ref: ref,
                                  tabController: _tabController,
                                  labels: _tabLabels,
                                  isRefreshing: false,
                                  isOnline: true,
                                  onRefresh: () {},
                                  onTap: _openMenu,
                                  onSettings: () =>
                                      _navigate(ShellDest.settings),
                                ),
                              // Back bar for sub-screens
                              if (isSubScreen)
                                Positioned(
                                  top: 0,
                                  left: 0,
                                  right: 0,
                                  child: _MobileSubBar(
                                    dest: dest,
                                    onBack: _goBack,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Side Nav ───────────────────────────────────────────────────────────────────

class _SideNav extends StatelessWidget {
  const _SideNav({
    required this.activeDest,
    required this.collapsed,
    required this.onSelectTab,
    required this.onNavigate,
    required this.onToggleCollapse,
  });

  final ShellDest activeDest;
  final bool collapsed;
  final void Function(int) onSelectTab;
  final void Function(ShellDest) onNavigate;
  final VoidCallback onToggleCollapse;

  static const _expandedWidth = 220.0;
  static const _collapsedWidth = 56.0;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: collapsed ? _collapsedWidth : _expandedWidth,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          right: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NavLogo(collapsed: collapsed),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _navGroups
                    .map(
                      (g) => _NavGroup(
                        label: g.label,
                        indices: g.indices,
                        activeDest: activeDest,
                        collapsed: collapsed,
                        onSelectTab: onSelectTab,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          _NavFooter(
            collapsed: collapsed,
            activeDest: activeDest,
            onToggleCollapse: onToggleCollapse,
            onNavigate: onNavigate,
          ),
        ],
      ),
    );
  }
}

class _NavLogo extends StatelessWidget {
  const _NavLogo({required this.collapsed});
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: cs.onSurface,
              borderRadius: BorderRadius.circular(7),
            ),
            alignment: Alignment.center,
            child: Text(
              'df',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: cs.surface,
                letterSpacing: -0.5,
              ),
            ),
          ),
          AnimatedOpacity(
            opacity: collapsed ? 0 : 1,
            duration: const Duration(milliseconds: 150),
            child: Padding(
              padding: const EdgeInsets.only(left: 10),
              child: Text(
                'dayfy',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavGroup extends StatelessWidget {
  const _NavGroup({
    required this.label,
    required this.indices,
    required this.activeDest,
    required this.collapsed,
    required this.onSelectTab,
  });

  final String label;
  final List<int> indices;
  final ShellDest activeDest;
  final bool collapsed;
  final void Function(int) onSelectTab;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedOpacity(
            opacity: collapsed ? 0 : 1,
            duration: const Duration(milliseconds: 150),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 10,
                  letterSpacing: 0.08,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.4),
                ),
              ),
            ),
          ),
          ...indices.map(
            (i) => _NavItem(
              tabIndex: i,
              activeDest: activeDest,
              collapsed: collapsed,
              onTap: () => onSelectTab(i),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tabIndex,
    required this.activeDest,
    required this.collapsed,
    required this.onTap,
  });

  final int tabIndex;
  final ShellDest activeDest;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isActive = activeDest.index == tabIndex;
    final badge = _tabBadges[tabIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: cs.onSurface.withOpacity(0.04),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 36,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 8),
          decoration: BoxDecoration(
            color: isActive ? cs.onSurface : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                _tabIcons[tabIndex],
                size: 17,
                color: isActive ? cs.surface : cs.onSurface.withOpacity(0.5),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _tabLabels[tabIndex],
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isActive
                          ? cs.surface
                          : cs.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? cs.surface.withOpacity(0.25)
                          : const Color(0xFFE24B4A),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$badge',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isActive ? cs.surface : Colors.white,
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NavFooter extends StatelessWidget {
  const _NavFooter({
    required this.collapsed,
    required this.activeDest,
    required this.onToggleCollapse,
    required this.onNavigate,
  });

  final bool collapsed;
  final ShellDest activeDest;
  final VoidCallback onToggleCollapse;
  final void Function(ShellDest) onNavigate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          _FooterItem(
            icon: Icons.shield_outlined,
            label: 'Security',
            collapsed: collapsed,
            isActive: activeDest == ShellDest.security,
            onTap: () => onNavigate(ShellDest.security),
          ),
          _FooterItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            collapsed: collapsed,
            isActive: activeDest == ShellDest.settings,
            onTap: () => onNavigate(ShellDest.settings),
          ),
          _FooterItem(
            icon: Icons.help_outline_rounded,
            label: 'Support',
            collapsed: collapsed,
            isActive: false,
            onTap: () => launchUrl(
              Uri.parse('https://dayfi.co/support'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 4),
          // Collapse toggle
          Align(
            alignment: collapsed ? Alignment.center : Alignment.centerRight,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: onToggleCollapse,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: AnimatedRotation(
                  turns: collapsed ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    Icons.chevron_left_rounded,
                    size: 18,
                    color: cs.onSurface.withOpacity(0.35),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          // User row — reads real name from userNotifierProvider
          Consumer(
            builder: (context, ref, _) {
              final userState = ref.watch(userNotifierProvider);

              // Adjust this to match your UserState's actual properties:
              final name = (userState.fullName?.isNotEmpty ?? false)
                  ? userState.fullName!
                  : 'User';

              final initials = name
                  .split(' ')
                  .where((w) => w.isNotEmpty)
                  .take(2)
                  .map((w) => w[0].toUpperCase())
                  .join();
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onNavigate(ShellDest.settings),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: cs.onSurface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          initials.isEmpty ? '?' : initials,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: cs.surface,
                          ),
                        ),
                      ),
                      if (!collapsed) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                name,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.bricolageGrotesque(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                              Text(
                                'Admin',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: cs.onSurface.withOpacity(0.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FooterItem extends StatelessWidget {
  const _FooterItem({
    required this.icon,
    required this.label,
    required this.collapsed,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool collapsed;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: cs.onSurface.withOpacity(0.04),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 34,
          padding: EdgeInsets.symmetric(horizontal: collapsed ? 0 : 8),
          decoration: BoxDecoration(
            color: isActive
                ? cs.onSurface.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                icon,
                size: 16,
                color: isActive
                    ? cs.onSurface.withOpacity(0.8)
                    : cs.onSurface.withOpacity(0.45),
              ),
              if (!collapsed) ...[
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.bricolageGrotesque(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                    color: isActive
                        ? cs.onSurface.withOpacity(0.8)
                        : cs.onSurface.withOpacity(0.55),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Web Top Bar ────────────────────────────────────────────────────────────────

class _WebTopBar extends StatelessWidget {
  const _WebTopBar({required this.dest, required this.onNavigate, this.onBack});

  final ShellDest dest;
  final void Function(ShellDest) onNavigate;
  final VoidCallback? onBack;

  String get _title {
    switch (dest) {
      case ShellDest.send:
        return 'Send';
      case ShellDest.receive:
        return 'Receive';
      case ShellDest.swap:
        return 'Swap';
      case ShellDest.settings:
        return 'Settings';
      case ShellDest.security:
        return 'Security';
      case ShellDest.checkout:
        return 'Checkout';
      case ShellDest.addProduct:
        return 'Add Product';
      case ShellDest.editProduct:
        return 'Edit Product';
      case ShellDest.productDetail:
        return 'Product Details';
      default:
        final i = dest.index;
        return i < _tabLabels.length ? _tabLabels[i] : '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.4)),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onBack,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: cs.onSurface.withOpacity(0.6),
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
          Text(
            _title,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const Spacer(),
          if (onBack == null) ...[
            _TBtn(label: 'Receive', onTap: () => onNavigate(ShellDest.receive)),
            const SizedBox(width: 8),
            _TBtn(label: 'Swap', onTap: () => onNavigate(ShellDest.swap)),
            const SizedBox(width: 8),
            _TBtn(
              label: '+ Send',
              filled: true,
              onTap: () => onNavigate(ShellDest.send),
            ),
          ],
        ],
      ),
    );
  }
}

class _TBtn extends StatelessWidget {
  const _TBtn({required this.label, required this.onTap, this.filled = false});
  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(7),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? cs.onSurface : Colors.transparent,
          border: Border.all(
            color: filled ? cs.onSurface : cs.onSurface.withOpacity(0.25),
          ),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Text(
          label,
          style: GoogleFonts.bricolageGrotesque(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: filled ? cs.surface : cs.onSurface,
          ),
        ),
      ),
    );
  }
}

// ── Mobile sub-screen back bar ─────────────────────────────────────────────────

class _MobileSubBar extends StatelessWidget {
  const _MobileSubBar({required this.dest, required this.onBack});
  final ShellDest dest;
  final VoidCallback onBack;

  String get _title {
    switch (dest) {
      case ShellDest.send:
        return 'Send';
      case ShellDest.receive:
        return 'Receive';
      case ShellDest.swap:
        return 'Swap';
      case ShellDest.settings:
        return 'Settings';
      case ShellDest.security:
        return 'Security';
      case ShellDest.checkout:
        return 'Checkout';
      case ShellDest.addProduct:
        return 'Add Product';
      case ShellDest.editProduct:
        return 'Edit Product';
      case ShellDest.productDetail:
        return 'Product Details';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      color: cs.surface.withOpacity(0.95),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: onBack,
          ),
          Text(
            _title,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile Header Overlay ──────────────────────────────────────────────────────

class _HeaderOverlay extends StatelessWidget {
  const _HeaderOverlay({
    required this.ref,
    required this.tabController,
    required this.labels,
    required this.isRefreshing,
    required this.isOnline,
    required this.onRefresh,
    required this.onSettings,
    this.onTap,
  });

  final WidgetRef ref;
  final TabController tabController;
  final List<String> labels;
  final bool isRefreshing;
  final bool isOnline;
  final VoidCallback onRefresh;
  final VoidCallback onSettings;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, right: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 46,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onSettings,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SvgPicture.asset(
                        'assets/icons/svgs/home_settings.svg',
                        height: 30,
                        colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onSurface,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'dayfy',
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.bricolageGrotesque(
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                      letterSpacing: 0,
                    ),
                  ),
                ),
                SizedBox(
                  width: 46,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: SvgPicture.asset(
                        'assets/icons/svgs/menu.svg',
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.55),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 3),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: AdaptiveLiquidGlassLayer(
              settings: const LiquidGlassSettings(thickness: 0.8, blur: 8.0),
              child: TabBar(
                physics: const NeverScrollableScrollPhysics(),
                controller: tabController,
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                isScrollable: true,
                tabAlignment: TabAlignment.center,
                indicator: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                labelStyle: GoogleFonts.bricolageGrotesque(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .2,
                  color: Theme.of(context).colorScheme.primary,
                ),
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelStyle: GoogleFonts.bricolageGrotesque(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .2,
                ),
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.55),
                padding: const EdgeInsets.symmetric(
                  vertical: 6,
                  horizontal: 200,
                ),
                tabs: labels
                    .map(
                      (label) => Tab(
                        height: 30,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(label),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}

// ── Menu Overlay ───────────────────────────────────────────────────────────────

class _MenuOverlay extends StatefulWidget {
  final Animation<double> animation;
  final void Function(ShellDest? dest) onNavigate;
  final VoidCallback onTestFund;

  const _MenuOverlay({
    required this.animation,
    required this.onNavigate,
    required this.onTestFund,
  });

  static const _items = [
    ('security', ShellDest.security),
    ('settings', ShellDest.settings),
  ];

  @override
  State<_MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<_MenuOverlay> {
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: () => Navigator.of(context).pop(),
        child: AppBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              centerTitle: true,
              automaticallyImplyLeading: false,
              title: Opacity(
                opacity: .45,
                child: Image.asset('assets/images/word_logo.png', width: 80),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    onTap: () => Navigator.of(context).pop(),
                    child: SvgPicture.asset(
                      'assets/icons/svgs/menu.svg',
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.55),
                    ),
                  ),
                ),
              ],
            ),
            body: SizedBox.expand(
              child: Column(
                children: [
                  const Expanded(child: SizedBox()),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ...List.generate(_MenuOverlay._items.length, (i) {
                        final item = _MenuOverlay._items[i];
                        return AnimatedBuilder(
                          animation: widget.animation,
                          builder: (ctx, child) {
                            final st = CurvedAnimation(
                              parent: widget.animation,
                              curve: Interval(
                                i * 0.08,
                                (i * 0.08 + 0.6).clamp(0.0, 1.0),
                                curve: Curves.easeOutCubic,
                              ),
                            );
                            return Transform.translate(
                              offset: Offset(60 * (1 - st.value), 0),
                              child: Opacity(
                                opacity: st.value.clamp(0.0, 1.0),
                                child: child,
                              ),
                            );
                          },
                          child: InkWell(
                            splashColor: Colors.transparent,
                            highlightColor: Colors.transparent,
                            hoverColor: Colors.transparent,
                            onTap: () => widget.onNavigate(item.$2),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                item.$1,
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w400,
                                      fontSize: 38,
                                      letterSpacing: -0.8,
                                    ),
                              ),
                            ),
                          ),
                        );
                      }),
                      // Support (external)
                      AnimatedBuilder(
                        animation: widget.animation,
                        builder: (ctx, child) {
                          final st = CurvedAnimation(
                            parent: widget.animation,
                            curve: const Interval(
                              0.16,
                              0.76,
                              curve: Curves.easeOutCubic,
                            ),
                          );
                          return Transform.translate(
                            offset: Offset(60 * (1 - st.value), 0),
                            child: Opacity(
                              opacity: st.value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          onTap: () {
                            Navigator.of(context).pop();
                            launchUrl(
                              Uri.parse('https://dayfi.co/support'),
                              mode: LaunchMode.externalApplication,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'support',
                              style: Theme.of(context).textTheme.displayLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w400,
                                    fontSize: 38,
                                    letterSpacing: -0.8,
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Expanded(child: SizedBox()),
                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final v = snapshot.data?.version ?? '—';
                      return Text('DayFi v$v (Build: 34)');
                    },
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
