// lib/screens/shell/main_shell.dart
//
// Redesigned shell — editorial/minimal aesthetic matching Zap402 + auth screens.
// Mobile: Claude-style bottom nav bar (5 primary tabs) + overflow menu.
// Web: Expanded side nav (220px), clean top bar, no heavy borders.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_app/providers/shell_navigation_provider.dart';
import 'package:mobile_app/providers/user_provider.dart';
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
import 'package:mobile_app/widgets/app_background.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:mobile_app/screens/merchant/add_product_screen.dart';
import 'package:mobile_app/screens/merchant/product_detail_screen.dart';

// ── Constants ──────────────────────────────────────────────────────────────────

const _kWebBreakpoint = 768.0;

// Bottom nav: 5 primary tabs for mobile
// Index maps to ShellDest
const _bottomNavItems = [
  _BottomNavDef(
    label: 'Home',
    icon: Icons.home_outlined,
    filledIcon: Icons.home_rounded,
    dest: ShellDest.home,
  ),
  _BottomNavDef(
    label: 'Billing',
    icon: Icons.receipt_long_outlined,
    filledIcon: Icons.receipt_long_rounded,
    dest: ShellDest.billing,
  ),
  _BottomNavDef(
    label: 'Accounts',
    icon: Icons.account_balance_wallet_outlined,
    filledIcon: Icons.account_balance_wallet_rounded,
    dest: ShellDest.accounts,
  ),
  _BottomNavDef(
    label: 'Expenses',
    icon: Icons.attach_money_outlined,
    filledIcon: Icons.attach_money,
    dest: ShellDest.expenses,
  ),
  _BottomNavDef(
    label: 'More',
    icon: Icons.grid_view_outlined,
    filledIcon: Icons.grid_view_rounded,
    dest: null,
  ),
];

// Side nav groups for web
const _navGroups = <_NavGroupDef>[
  _NavGroupDef(
    label: 'Overview',
    dests: [ShellDest.home, ShellDest.accounts, ShellDest.transactions],
  ),
  _NavGroupDef(
    label: 'Business',
    dests: [
      ShellDest.billing,
      ShellDest.expenses,
      ShellDest.shop,
      ShellDest.cards,
      ShellDest.workflows,
    ],
  ),
];

// Label + icon per dest
extension ShellDestMeta on ShellDest {
  String get label {
    switch (this) {
      case ShellDest.billing:
        return 'Billing';
      case ShellDest.expenses:
        return 'Expenses';
      case ShellDest.merchant:
        return 'Shop';
      case ShellDest.transactions:
        return 'Transactions';
      case ShellDest.home:
        return 'Home';
      case ShellDest.accounts:
        return 'Accounts';
      case ShellDest.cards:
        return 'Cards';
      case ShellDest.workflows:
        return 'Workflows';
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
      case ShellDest.invoices:
        return 'Billing';
      case ShellDest.merchant:
        return 'Shop';
      default:
        return '';
    }
  }

  IconData get icon {
    switch (this) {
      case ShellDest.billing:
        return Icons.receipt_long_outlined;
      case ShellDest.expenses:
        return Icons.attach_money_outlined;
      case ShellDest.merchant:
        return Icons.storefront_outlined;
      case ShellDest.invoices:
        return Icons.receipt_long_outlined;
      case ShellDest.transactions:
        return Icons.swap_horiz_outlined;
      case ShellDest.home:
        return Icons.home_outlined;
      case ShellDest.accounts:
        return Icons.account_balance_wallet_outlined;
      case ShellDest.cards:
        return Icons.credit_card_outlined;
      case ShellDest.workflows:
        return Icons.account_tree_outlined;
      case ShellDest.send:
        return Icons.arrow_upward_outlined;
      case ShellDest.receive:
        return Icons.arrow_downward_outlined;
      case ShellDest.swap:
        return Icons.swap_horiz_outlined;
      case ShellDest.settings:
        return Icons.settings_outlined;
      case ShellDest.security:
        return Icons.shield_outlined;
      case ShellDest.checkout:
        return Icons.shopping_cart_outlined;
      case ShellDest.addProduct:
        return Icons.add_box_outlined;
      case ShellDest.editProduct:
        return Icons.edit_outlined;
      case ShellDest.productDetail:
        return Icons.info_outline_rounded;
      case ShellDest.invoices:
        return Icons.receipt_long_outlined;
      default:
        return Icons.circle_outlined;
    }
  }
}

// ── Data classes ───────────────────────────────────────────────────────────────

class _BottomNavDef {
  final String label;
  final IconData icon;
  final IconData filledIcon;
  final ShellDest? dest; // null = "More" overflow
  const _BottomNavDef({
    required this.label,
    required this.icon,
    required this.filledIcon,
    required this.dest,
  });
}

class _NavGroupDef {
  final String label;
  final List<ShellDest> dests;
  const _NavGroupDef({required this.label, required this.dests});
}

// ── MainShell ──────────────────────────────────────────────────────────────────

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWeb = MediaQuery.sizeOf(context).width >= _kWebBreakpoint;
    return isWeb ? const _WebShell() : const _MobileShell();
  }
}

