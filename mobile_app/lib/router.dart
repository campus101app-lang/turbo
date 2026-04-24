// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/screens/buy/buy_screen.dart';
import 'package:mobile_app/screens/portfolio/portfolio_screen.dart';
import 'package:mobile_app/screens/requests/requests_screen.dart';
import 'package:mobile_app/screens/requests/public_request_pay_screen.dart';
import 'package:mobile_app/screens/shell/main_shell.dart';
import 'package:mobile_app/screens/swap/swap_screen.dart';
import 'package:mobile_app/screens/auth/backup_screen.dart';
import 'package:mobile_app/screens/auth/business_profile_screen.dart';
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

    GoRoute(path: '/mainshell', builder: (_, __) => const MainShell()),
    GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),

    // ── Onboarding ──────────────────────────────────────────
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

    // ── Auth ────────────────────────────────────────────────
    GoRoute(
      path: '/auth/email',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return EmailScreen(isNewUser: extra?['isNewUser'] ?? true);
      },
    ),
    GoRoute(
      path: '/auth/otp',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return OtpScreen(
          email: extra['email'],
          isNewUser: extra['isNewUser'] ?? false,
        );
      },
    ),

    // username_screen.dart is DELETED — all new-user post-OTP flows
    // land here instead.
    GoRoute(
      path: '/auth/business-profile',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>;
        return BusinessProfileScreen(setupToken: extra['setupToken']);
      },
    ),

    GoRoute(
      path: '/auth/biometric',
      builder: (_, __) => const BiometricScreen(),
    ),
    GoRoute(path: '/auth/backup', builder: (_, __) => const BackupScreen()),

    // ── Main app ─────────────────────────────────────────────
    GoRoute(
      path: '/receive',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ReceiveScreen(initialAsset: extra?['asset'] as String?);
      },
    ),
    GoRoute(
      path: '/send',
      builder: (_, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return SendScreen(initialAsset: extra?['asset'] as String?);
      },
    ),

    GoRoute(path: '/buy', builder: (_, __) => const BuyScreen()),
    GoRoute(path: '/swap', builder: (_, __) => const SwapScreen()),
    GoRoute(
      path: '/transactions',
      builder: (_, __) => const TransactionsScreen(),
    ),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(path: '/portfolio', builder: (_, __) => const PortfolioScreen()),

    // ── Fund with NGN shortcut ───────────────────────────────
    // Navigating to /fund just opens the Receive screen on Tab 2 (NGN)
    GoRoute(
      path: '/fund',
      builder: (_, __) => const ReceiveScreen(initialAsset: 'NGNT'),
    ),

    // ── Security ─────────────────────────────────────────────
    GoRoute(path: '/security', builder: (_, __) => const SecurityScreen()),
    GoRoute(
      path: '/security/phrase',
      builder: (_, __) => const RecoveryPhraseScreen(),
    ),

    // ── Merchant ─────────────────────────────────────────────
    GoRoute(path: '/merchant', builder: (_, __) => const MerchantDashboard()),
    GoRoute(
      path: '/merchant/checkout',
      builder: (_, __) => const CheckoutScreen(),
    ),
    // ── Invoices ─────────────────────────────────────────
    GoRoute(path: '/invoices', builder: (_, __) => const InvoicesScreen()),
    GoRoute(
      path: '/invoices/:id',
      builder: (_, state) {
        final id = state.pathParameters['id'];
        return Scaffold(
          appBar: AppBar(title: const Text('Invoice Detail')),
          body: Center(child: Text('Invoice: $id')),
        );
      },
    ),

    // ── Expenses ─────────────────────────────────────────
    GoRoute(path: '/expenses', builder: (_, __) => const ExpensesScreen()),

    GoRoute(path: '/requests', builder: (_, __) => const RequestsScreen()),
    GoRoute(
      path: '/requests/pay/:requestNumber',
      builder: (_, state) => PublicRequestPayScreen(
        requestNumber: state.pathParameters['requestNumber'] ?? '',
      ),
    ),

    GoRoute(path: '/workflows', builder: (_, __) => const WorkflowsScreen()),

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
