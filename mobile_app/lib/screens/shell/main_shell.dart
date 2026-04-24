// lib/screens/shell/main_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:mobile_app/providers/wallet_provider.dart';
import 'package:mobile_app/screens/accounts/accounts_screen.dart';
import 'package:mobile_app/screens/home/home_screen.dart';
import 'package:mobile_app/screens/invoices/invoices_screen.dart';
import 'package:mobile_app/screens/expenses/expenses_screen.dart';
// import 'package:mobile_app/screens/portfolio/portfolio_screen.dart';
import 'package:mobile_app/screens/settings/settings_screen.dart';
import 'package:mobile_app/screens/transactions/transactions_screen.dart';
import 'package:mobile_app/services/api_service.dart';
import 'package:mobile_app/widgets/app_background.dart';
// import 'package:mobile_app/widgets/adaptive_bottom_navigation_bar.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const _tabsText = [
  // _TabData(icon: 'assets/icons/svgs/my_shop.svg', label: 'Get started'),
  // _TabData(icon: 'assets/icons/svgs/wallet.svg', label: 'Cards'),
  'Accounts',
  // 'Investments',
  'Transactions',
  'Dashboard',
  // 'Requests',
  'Invoicing',
  'Expenses',
];

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this, initialIndex: 2);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openMenu() {
    final userAsync = ref.read(userProvider);
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (ctx, animation, _) => _MenuOverlay(
          animation: animation,
          onNavigate: (route) {
            Navigator.of(ctx).pop();
            if (route != null) context.push(route);
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
        transitionsBuilder: (ctx, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 180),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AppBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              centerTitle: true,
              automaticallyImplyLeading: false,
              title: _buildTopBar(context),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    onTap: _openMenu,
                    child: SvgPicture.asset(
                      "assets/icons/svgs/menu.svg",
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
                  Expanded(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      child: Container(
                        // padding: const EdgeInsets.only(bottom: 32),
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                        ),
                        child: Stack(
                          children: [
                            // ── Tab content ──────────────────────────
                            Positioned.fill(
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  // Tab 0: Accounts
                                  const AccountsScreen(),
                                  // Tab 1: Transactions
                                  TransactionsScreen(
                                    tabController: _tabController,
                                  ),
                                  // Tab 2: Dashboard
                                  const HomeScreen(),
                                  // Tab 3: Invoicing
                                  const InvoicesScreen(),
                                  // Tab 4: Expenses
                                  const ExpensesScreen(),
                                ],
                              ),
                            ),
                            // ── Header overlay ───────────────────────
                            _HeaderOverlay(
                              ref: ref,
                              tabController: _tabController,
                              labels: _tabsText,
                              isRefreshing: false,
                              isOnline: true,
                              onRefresh: () {},
                              onTap: _openMenu,
                              onSettings: () => Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const SettingsScreen(),
                                ),
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
            bottomNavigationBar: 
            // _tabController.index == 0
            //     ?
                 _buildActionRow()
                // : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActionRow() {
    final walletState = ref.watch(walletProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 112, vertical: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).textTheme.bodySmall!.color!.withOpacity(0.1),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.04),
          ),
        ),
        child: Row(
          children: [
            _ActionButton(
              icon: "assets/icons/svgs/receive.svg",
              label: 'Receive',
              onTap: () => context.push('/receive'),
            ),
            // _ActionButton(
            //   icon: "assets/icons/svgs/swap.svg",
            //   label: 'Swap',
            //   onTap: () => _handleSwapTap(walletState),
            // ),
            _ActionButton(
              icon: "assets/icons/svgs/send.svg",
              label: 'Send',
              onTap: () => _handleSendTap(walletState),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.4, end: 0);
  }

  void _handleSendTap(WalletState walletState) {
    if (walletState.usdcBalance == 0 && walletState.xlmBalance == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Cannot send: wallet has no balance'),
          backgroundColor: Color(0xFFFFA726),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    context.push('/send');
  }

  void _handleSwapTap(WalletState walletState) {
    if (walletState.usdcBalance == 0 && walletState.xlmBalance == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Cannot swap: wallet has no balance'),
          backgroundColor: Color(0xFFFFA726),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }
    context.push('/swap');
  }
}

// ─── Action Button ────────────────────────────────────────

class _ActionButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        hoverColor: Colors.transparent,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                icon,
                height: 22,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(.60),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(.60),
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabData {
  final String icon;
  final String label;
  const _TabData({required this.icon, required this.label});
}

// ─── Menu Overlay (separate route, no flash) ─────────────────────────────────

class _MenuOverlay extends StatefulWidget {
  final Animation<double> animation;
  final void Function(String? route) onNavigate;
  final VoidCallback onTestFund;

  const _MenuOverlay({
    required this.animation,
    required this.onNavigate,
    required this.onTestFund,
  });

  static const _items = [
    // ('transactions', '/transactions'),
    // ('merchant', '/merchant'),
    ('security', '/security'),
    ('settings', '/settings'),
    ('support', 'https://dayfi.co/support'),
  ];

  @override
  State<_MenuOverlay> createState() => _MenuOverlayState();
}

class _MenuOverlayState extends State<_MenuOverlay> {
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version; // e.g. "1.0.1"
      _buildNumber = info.buildNumber; // e.g. "47"
    });
  }

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
              title: _buildTopBar(context),
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
                      "assets/icons/svgs/menu.svg",
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
                    children: List.generate(_MenuOverlay._items.length, (i) {
                      final item = _MenuOverlay._items[i];
                      return AnimatedBuilder(
                        animation: widget.animation,
                        builder: (ctx, child) {
                          // Stagger: each item starts slightly later
                          final staggered = CurvedAnimation(
                            parent: widget.animation,
                            curve: Interval(
                              i * 0.08,
                              (i * 0.08 + 0.6).clamp(0.0, 1.0),
                              curve: Curves.easeOutCubic,
                            ),
                          );
                          return Transform.translate(
                            offset: Offset(60 * (1 - staggered.value), 0),
                            child: Opacity(
                              opacity: staggered.value.clamp(0.0, 1.0),
                              child: child,
                            ),
                          );
                        },
                        child: InkWell(
                          splashColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          // behavior: HitTestBehavior.opaque,
                          onTap: () {
                            final dest = item.$2;
                            if (dest.startsWith('http')) {
                              launchUrl(
                                Uri.parse(dest),
                                mode: LaunchMode.externalApplication,
                              );
                            } else {
                              widget.onNavigate(dest);
                            }
                          },
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
                  ),
                  const Expanded(child: SizedBox()),

                  FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      final version = snapshot.data?.version ?? '—';
                      final build = snapshot.data?.buildNumber ?? '—';
                      return Text("DayFi v$version (Build: 34)");
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

Widget _buildTopBar(context) {
  return Opacity(
    opacity: .45,
    child: Image.asset("assets/images/word_logo.png", width: 80),
  );
}

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
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    // final colorScheme = Theme.of(context).colorScheme;
    // final ext = AppThemeExtension.of(context);

    return Container(
      decoration: const BoxDecoration(
        // gradient: LinearGradient(
        //   begin: Alignment.topCenter,
        //   end: Alignment.bottomCenter,
        //   colors: [
        //     const Color(0xff010E1F).withValues(alpha: .95),
        //     const Color(0xff010E1F).withValues(alpha: .95),
        //     const Color(0xff010E1F).withValues(alpha: .95),
        //     const Color(0xff010E1F).withValues(alpha: .95),
        //     const Color(0xff010E1F).withValues(alpha: .95),
        //     const Color(0xff010E1F).withValues(alpha: .95),
        //     const Color(0xff010E1F).withValues(alpha: .95),
        //     const Color(0xff010E1F).withValues(alpha: .95),
        //     const Color(0xff010E1F).withValues(alpha: .95),
        //     const Color(0xff010E1F).withValues(alpha: .95),
        //     const Color(0xff010E1F).withValues(alpha: 0),
        //   ],
        // ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 48,
            child: AdaptiveLiquidGlassLayer(
              settings: const LiquidGlassSettings(thickness: 0.8, blur: 8.0),
              child: TabBar(
                controller: tabController,
                splashFactory: NoSplash.splashFactory,
                overlayColor: WidgetStateProperty.all(Colors.transparent),
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).textTheme.bodySmall?.color?.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(100),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.color!.withOpacity(.85),
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  letterSpacing: -.1,
                ),
                labelColor: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color!.withOpacity(.85),
                unselectedLabelStyle: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(
                      color: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.color!.withOpacity(.5),
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      letterSpacing: -.1,
                    ),
                unselectedLabelColor: Theme.of(
                  context,
                ).textTheme.bodyLarge?.color!.withOpacity(.5),
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
