// lib/router.dart
//
// On web (all platforms that render MainShell), the routes /send /receive
// /swap /settings /security are handled INSIDE the shell via shellNavProvider.
// The GoRouter routes for those paths now redirect to /mainshell and set the
// provider state before doing so — handled by the redirect below.
//
// Routes that are always full-screen (auth flow, merchant checkout, public
// request pay, recovery phrase) are unchanged.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_app/providers/shell_navigation_provider.dart';
import 'package:mobile_app/screens/buy/buy_screen.dart';
import 'package:mobile_app/screens/portfolio/portfolio_screen.dart';
import 'package:mobile_app/screens/invoices/invoices_screen.dart';
import 'package:mobile_app/screens/organization/organization_screen.dart';
import 'package:mobile_app/screens/requests/public_request_pay_screen.dart';
import 'package:mobile_app/screens/merchant/merchant_dashboard.dart';
import 'package:mobile_app/screens/merchant/checkout_screen.dart';
import 'package:mobile_app/screens/expenses/expenses_screen.dart';
import 'package:mobile_app/screens/auth/business_onboarding_screen.dart';
import 'package:mobile_app/screens/auth/business_profile_screen.dart';
import 'package:mobile_app/screens/requests/requests_screen.dart';
import 'package:mobile_app/screens/security/security_screen.dart';
import 'package:mobile_app/screens/security/recovery_phrase_screen.dart';
import 'package:mobile_app/screens/transactions/transactions_screen.dart';
import 'package:mobile_app/screens/swap/swap_screen.dart';
import 'package:mobile_app/screens/auth/backup_screen.dart';
import 'package:mobile_app/screens/shell/main_shell.dart';
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

// ── Riverpod container ref (needed to write shellNavProvider from redirects) ──
// Pass your ProviderContainer / WidgetRef here at app startup.
// See main.dart usage note at bottom of this file.
ProviderContainer? shellRouterContainer;

// ── Transition helper ─────────────────────────────────────────────────────────

