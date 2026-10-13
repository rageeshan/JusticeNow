import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/officer_cases_provider.dart';
import 'officer_evidence_screen.dart';
import 'officer_home_screen.dart';
import 'officer_my_cases_screen.dart';
import 'officer_profile_screen.dart';

final officerNavIndexProvider = StateProvider<int>((ref) => 0);

class OfficerShellScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  const OfficerShellScreen({super.key, this.initialIndex = 0});

  @override
  ConsumerState<OfficerShellScreen> createState() => _OfficerShellScreenState();
}

class _OfficerShellScreenState extends ConsumerState<OfficerShellScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialIndex != 0) {
        ref.read(officerNavIndexProvider.notifier).state = widget.initialIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = ref.watch(officerNavIndexProvider);
    final cases = ref.watch(officerCasesProvider);

    // Badges
    final urgentCount = cases.where((c) => c['status'] == 'submitted' || c['priority'] == 'critical').length;
    final evidenceReqCount = cases.where((c) => c['status'] == 'evidence_requested').length;

    const screens = [
      OfficerHomeScreen(),
      OfficerMyCasesScreen(),
      OfficerEvidenceScreen(),
      OfficerProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.primaryDark,
          border: Border(
            top: BorderSide(color: AppColors.divider, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              backgroundColor: AppColors.primaryDark,
              indicatorColor: AppColors.accent.withValues(alpha: 0.18),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    color: AppColors.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  );
                }
                return const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                );
              }),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: AppColors.accent, size: 24);
                }
                return const IconThemeData(color: AppColors.textSecondary, size: 22);
              }),
            ),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                ref.read(officerNavIndexProvider.notifier).state = index;
              },
              height: 64,
              destinations: [
                const NavigationDestination(
                  icon: Icon(Icons.dashboard_outlined),
                  selectedIcon: Icon(Icons.dashboard_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: urgentCount > 0,
                    label: Text(
                      urgentCount > 9 ? '9+' : '$urgentCount',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppColors.error,
                    child: const Icon(Icons.folder_shared_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: urgentCount > 0,
                    label: Text(
                      urgentCount > 9 ? '9+' : '$urgentCount',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppColors.error,
                    child: const Icon(Icons.folder_shared_rounded),
                  ),
                  label: 'My Cases',
                ),
                NavigationDestination(
                  icon: Badge(
                    isLabelVisible: evidenceReqCount > 0,
                    label: Text(
                      evidenceReqCount > 9 ? '9+' : '$evidenceReqCount',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppColors.warning,
                    child: const Icon(Icons.inventory_2_outlined),
                  ),
                  selectedIcon: Badge(
                    isLabelVisible: evidenceReqCount > 0,
                    label: Text(
                      evidenceReqCount > 9 ? '9+' : '$evidenceReqCount',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    backgroundColor: AppColors.warning,
                    child: const Icon(Icons.inventory_2_rounded),
                  ),
                  label: 'Evidence',
                ),
                const NavigationDestination(
                  icon: Icon(Icons.badge_outlined),
                  selectedIcon: Icon(Icons.badge_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
