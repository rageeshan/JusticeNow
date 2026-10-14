import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class AdminUserDetailScreen extends ConsumerStatefulWidget {
  final String userId;
  final Map<String, dynamic>? initialUser;

  const AdminUserDetailScreen({
    super.key,
    required this.userId,
    this.initialUser,
  });

  @override
  ConsumerState<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

class _AdminUserDetailScreenState extends ConsumerState<AdminUserDetailScreen> {
  Map<String, dynamic>? _user;
  bool _isLoading = false;
  bool _isProcessingAction = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _user = widget.initialUser;
    if (_user == null) {
      _loadUserDetails();
    }
  }

  Future<void> _loadUserDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.getAdminUserDetail(widget.userId);
      if (mounted) {
        setState(() {
          _user = user;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      return DateFormat('MMMM dd, yyyy • hh:mm a').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  String _resolveCertificateUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    // Prepend API base URL
    final base = AppConstants.baseUrl.replaceAll('/api', '');
    return '$base$url';
  }

  void _viewFullSizePhoto(String fullUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.8,
              maxScale: 4.0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  fullUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) {
                    if (progress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (_, __, ___) => Container(
                    padding: const EdgeInsets.all(32),
                    color: AppColors.surface,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image_rounded, color: AppColors.error, size: 48),
                        SizedBox(height: 12),
                        Text('Unable to load full certificate photo', style: TextStyle(color: AppColors.textPrimary)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const CircleAvatar(
                backgroundColor: Colors.black54,
                child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
              ),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveUser() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 26),
            SizedBox(width: 10),
            Text('Approve Account', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: const Text(
          'Are you sure you want to approve this professional account? The user will be immediately granted full system access to handle cases.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm Approval'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessingAction = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateUserApprovalStatus(widget.userId, 'approved');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account successfully approved.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingAction = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _rejectUser() async {
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.cancel_rounded, color: AppColors.error, size: 26),
            SizedBox(width: 10),
            Text('Reject Application', style: TextStyle(color: AppColors.textPrimary)),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please provide the reason for rejection. This reason will be displayed to the applicant:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'e.g. Bar enrollment number does not match submitted certificate...',
                  alignLabelWithHint: true,
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Rejection reason is required' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('Reject Account'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isProcessingAction = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateUserApprovalStatus(
        widget.userId,
        'rejected',
        reason: reasonCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account has been rejected.'),
          backgroundColor: AppColors.error,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessingAction = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Action failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null || _user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Verification Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text(_errorMessage ?? 'User not found', style: const TextStyle(color: AppColors.error)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadUserDetails, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final user = _user!;
    final profile = user['profile'] as Map<String, dynamic>? ?? {};
    final fullName = profile['fullName'] ?? 'N/A';
    final email = user['email'] ?? 'N/A';
    final phone = profile['phone'] ?? 'N/A';
    final nic = profile['nic'] ?? 'N/A';
    final gender = profile['gender'] ?? 'N/A';
    final province = profile['province'] ?? 'N/A';
    final district = profile['district'] ?? 'N/A';
    final role = user['role'] as String?;
    final createdAt = user['createdAt'] as String?;
    final certificateUrl = profile['certificateUrl'] as String?;
    final aboutMe = profile['aboutMe'] as String?;
    final preferredLanguage = profile['preferredLanguage'] as String?;

    final isLawyer = role == 'lawyer';
    final courtNumber = profile['courtNumber'] ?? profile['lawyerId'] ?? 'N/A';
    final policeId = profile['policeId'] ?? 'N/A';

    final resolvedCertUrl = _resolveCertificateUrl(certificateUrl);
    final isPdf = resolvedCertUrl.toLowerCase().endsWith('.pdf');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verification Detail'),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Header Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: const [AppColors.cardShadow],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isLawyer ? AppColors.surfacePurple : AppColors.surfaceBlue,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isLawyer ? AppColors.surfacePurple : AppColors.borderBlue,
                              ),
                            ),
                            child: Icon(
                              isLawyer ? Icons.gavel_rounded : Icons.local_police_rounded,
                              color: isLawyer ? const Color(0xFF7C3AED) : AppColors.primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceAmber,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppColors.borderAmber),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Pending Admin Review',
                                        style: TextStyle(
                                          color: Color(0xFFB45309),
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
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
                    const SizedBox(height: 24),

                    // ── Common Details ──
                    const _SectionHeader(
                      title: 'COMMON DETAILS',
                      icon: Icons.person_outline_rounded,
                      iconColor: AppColors.primary,
                      iconBg: AppColors.surfaceBlue,
                    ),
                    const SizedBox(height: 12),
                    _DetailCard(
                      items: [
                        _DetailItem('Full Name', fullName),
                        _DetailItem('Email Address', email),
                        _DetailItem('Mobile Number', phone),
                        _DetailItem('NIC', nic),
                        _DetailItem('Gender', gender),
                        _DetailItem('Province', province),
                        _DetailItem('District', district),
                        _DetailItem('Date Submitted', _formatDate(createdAt)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── Role Specific Details ──
                    if (isLawyer) ...[
                      const _SectionHeader(
                        title: 'LAWYER CREDENTIALS',
                        icon: Icons.badge_outlined,
                        iconColor: Color(0xFF7C3AED),
                        iconBg: AppColors.surfacePurple,
                      ),
                      const SizedBox(height: 12),
                      _DetailCard(
                        items: [
                          _DetailItem('Court / Bar Number', courtNumber),
                          _DetailItem('Preferred Language', preferredLanguage ?? 'English'),
                          _DetailItem('About Me', (aboutMe != null && aboutMe.isNotEmpty) ? aboutMe : 'None provided'),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Certificate Photo / PDF Section
                      const _SectionHeader(
                        title: 'SUPREME COURT CERTIFICATE',
                        icon: Icons.verified_user_outlined,
                        iconColor: AppColors.success,
                        iconBg: AppColors.surfaceGreen,
                      ),
                      const SizedBox(height: 12),
                      if (certificateUrl == null || certificateUrl.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceAmber,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderAmber),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppColors.warning),
                              SizedBox(width: 10),
                              Text('No certificate file uploaded', style: TextStyle(color: Color(0xFF92400E))),
                            ],
                          ),
                        )
                      else if (isPdf)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceBlue,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.borderBlue),
                            boxShadow: const [AppColors.cardShadow],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceRed,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 24),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Certificate Document (PDF)', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(resolvedCertUrl, style: const TextStyle(color: AppColors.textMuted, fontSize: 11), overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else ...[
                        GestureDetector(
                          onTap: () => _viewFullSizePhoto(resolvedCertUrl),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                              boxShadow: const [AppColors.cardShadow],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Image.network(
                                      resolvedCertUrl,
                                      height: 220,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        height: 180,
                                        color: AppColors.surfaceVariant,
                                        child: const Center(
                                          child: Icon(Icons.broken_image_rounded, color: AppColors.textMuted, size: 40),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.all(10),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.75),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.zoom_in_rounded, color: Colors.white, size: 16),
                                          SizedBox(width: 4),
                                          Text('Tap to view full size', style: TextStyle(color: Colors.white, fontSize: 11)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],

                    if (!isLawyer) ...[
                      const _SectionHeader(
                        title: 'POLICE CREDENTIALS',
                        icon: Icons.local_police_outlined,
                        iconColor: AppColors.primary,
                        iconBg: AppColors.surfaceBlue,
                      ),
                      const SizedBox(height: 12),
                      _DetailCard(
                        items: [
                          _DetailItem('Police ID / Badge Number', policeId),
                          _DetailItem('Preferred Language', preferredLanguage ?? 'English'),
                          _DetailItem('About Me', (aboutMe != null && aboutMe.isNotEmpty) ? aboutMe : 'None provided'),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
            ),

            // ── Bottom Action Buttons: Approve | Reject ──
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: Offset(0, -3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isProcessingAction ? null : _rejectUser,
                      icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                      label: const Text('Reject', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessingAction ? null : _approveUser,
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  final List<_DetailItem> items;
  const _DetailCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (_, i) {
          final item = items[i];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _DetailItem {
  final String label;
  final String value;
  _DetailItem(this.label, this.value);
}