CustomTransitionPage buildFadeTransition({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

// ── Helper: navigate inside shell then redirect to /mainshell ─────────────────

String _shellRedirect(ShellDest dest) {
  shellRouterContainer?.read(shellNavProvider.notifier).goTo(dest);
  return '/mainshell';
}

// ── Router ────────────────────────────────────────────────────────────────────

final appRouter = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final token = await apiService.getToken();
    final isAuth = token != null;
    final loc = state.matchedLocation;

    final isPostSignup = loc == '/auth/biometric' || loc == '/auth/backup';
    final isPublicRequestPay = loc.startsWith('/requests/pay/');
    final isAuthRoute = loc.startsWith('/auth') && !isPostSignup;
    final isOnboarding = loc == '/onboarding';

    if (isAuth && (isAuthRoute || isOnboarding)) return '/mainshell';
    if (!isAuth &&
        !isAuthRoute &&
        !isOnboarding &&
        !isPostSignup &&
        !isPublicRequestPay) {
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

    // ── Shell ──────────────────────────────────────────────────────────────
    GoRoute(
      path: '/mainshell',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const MainShell(),
      ),
    ),
    GoRoute(path: '/home', redirect: (_, __) => _shellRedirect(ShellDest.home)),

    // ── Shell sub-screens (redirect into shell instead of full-screen) ──────
    GoRoute(
      path: '/send',
      redirect: (context, state) {
        // On mobile (narrow) allow full-screen; on web redirect into shell.
        // We always redirect into shell — SendScreen handles insideShell flag.
        final asset =
            (state.extra as Map<String, dynamic>?)?['asset'] as String?;
        shellRouterContainer
            ?.read(shellNavProvider.notifier)
            .goTo(ShellDest.send);
        return '/mainshell';
      },
    ),
    GoRoute(
      path: '/receive',
      redirect: (context, state) {
        shellRouterContainer
            ?.read(shellNavProvider.notifier)
            .goTo(ShellDest.receive);
        return '/mainshell';
      },
    ),
    GoRoute(path: '/swap', redirect: (_, __) => _shellRedirect(ShellDest.swap)),
    GoRoute(
      path: '/settings',
      redirect: (_, __) => _shellRedirect(ShellDest.settings),
    ),
    GoRoute(
      path: '/security',
      redirect: (_, __) => _shellRedirect(ShellDest.security),
    ),
    GoRoute(
      path: '/fund',
      redirect: (_, __) => _shellRedirect(ShellDest.receive),
    ),
    GoRoute(
      path: '/transactions',
      redirect: (_, __) => _shellRedirect(ShellDest.transactions),
    ),
    GoRoute(
      path: '/billing',
      redirect: (_, __) => _shellRedirect(ShellDest.billing),
    ),
    GoRoute(
      path: '/expenses',
      redirect: (_, __) => _shellRedirect(ShellDest.expenses),
    ),
    GoRoute(path: '/shop', redirect: (_, __) => _shellRedirect(ShellDest.shop)),
    GoRoute(
      path: '/workflows',
      redirect: (_, __) => _shellRedirect(ShellDest.workflows),
    ),
    GoRoute(
      path: '/shop/checkout',
      redirect: (_, __) => _shellRedirect(ShellDest.checkout),
    ),
    GoRoute(
      path: '/shop/add-product',
      redirect: (_, __) => _shellRedirect(ShellDest.addProduct),
    ),
    GoRoute(
      path: '/shop/edit-product',
      redirect: (_, __) => _shellRedirect(ShellDest.editProduct),
    ),
    GoRoute(
      path: '/shop/product',
      redirect: (_, __) => _shellRedirect(ShellDest.productDetail),
    ),

    // ── Onboarding ──────────────────────────────────────────────────────────
    GoRoute(
      path: '/onboarding',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const OnboardingScreen(),
      ),
    ),

    // ── Auth ────────────────────────────────────────────────────────────────
    GoRoute(
      path: '/auth/email',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: EmailScreen(
          isNewUser:
              (state.extra as Map<String, dynamic>?)?['isNewUser'] ?? true,
        ),
      ),
    ),
    GoRoute(
      path: '/auth/otp',
      pageBuilder: (context, state) {
        final extra = (state.extra as Map<String, dynamic>?) ?? {};
        return buildFadeTransition(
          context: context,
          state: state,
          child: OtpScreen(
            email: extra['email'] ?? '',
            isNewUser: extra['isNewUser'] ?? false,
            destination: extra['destination'],
          ),
        );
      },
    ),
    GoRoute(
      path: '/auth/business-profile',
      pageBuilder: (context, state) {
        final extra = (state.extra as Map<String, dynamic>?) ?? {};
        return buildFadeTransition(
          context: context,
          state: state,
          child: BusinessProfileScreen(
            setupToken: extra['setupToken'] ?? '',
            isNewUser: extra['isNewUser'] ?? true,
            existingData: extra['existingData'] as Map<String, dynamic>? ?? {},
          ),
        );
      },
    ),
    GoRoute(
      path: '/auth/business-onboarding',
      pageBuilder: (context, state) {
        final extra = (state.extra as Map<String, dynamic>?) ?? {};
        return buildFadeTransition(
          context: context,
          state: state,
          child: BusinessOnboardingScreen(
            setupToken: extra['setupToken'] ?? '',
            isNewUser: extra['isNewUser'] ?? true,
          ),
        );
      },
    ),
    GoRoute(
      path: '/auth/biometric',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const BiometricScreen(),
      ),
    ),
    GoRoute(
      path: '/auth/backup',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const BackupScreen(),
      ),
    ),

    // ── Always full-screen (modal / deep-link / external) ──────────────────
    GoRoute(
      path: '/buy',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const BuyScreen(),
      ),
    ),
    GoRoute(
      path: '/portfolio',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const PortfolioScreen(),
      ),
    ),
    GoRoute(
      path: '/security/phrase',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const RecoveryPhraseScreen(),
      ),
    ),
    GoRoute(
      path: '/merchant',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const MerchantDashboard(),
      ),
    ),
    GoRoute(
      path: '/merchant/checkout',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const CheckoutScreen(),
      ),
    ),
    GoRoute(
      path: '/invoices',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const InvoicesScreen(),
      ),
    ),
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
    GoRoute(
      path: '/requests',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const RequestsScreen(),
      ),
    ),
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
    GoRoute(
      path: '/organization',
      pageBuilder: (context, state) => buildFadeTransition(
        context: context,
        state: state,
        child: const OrganizationScreen(),
      ),
    ),
  ],
);

// ── main.dart usage note ───────────────────────────────────────────────────────
//
// In your main.dart, after creating your ProviderScope / ProviderContainer,
// assign it so redirects can write to shellNavProvider:
//
//   void main() {
//     final container = ProviderContainer();
//     shellRouterContainer = container;
//     runApp(UncontrolledProviderScope(
//       container: container,
//       child: MyApp(),
//     ));
//   }
//
// If you already use ProviderScope without a container, the simplest approach
// is to replace it with UncontrolledProviderScope using an explicit container.
