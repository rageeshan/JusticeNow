import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/screens/auth/splash_screen.dart';
import '../../presentation/screens/auth/onboarding_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/register_screen.dart';
import '../../presentation/screens/auth/registration_success_screen.dart';
import '../../presentation/screens/auth/pending_approval_screen.dart';
import '../../presentation/screens/auth/rejected_screen.dart';
import '../../presentation/screens/cases/my_cases_screen.dart';
import '../../presentation/screens/cases/report_case_screen.dart';
import '../../presentation/screens/cases/case_detail_screen.dart';
import '../../presentation/screens/legal_aid/legal_aid_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/admin_verifications_screen.dart';
import '../../presentation/screens/admin/admin_user_detail_screen.dart';
import '../../presentation/screens/admin/admin_case_list_screen.dart';

/// Named route constants
class AppRoutes {
  AppRoutes._();
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const registerSuccess = '/register/success';
  static const pendingApproval = '/auth/pending-approval';
  static const rejected = '/auth/rejected';
  static const home = '/home';
  static const myCases = '/my-cases';
  static const reportCase = '/report-case';
  static const caseDetail = '/cases/:id';
  static const legalAid = '/legal-aid';
  static const dashboard = '/dashboard';
  static const adminDashboard = '/admin/dashboard';
  static const adminVerifications = '/admin/verifications';
  static const adminUserDetail = '/admin/verifications/:id';
  static const adminCases = '/admin/cases';
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
        path: AppRoutes.registerSuccess,
        builder: (context, state) => RegistrationSuccessScreen(
          role: state.extra as String?,
        ),
      ),
      GoRoute(
        path: AppRoutes.pendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: AppRoutes.rejected,
        builder: (context, state) => RejectedScreen(
          rejectionReason: state.extra as String?,
        ),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
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
      GoRoute(
        path: AppRoutes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminVerifications,
        builder: (context, state) => const AdminVerificationsScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.adminVerifications}/:id',
        builder: (context, state) => AdminUserDetailScreen(
          userId: state.pathParameters['id']!,
          initialUser: state.extra as Map<String, dynamic>?,
        ),
      ),
      GoRoute(
        path: AppRoutes.adminCases,
        builder: (context, state) => const AdminCaseListScreen(),
      ),
    ],
  );
});
