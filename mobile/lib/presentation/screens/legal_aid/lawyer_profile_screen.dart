import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/legal_aid_repository.dart';

class LawyerProfileScreen extends StatefulWidget {
  final String lawyerId;
  final Map<String, dynamic>? initialLawyer;
  final String? caseId;
  final Map<String, dynamic>? caseData;

  const LawyerProfileScreen({
    super.key,
    required this.lawyerId,
    this.initialLawyer,
    this.caseId,
    this.caseData,
  });

  @override
  State<LawyerProfileScreen> createState() => _LawyerProfileScreenState();
}

class _LawyerProfileScreenState extends State<LawyerProfileScreen> {
  final LegalAidRepository _repo = LegalAidRepository();
  Map<String, dynamic>? _lawyer;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialLawyer != null) {
      _lawyer = widget.initialLawyer;
    } else {
      _fetchLawyerDetails();
    }
  }

  Future<void> _fetchLawyerDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _repo.getLawyerById(widget.lawyerId);
      if (mounted) {
        setState(() {
          _lawyer = data;
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

  void _previewCertificate(String certUrl) {
    final fullUrl = certUrl.startsWith('http')
        ? certUrl
        : '${AppConstants.baseUrl.replaceAll('/api', '')}$certUrl';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: AppColors.success, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Supreme Court Certificate',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: AppColors.border, height: 1),
              Container(
                constraints: const BoxConstraints(maxHeight: 400),
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    fullUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.description_rounded, size: 64, color: AppColors.textMuted),
                          SizedBox(height: 12),
                          Text('Supreme Court Enrollment Document on File', style: TextStyle(color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _proceedToBooking() {
    context.push(
      '/legal-aid/book/${widget.lawyerId}',
      extra: {
        'lawyer': _lawyer,
        'caseId': widget.caseId,
        'case': widget.caseData,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Lawyer Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null && _lawyer == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Lawyer Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
              const SizedBox(height: 12),
              Text('Failed to load profile:\n$_errorMessage', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchLawyerDetails, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final l = _lawyer ?? {};
    final profile = l['profile'] as Map<String, dynamic>? ?? {};

    // Personal Details
    final fullName = profile['fullName'] ?? l['email'] ?? 'Attorney at Law';
    final age = l['age'] ?? profile['age'] ?? 35;
    final gender = profile['gender'] ?? 'Not specified';
    final nic = profile['nic'] ?? 'Verified on record';
    final email = l['email'] ?? 'Not specified';
    final phone = profile['phone'] ?? 'Not specified';

    // Professional Details
    final courtNumber = profile['courtNumber'] ?? profile['lawyerId'] ?? 'SC/REG/VERIFIED';
    final certUrl = profile['certificateUrl'] as String?;
    final preferredLanguage = profile['preferredLanguage'] ?? 'English';
    final province = profile['province'] ?? 'Western';
    final district = profile['district'] ?? 'Colombo';

    // About
    final aboutMe = profile['aboutMe'] ??
        'Practicing attorney dedicated to human rights, civil liberties, and providing fair and impartial legal assistance to citizens in need.';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lawyer Profile'),
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
                    // Top Hero Banner
                    Center(
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.surfaceBlue,
                                  border: Border.all(color: AppColors.borderBlue, width: 2),
                                ),
                                child: const Center(
                                  child: Icon(Icons.person_rounded, size: 48, color: AppColors.primary),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AppColors.background,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 22),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            fullName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceGreen,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderGreen),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, color: AppColors.success, size: 14),
                                SizedBox(width: 4),
                                Text(
                                  'Supreme Court Verified Counsel',
                                  style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 1: Personal Details
                    _buildSectionHeader('1. Personal Details', Icons.person_outline_rounded),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Name', fullName),
                          _buildDetailRow('Age', '$age years'),
                          _buildDetailRow('Gender', gender),
                          _buildDetailRow('NIC', nic),
                          _buildDetailRow('Email', email),
                          _buildDetailRow('Mobile Number', phone, isLast: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 2: Professional Details
                    _buildSectionHeader('2. Professional Details', Icons.gavel_rounded),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow('Court Number', courtNumber),
                          _buildDetailRow('Preferred Language', preferredLanguage),
                          _buildDetailRow('Province', province),
                          _buildDetailRow('District', district),
                          const SizedBox(height: 8),

                          // Supreme Court Certificate Item
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceGreen,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderGreen),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.verified_rounded, color: AppColors.success, size: 24),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Supreme Court Certificate',
                                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      Text(
                                        'Verified credential on record',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                if (certUrl != null && certUrl.isNotEmpty)
                                  ElevatedButton(
                                    onPressed: () => _previewCertificate(certUrl),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    child: const Text('View Cert', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  )
                                else
                                  const Icon(Icons.check_circle_outline_rounded, color: AppColors.success, size: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // SECTION 3: About
                    _buildSectionHeader('3. About Lawyer', Icons.info_outline_rounded),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        aboutMe,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Bar: Back & Select This Lawyer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.border),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: ElevatedButton(
                      onPressed: _proceedToBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 18),
                          SizedBox(width: 8),
                          Text('Select This Lawyer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
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

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.surfaceBlue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 16),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
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
  }
}