// ── Shared IndexedStack ────────────────────────────────────────────────────────

Widget buildStack() => const _ShellStack();

class _ShellStack extends StatelessWidget {
  const _ShellStack();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final dest = ref.watch(shellNavProvider);
        return IndexedStack(
          index: dest.index,
          children: const [
            InvoicesScreen(), // 0 billing
            ExpensesScreen(), // 1 expenses
            MerchantDashboard(), // 2 shop
            TransactionsScreen(), // 3 transactions
            HomeScreen(), // 4 home
            AccountsScreen(), // 5 accounts
            CardsScreen(), // 6 cards
            WorkflowsScreen(), // 7 workflows
            SendScreen(insideShell: true), // 8 send
            ReceiveScreen(insideShell: true), // 9 receive
            SwapScreen(insideShell: true), // 10 swap
            SettingsScreen(insideShell: true), // 11 settings
            SecurityScreen(insideShell: true), // 12 security
            CheckoutScreen(insideShell: true), // 13 checkout
            AddProductScreen(insideShell: true), // 14 addProduct
            EditProductScreen(insideShell: true), // 15 editProduct
            ProductDetailScreen(insideShell: true), // 16 productDetail
            // 17+ invoices, merchant — legacy aliases, point to same screens
            InvoicesScreen(), // 17 invoices (alias)
            MerchantDashboard(), // 18 merchant (alias)
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// WEB SHELL
// ══════════════════════════════════════════════════════════════════════════════

class _WebShell extends ConsumerWidget {
  const _WebShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dest = ref.watch(shellNavProvider);
    final notifier = ref.read(shellNavProvider.notifier);

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Row(
          children: [
            _WebSideNav(activeDest: dest, onNavigate: (d) => notifier.goTo(d)),
            Expanded(
              child: Column(
                children: [
                  _WebTopBar(
                    dest: dest,
                    onBack: notifier.isSubScreen ? notifier.goBack : null,
                    onNavigate: (d) => notifier.goTo(d),
                  ),
                  const Expanded(child: _ShellStack()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Web Side Nav ───────────────────────────────────────────────────────────────

class _WebSideNav extends ConsumerWidget {
  const _WebSideNav({required this.activeDest, required this.onNavigate});

  final ShellDest activeDest;
  final void Function(ShellDest) onNavigate;

  static const _width = 220.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: _width,
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          right: BorderSide(color: cs.onSurface.withOpacity(0.06)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Text(
              'dayfy',
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: cs.onSurface,
                letterSpacing: -0.5,
              ),
            ),
          ),

          // Nav groups
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _navGroups
                    .map(
                      (g) => _WebNavGroup(
                        group: g,
                        activeDest: activeDest,
                        onNavigate: onNavigate,
                      ),
                    )
                    .toList(),
              ),
            ),
          ),

          // Footer
          _WebNavFooter(activeDest: activeDest, onNavigate: onNavigate),
        ],
      ),
    );
  }
}

class _WebNavGroup extends StatelessWidget {
  const _WebNavGroup({
    required this.group,
    required this.activeDest,
    required this.onNavigate,
  });

  final _NavGroupDef group;
  final ShellDest activeDest;
  final void Function(ShellDest) onNavigate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: Text(
              group.label.toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: cs.onSurface.withOpacity(0.55),
              ),
            ),
          ),
          ...group.dests.map(
            (d) => _WebNavItem(
              dest: d,
              isActive: activeDest == d,
              onTap: () => onNavigate(d),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebNavItem extends StatelessWidget {
  const _WebNavItem({
    required this.dest,
    required this.isActive,
    required this.onTap,
  });

  final ShellDest dest;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: cs.onSurface.withOpacity(0.04),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isActive
                ? cs.onSurface.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                dest.icon,
                size: 16,
                color: isActive
                    ? cs.onSurface.withOpacity(0.9)
                    : cs.onSurface.withOpacity(0.45),
              ),
              const SizedBox(width: 10),
              Text(
                dest.label,
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 14,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w600,
                  color: isActive
                      ? cs.onSurface.withOpacity(0.9)
                      : cs.onSurface.withOpacity(0.55),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebNavFooter extends ConsumerWidget {
  const _WebNavFooter({required this.activeDest, required this.onNavigate});

  final ShellDest activeDest;
  final void Function(ShellDest) onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final userState = ref.watch(userNotifierProvider);
    final name = (userState.fullName?.isNotEmpty ?? false)
        ? userState.fullName!
        : 'User';
    final initials = name
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 20),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.onSurface.withOpacity(0.06))),
      ),
      child: Column(
        children: [
          _WebNavItem(
            dest: ShellDest.security,
            isActive: activeDest == ShellDest.security,
            onTap: () => onNavigate(ShellDest.security),
          ),
          _WebNavItem(
            dest: ShellDest.settings,
            isActive: activeDest == ShellDest.settings,
            onTap: () => onNavigate(ShellDest.settings),
          ),
          const SizedBox(height: 4),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onNavigate(ShellDest.settings),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                        fontWeight: FontWeight.w700,
                        color: cs.surface,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
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
                            fontWeight: FontWeight.w600,
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
              ),
            ),
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          bottom: BorderSide(color: cs.onSurface.withOpacity(0.06)),
        ),
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onBack,
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 15,
                  color: cs.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Text(
            dest.label,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          if (onBack == null) ...[
            _TopBarBtn(
              label: 'Receive',
              onTap: () => onNavigate(ShellDest.receive),
            ),
            const SizedBox(width: 8),
            _TopBarBtn(label: 'Swap', onTap: () => onNavigate(ShellDest.swap)),
            const SizedBox(width: 8),
            _TopBarBtn(
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

class _TopBarBtn extends StatelessWidget {
  const _TopBarBtn({
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: filled ? cs.onSurface : Colors.transparent,
          border: Border.all(
            color: filled ? cs.onSurface : cs.onSurface.withOpacity(0.15),
          ),
          borderRadius: BorderRadius.circular(8),
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

// ══════════════════════════════════════════════════════════════════════════════
// MOBILE SHELL
// ══════════════════════════════════════════════════════════════════════════════

class _MobileShell extends ConsumerWidget {
  const _MobileShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dest = ref.watch(shellNavProvider);
    final notifier = ref.read(shellNavProvider.notifier);
    final isSubScreen = notifier.isSubScreen;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Mobile top bar (logo + actions)
              if (!isSubScreen)
                _MobileTopBar(
                  onSettings: () => notifier.goTo(ShellDest.settings),
                )
              else
                _MobileSubBar(dest: dest, onBack: notifier.goBack),

              // Content
              Expanded(child: _ShellStack()),
            ],
          ),
        ),
        bottomNavigationBar: isSubScreen
            ? null
            : _MobileBottomNav(
                activeDest: dest,
                onNavigate: (d) {
                  if (d == null) {
                    _showMoreSheet(context, ref);
                  } else {
                    notifier.goTo(d);
                  }
                },
              ),
      ),
    );
  }

  void _showMoreSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _MoreSheet(
        onNavigate: (d) {
          Navigator.of(context).pop();
          ref.read(shellNavProvider.notifier).goTo(d);
        },
      ),
    );
  }
}

