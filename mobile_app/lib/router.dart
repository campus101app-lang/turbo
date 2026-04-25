// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/screens/buy/buy_screen.dart';
import 'package:mobile_app/screens/portfolio/portfolio_screen.dart';
import 'package:mobile_app/screens/invoices/invoices_screen.dart';
import 'package:mobile_app/screens/organization/organization_screen.dart';
import 'package:mobile_app/screens/requests/public_request_pay_screen.dart';
import 'package:mobile_app/screens/shell/main_shell.dart';
import 'package:mobile_app/screens/swap/swap_screen.dart';
import 'package:mobile_app/screens/auth/backup_screen.dart';
import 'package:mobile_app/screens/auth/business_profile_screen.dart';
import 'package:mobile_app/screens/auth/business_onboarding_screen.dart';
import 'package:mobile_app/screens/requests/requests_screen.dart';
import 'package:mobile_app/screens/security/security_screen.dart';
import 'package:mobile_app/screens/security/recovery_phrase_screen.dart';
import 'package:mobile_app/screens/transactions/transactions_screen.dart';
import 'package:mobile_app/screens/workflows/workflows_screen.dart';
import 'screens/auth/email_screen.dart';
import 'screens/auth/otp_screen.dart';
import 'screens/auth/biometric_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/receive/receive_screen.dart';
import 'screens/send/send_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'services/api_service.dart';
import 'screens/merchant/merchant_dashboard.dart';
import 'screens/merchant/checkout_screen.dart';
import 'screens/expenses/expenses_screen.dart';
import 'screens/invoices/invoices_screen.dart';

// Custom fade transition
CustomTransitionPage buildFadeTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: child,
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final token = await apiService.getToken();
    final isAuth = token != null;
    final loc = state.matchedLocation;

    // These are allowed even when authenticated (post-signup flow)
    final isPostSignup = loc == '/auth/biometric' || loc == '/auth/backup';
    final isPublicRequestPay = loc.startsWith('/requests/pay/');
    final isAuthRoute = loc.startsWith('/auth') && !isPostSignup;
    final isOnboarding = loc == '/onboarding';

    if (isAuth && (isAuthRoute || isOnboarding)) return '/mainshell';
    if (!isAuth && !isAuthRoute && !isOnboarding && !isPostSignup && !isPublicRequestPay) {
      return '/onboarding';
    }
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      redirect: (_, __) async {
        final token = await apiService.getToken();
        return token != null ? '/mainshell' : '/onboarding';
      },
    ),

    GoRoute(path: '/mainshell', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const MainShell(),
    )),
    GoRoute(path: '/home', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const HomeScreen(),
    )),

    // ── Onboarding ──────────────────────────────────────────
    GoRoute(path: '/onboarding', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const OnboardingScreen(),
    )),

    // ── Auth ────────────────────────────────────────────────
    GoRoute(
      path: '/auth/email',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: EmailScreen(isNewUser: (state.extra as Map<String, dynamic>?)?['isNewUser'] ?? true),
      ),
    ),
    GoRoute(
      path: '/auth/otp',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: OtpScreen(
          email: (state.extra as Map<String, dynamic>)['email'],
          isNewUser: (state.extra as Map<String, dynamic>)['isNewUser'] ?? false,
          destination: (state.extra as Map<String, dynamic>)['destination'],
        ),
      ),
    ),

    // username_screen.dart is DELETED — all new-user post-OTP flows
    // land here instead.
    GoRoute(
      path: '/auth/business-onboarding',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: BusinessOnboardingScreen(
          setupToken: (state.extra as Map<String, dynamic>)['setupToken'] ?? '',
        ),
      ),
    ),

    GoRoute(
      path: '/auth/biometric',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const BiometricScreen(),
      ),
    ),
    GoRoute(path: '/auth/backup', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const BackupScreen(),
    )),

    // ── Main app ─────────────────────────────────────────────
    GoRoute(
      path: '/receive',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: ReceiveScreen(initialAsset: (state.extra as Map<String, dynamic>?)?['asset'] as String?),
      ),
    ),
    GoRoute(
      path: '/send',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: SendScreen(initialAsset: (state.extra as Map<String, dynamic>?)?['asset'] as String?),
      ),
    ),

    GoRoute(path: '/buy', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const BuyScreen(),
    )),
    GoRoute(path: '/swap', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const SwapScreen(),
    )),
    GoRoute(
      path: '/transactions',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const TransactionsScreen(),
      ),
    ),
    GoRoute(path: '/settings', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const SettingsScreen(),
    )),
    GoRoute(path: '/portfolio', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const PortfolioScreen(),
    )),

    // ── Fund with NGN shortcut ───────────────────────────────
    // Navigating to /fund just opens the Receive screen on Tab 2 (NGN)
    GoRoute(
      path: '/fund',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const ReceiveScreen(initialAsset: 'NGNT'),
      ),
    ),

    // ── Security ─────────────────────────────────────────────
    GoRoute(path: '/security', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const SecurityScreen(),
    )),
    GoRoute(
      path: '/security/phrase',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const RecoveryPhraseScreen(),
      ),
    ),

    // ── Merchant ─────────────────────────────────────────────
    GoRoute(path: '/merchant', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const MerchantDashboard(),
    )),
    GoRoute(
      path: '/merchant/checkout',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const CheckoutScreen(),
      ),
    ),
    // ── Invoices ─────────────────────────────────────────
    GoRoute(path: '/invoices', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const InvoicesScreen(),
    )),
    GoRoute(
      path: '/invoices/:id',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: Scaffold(
          appBar: AppBar(title: const Text('Invoice Detail')),
          body: Center(child: Text('Invoice: ${state.pathParameters['id']}')),
        ),
      ),
    ),

    // ── Expenses ─────────────────────────────────────────
    GoRoute(path: '/expenses', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const ExpensesScreen(),
    )),

    GoRoute(path: '/requests', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const RequestsScreen(),
    )),
    GoRoute(
      path: '/requests/pay/:requestNumber',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: PublicRequestPayScreen(
          requestNumber: state.pathParameters['requestNumber'] ?? '',
        ),
      ),
    ),

    GoRoute(path: '/workflows', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const WorkflowsScreen(),
    )),

    // ── Organization ─────────────────────────────────────────
    GoRoute(path: '/organization', pageBuilder: (context, state) => buildFadeTransition(
      context: context,
      state: state,
      child: const OrganizationScreen(),
    )),

    // GoRoute(
    //   path: '/expenses/create',
    //   builder: (_, __) => const CreateEditExpenseScreen(),
    // ),
    // GoRoute(
    //   path: '/expenses/:id',
    //   builder: (_, state) {
    //     final id = state.pathParameters['id'];
    //     return CreateEditExpenseScreen(expenseId: id);
    //   },
    // ),
  ],
);
