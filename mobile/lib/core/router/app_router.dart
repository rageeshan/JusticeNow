import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/cases/my_cases_screen.dart';
import '../../presentation/screens/cases/report_case_screen.dart';
import '../../presentation/screens/cases/case_detail_screen.dart';
import '../../presentation/screens/legal_aid/legal_aid_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
<<<<<<< HEAD
=======
import '../../presentation/screens/home/home_screen.dart';
>>>>>>> origin/feat/Human-Rights-Case-Reporting

/// Named route constants
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
<<<<<<< HEAD
=======
  static const home = '/home';
>>>>>>> origin/feat/Human-Rights-Case-Reporting
  static const myCases = '/my-cases';
  static const reportCase = '/report-case';
  static const caseDetail = '/cases/:id';
  static const legalAid = '/legal-aid';
  static const dashboard = '/dashboard';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
<<<<<<< HEAD
=======
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
>>>>>>> origin/feat/Human-Rights-Case-Reporting
        path: AppRoutes.myCases,
        builder: (context, state) => const MyCasesScreen(),
      ),
      GoRoute(
        path: AppRoutes.reportCase,
        builder: (context, state) => const ReportCaseScreen(),
      ),
      GoRoute(
        path: AppRoutes.caseDetail,
        builder: (context, state) => CaseDetailScreen(
          caseId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.legalAid,
        builder: (context, state) => const LegalAidScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
});