// ── Mobile Top Bar ─────────────────────────────────────────────────────────────

class _MobileTopBar extends StatelessWidget {
  const _MobileTopBar({required this.onSettings});
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Text(
            'dayfy',
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            splashColor: Colors.transparent,
            onTap: onSettings,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.settings_outlined,
                size: 22,
                color: cs.onSurface.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile Sub Bar (back navigation) ──────────────────────────────────────────

class _MobileSubBar extends StatelessWidget {
  const _MobileSubBar({required this.dest, required this.onBack});
  final ShellDest dest;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            splashColor: Colors.transparent,
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
          Text(
            dest.label,
            style: GoogleFonts.bricolageGrotesque(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile Bottom Nav ──────────────────────────────────────────────────────────

class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav({required this.activeDest, required this.onNavigate});

  final ShellDest activeDest;
  final void Function(ShellDest? dest) onNavigate;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.onSurface.withOpacity(0.07))),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Row(
        children: _bottomNavItems.map((item) {
          final isActive = item.dest != null && activeDest == item.dest;
          return Expanded(
            child: InkWell(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
              onTap: () => onNavigate(item.dest),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        isActive ? item.filledIcon : item.icon,
                        key: ValueKey(isActive),
                        size: 22,
                        color: isActive
                            ? cs.onSurface
                            : cs.onSurface.withOpacity(0.4),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.label,
                      style: GoogleFonts.bricolageGrotesque(
                        fontSize: 10,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isActive
                            ? cs.onSurface
                            : cs.onSurface.withOpacity(0.4),
                        letterSpacing: 0.1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── More Sheet (overflow tabs) ─────────────────────────────────────────────────

class _MoreSheet extends ConsumerWidget {
  const _MoreSheet({required this.onNavigate});
  final void Function(ShellDest) onNavigate;

  static const _overflowDests = [
    ShellDest.transactions,
    ShellDest.shop,
    ShellDest.cards,
    ShellDest.workflows,
    ShellDest.security,
    ShellDest.settings,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: cs.onSurface.withOpacity(0.07))),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 32,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'More',
                style: GoogleFonts.bricolageGrotesque(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            // Grid of tiles
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.3,
                children: _overflowDests
                    .map((d) => _MoreTile(dest: d, onTap: () => onNavigate(d)))
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Version
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snap) => Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'DayFi v${snap.data?.version ?? '—'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreTile extends StatelessWidget {
  const _MoreTile({required this.dest, required this.onTap});
  final ShellDest dest;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      splashColor: Colors.transparent,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cs.onSurface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(dest.icon, size: 22, color: cs.onSurface.withOpacity(0.6)),
            const SizedBox(height: 6),
            Text(
              dest.label,
              style: GoogleFonts.bricolageGrotesque(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withOpacity(0.65),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
