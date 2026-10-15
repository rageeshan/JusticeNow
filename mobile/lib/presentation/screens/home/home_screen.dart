import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/legal_aid_repository.dart';
import '../../../providers/auth_provider.dart';

import '../legal_aid/counsel_cases_screen.dart';
import '../legal_aid/manage_availability_screen.dart';
import '../legal_aid/submit_ad_screen.dart';
import '../legal_aid/lawyer_profile_update_screen.dart';
import '../officer/officer_my_cases_screen.dart';
import '../officer/officer_manage_availability_screen.dart';
import '../officer/officer_profile_update_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// Map backend role strings to user-friendly labels
  String _roleLabel(String? role) {
    switch (role) {
      case 'citizen':
        return 'Citizen';
      case 'police_officer':
        return 'Police Officer';
      case 'lawyer':
        return 'Lawyer';
      case 'admin':
        return 'Admin';
      case 'anonymous':
        return 'Anonymous';
      default:
        return 'User';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final fullName = user?['profile']?['fullName'] ?? user?['alias'] ?? 'User';
    final role = user?['role'] as String?;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(role == 'lawyer'
            ? 'Lawyer Dashboard'
            : (role == 'police_officer' ? 'Police Dashboard' : 'JusticeNow')),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          if (role == 'lawyer') ...[
            IconButton(
              icon: const Icon(Icons.account_circle_outlined, color: AppColors.accent, size: 26),
              tooltip: 'Update Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LawyerProfileUpdateScreen()),
                );
              },
            ),
          ] else if (role == 'police_officer') ...[
            IconButton(
              icon: const Icon(Icons.account_circle_outlined, color: AppColors.accent, size: 26),
              tooltip: 'Update Profile',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const OfficerProfileUpdateScreen()),
                );
              },
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.history_rounded, color: AppColors.accent),
              tooltip: 'Case History',
              onPressed: () => context.push(AppRoutes.myCases),
            ),
          ],
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: AppColors.accent),
            tooltip: 'Notifications',
            onPressed: () => context.push(AppRoutes.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary),
            tooltip: 'Logout',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.onboarding);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Welcome Hero Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceBlue,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderBlue),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceBlueMuted,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _roleLabel(role).toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Hello, $fullName',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'JusticeNow Secure Legal Assistance & Rights Protection',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderBlue, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.shield_outlined, color: AppColors.primary, size: 26),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // ── Quick Actions / Menu ──
              Text(
                role == 'lawyer'
                    ? 'Lawyer Workspace'
                    : (role == 'police_officer' ? 'Police Workspace' : 'Quick Actions'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 14),

              // ── POLICE DASHBOARD MENU (EXCLUSIVELY: View Cases, Add Time Slot) ──
              if (role == 'police_officer') ...[
                // Part 1: View Cases
                _ActionCard(
                  icon: Icons.folder_shared_rounded,
                  title: 'View Cases',
                  subtitle: 'Pending assignments, To-Do active investigations & completed cases',
                  color: AppColors.accent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OfficerMyCasesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 14),

                // Part 2: Add Time Slot (Duty shift manager)
                _ActionCard(
                  icon: Icons.more_time_rounded,
                  title: 'Add Time Slot',
                  subtitle: 'Duty shift manager — define on-duty hours & investigation availability',
                  color: AppColors.info,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const OfficerManageAvailabilityScreen()),
                    );
                  },
                ),
                const SizedBox(height: 14),
              ] else if (role == 'lawyer') ...[
                // View Cases
                _ActionCard(
                  icon: Icons.folder_shared_rounded,
                  title: 'View Cases',
                  subtitle: 'Pending requests, scheduled cases & completed records',
                  color: AppColors.accent,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CounselCasesScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Set Availability
                _ActionCard(
                  icon: Icons.calendar_month_rounded,
                  title: 'Set Availability',
                  subtitle: 'Define your weekly available time slots for case appointments',
                  color: AppColors.info,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageAvailabilityScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Submit an Ad
                _ActionCard(
                  icon: Icons.campaign_rounded,
                  title: 'Submit an Ad',
                  subtitle: 'Publish promotional legal service advertisements',
                  color: AppColors.success,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SubmitAdScreen()),
                    );
                  },
                ),
                const SizedBox(height: 12),
              ] else ...[
                // ── CITIZEN / STANDARD MENU ──
                // Report Incident
                _ActionCard(
                  icon: Icons.add_circle_outline_rounded,
                  title: 'Report Incident',
                  subtitle: 'Submit a new human rights incident report',
                  color: AppColors.accent,
                  onTap: () => context.push(AppRoutes.reportCase),
                ),
                const SizedBox(height: 12),

                // My Cases
                _ActionCard(
                  icon: Icons.folder_outlined,
                  title: 'My Cases',
                  subtitle: 'View and track your submitted cases',
                  color: AppColors.info,
                  onTap: () => context.go(AppRoutes.myCases),
                ),
                const SizedBox(height: 12),

                // Legal Aid
                _ActionCard(
                  icon: Icons.gavel_rounded,
                  title: 'Legal Aid',
                  subtitle: 'Find verified NGOs and legal practitioners',
                  color: AppColors.success,
                  onTap: () => context.push(AppRoutes.legalAid),
                ),
                const SizedBox(height: 12),
              ],

              // Admin: Portal & Verification
              if (role == 'admin') ...[
                _ActionCard(
                  icon: Icons.admin_panel_settings_rounded,
                  title: 'Admin Dashboard',
                  subtitle: 'Manage verifications, case registry, and hotspot analytics',
                  color: AppColors.accent,
                  onTap: () => context.push(AppRoutes.adminDashboard),
                ),
                const SizedBox(height: 12),
              ],

              // ── CITIZEN ADS ROW SLIDER (Only for citizens) ──
              if (role != 'lawyer' && role != 'police_officer' && role != 'admin') ...[
                const _CitizenAdsRowSlider(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Reusable action card widget
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: color.withValues(alpha: 0.08),
          highlightColor: color.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Center(
                    child: Icon(icon, color: color, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sliding Row Widget displaying lawyer advertisement posts on Citizen Dashboard
class _CitizenAdsRowSlider extends StatefulWidget {
  const _CitizenAdsRowSlider();

  @override
  State<_CitizenAdsRowSlider> createState() => _CitizenAdsRowSliderState();
}

class _CitizenAdsRowSliderState extends State<_CitizenAdsRowSlider> {
  final LegalAidRepository _repo = LegalAidRepository();
  List<dynamic> _ads = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  late final PageController _pageController;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _fetchAds();
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _fetchAds() async {
    try {
      final list = await _repo.getAdvertisements();
      if (mounted) {
        setState(() {
          _ads = list;
          _isLoading = false;
        });
        if (_ads.length > 1) {
          _startAutoSlide();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startAutoSlide() {
    _autoSlideTimer?.cancel();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _ads.length <= 1 || !_pageController.hasClients) return;
      final nextIndex = (_currentIndex + 1) % _ads.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _showFullImageDialog(BuildContext context, String imageUrl, String lawyerName, String details) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.7),
                      child: InteractiveViewer(
                        child: Image.network(
                          AppConstants.resolveImageUrl(imageUrl),
                          fit: BoxFit.contain,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              height: 250,
                              color: Colors.black12,
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.accent),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            height: 250,
                            color: AppColors.surfaceVariant,
                            child: const Center(
                              child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 48),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                          child: const Icon(Icons.gavel_rounded, color: AppColors.accent, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lawyerName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              if (details.isNotEmpty)
                                Text(
                                  details,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: CircleAvatar(
                radius: 18,
                backgroundColor: Colors.black.withOpacity(0.65),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 180,
        margin: const EdgeInsets.only(top: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    if (_ads.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.campaign_rounded, color: AppColors.accent, size: 18),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Lawyer & Legal Notices',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (_ads.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text(
                  '${_currentIndex + 1} / ${_ads.length}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 14),

        // Sliding Row PageView
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _ads.length,
            onPageChanged: (idx) {
              setState(() => _currentIndex = idx);
            },
            itemBuilder: (context, index) {
              final ad = _ads[index] as Map<String, dynamic>;
              final imageUrl = ad['imageUrl']?.toString() ?? '';
              final lawyerName = ad['lawyerName']?.toString() ?? 'Attorney at Law';
              final district = ad['lawyerDistrict']?.toString() ?? '';
              final courtNo = ad['lawyerCourtNumber']?.toString() ?? '';
              final locationInfo = [district, courtNo].where((s) => s.isNotEmpty).join(' • ');

              return GestureDetector(
                onTap: () => _showFullImageDialog(context, imageUrl, lawyerName, locationInfo),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Ad Poster Image
                        Image.network(
                          AppConstants.resolveImageUrl(imageUrl),
                          fit: BoxFit.cover,
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: AppColors.surfaceVariant,
                              child: const Center(
                                child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: AppColors.surfaceVariant,
                            child: const Center(
                              child: Icon(Icons.campaign_outlined, color: AppColors.accent, size: 48),
                            ),
                          ),
                        ),

                        // Bottom Gradient Scrim & Info
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.fromLTRB(14, 28, 14, 12),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.85),
                                ],
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: AppColors.accent,
                                  child: const Icon(Icons.gavel_rounded, color: Colors.white, size: 15),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        lawyerName,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (locationInfo.isNotEmpty)
                                        Text(
                                          locationInfo,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.8),
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'View Post',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Dots Indicator
        if (_ads.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _ads.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentIndex == i ? 18 : 6,
                height: 5,
                decoration: BoxDecoration(
                  color: _currentIndex == i ? AppColors.accent : AppColors.border,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
