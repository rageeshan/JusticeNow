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
import '../../presentation/screens/legal_aid/lawyer_profile_screen.dart';
import '../../presentation/screens/legal_aid/book_lawyer_screen.dart';
import '../../presentation/screens/legal_aid/booking_success_screen.dart';
import '../../presentation/screens/legal_aid/lawyer_case_detail_screen.dart';
import '../../presentation/screens/legal_aid/counsel_cases_screen.dart';
import '../../presentation/screens/legal_aid/manage_availability_screen.dart';
import '../../presentation/screens/legal_aid/submit_ad_screen.dart';
import '../../presentation/screens/legal_aid/lawyer_profile_update_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/home/home_screen.dart';
import '../../presentation/screens/admin/admin_dashboard_screen.dart';
import '../../presentation/screens/admin/admin_verifications_screen.dart';
import '../../presentation/screens/admin/admin_user_detail_screen.dart';
import '../../presentation/screens/admin/admin_case_list_screen.dart';
import '../../presentation/screens/admin/admin_case_detail_screen.dart';
import '../../presentation/screens/admin/admin_export_data_screen.dart';
import '../../presentation/screens/notifications/notifications_screen.dart';

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
  static const lawyerProfile = '/legal-aid/lawyer/:id';
  static const bookLawyer = '/legal-aid/book/:id';
  static const bookingSuccess = '/legal-aid/booking-success';
  static const lawyerCaseDetail = '/legal-aid/lawyer-case/:caseId';
  static const lawyerCases = '/lawyer/cases';
  static const lawyerAvailability = '/lawyer/availability';
  static const lawyerSubmitAd = '/lawyer/submit-ad';
  static const lawyerProfileUpdate = '/lawyer/profile';
  static const dashboard = '/dashboard';
  static const notifications = '/notifications';
  static const adminDashboard = '/admin/dashboard';
  static const adminExportData = '/admin/export-data';
  static const adminVerifications = '/admin/verifications';
  static const adminUserDetail = '/admin/verifications/:id';
  static const adminCases = '/admin/cases';
  static const adminCaseDetail = '/admin/cases/:id';
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
        path: AppRoutes.notifications,
        builder: (context, state) => const NotificationsScreen(),
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
        builder: (context, state) {
          final caseId = state.uri.queryParameters['caseId'] ??
              (state.extra is Map ? (state.extra as Map)['caseId']?.toString() : null);
          return LegalAidScreen(caseId: caseId);
        },
      ),
      GoRoute(
        path: AppRoutes.lawyerProfile,
        builder: (context, state) {
          final extraMap = state.extra is Map ? (state.extra as Map<String, dynamic>) : null;
          return LawyerProfileScreen(
            lawyerId: state.pathParameters['id']!,
            initialLawyer: extraMap?['lawyer'] as Map<String, dynamic>?,
            caseId: extraMap?['caseId'] as String?,
            caseData: extraMap?['case'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.bookLawyer,
        builder: (context, state) {
          final extraMap = state.extra is Map ? (state.extra as Map<String, dynamic>) : null;
          return BookLawyerScreen(
            lawyerId: state.pathParameters['id']!,
            lawyerData: extraMap?['lawyer'] as Map<String, dynamic>?,
            caseId: extraMap?['caseId'] as String?,
            initialCase: extraMap?['case'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.bookingSuccess,
        builder: (context, state) => const BookingSuccessScreen(),
      ),
      GoRoute(
        path: AppRoutes.lawyerCaseDetail,
        builder: (context, state) => LawyerCaseDetailScreen(
          caseId: state.pathParameters['caseId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.lawyerCases,
        builder: (context, state) {
          final tab = state.uri.queryParameters['tab'];
          final initialIndex = tab == 'in_progress' ? 1 : (tab == 'completed' ? 2 : 0);
          return CounselCasesScreen(initialTabIndex: initialIndex);
        },
      ),
      GoRoute(
        path: AppRoutes.lawyerAvailability,
        builder: (context, state) => const ManageAvailabilityScreen(),
      ),
      GoRoute(
        path: AppRoutes.lawyerSubmitAd,
        builder: (context, state) => const SubmitAdScreen(),
      ),
      GoRoute(
        path: AppRoutes.lawyerProfileUpdate,
        builder: (context, state) => const LawyerProfileUpdateScreen(),
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
        path: AppRoutes.adminExportData,
        builder: (context, state) => const AdminExportDataScreen(),
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
      GoRoute(
        path: '${AppRoutes.adminCases}/:id',
        builder: (context, state) => AdminCaseDetailScreen(
          caseId: state.pathParameters['id']!,
          initialCase: state.extra as Map<String, dynamic>?,
        ),
      ),
    ],
  );
});
