import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class AdminVerificationsScreen extends ConsumerStatefulWidget {
  const AdminVerificationsScreen({super.key});

  @override
  ConsumerState<AdminVerificationsScreen> createState() => _AdminVerificationsScreenState();
}

class _AdminVerificationsScreenState extends ConsumerState<AdminVerificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _users = [];
  String? _errorMessage;

  final List<String> _tabs = ['pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _fetchUsers();
      }
    });
    _fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final currentStatus = _tabs[_tabController.index];

    try {
      final repo = ref.read(authRepositoryProvider);
      final users = await repo.getAdminUsers(approvalStatus: currentStatus);
      if (mounted) {
        setState(() {
          _users = users;
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

  Future<void> _updateStatus(String userId, String newStatus, String userName) async {
    final isApprove = newStatus == 'approved';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isApprove ? 'Approve Account' : 'Reject Account',
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          isApprove
              ? 'Are you sure you want to approve $userName? They will be granted full access to the platform.'
              : 'Are you sure you want to reject $userName? They will not be able to log in.',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isApprove ? AppColors.success : AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(isApprove ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.updateUserApprovalStatus(userId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account successfully ${isApprove ? "approved" : "rejected"}.'),
            backgroundColor: isApprove ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _fetchUsers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update status: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatRole(String? role) {
    switch (role) {
      case 'police_officer':
        return 'Police Officer';
      case 'lawyer':
        return 'Lawyer';
      case 'citizen':
        return 'Citizen';
      case 'admin':
        return 'Admin';
      default:
        return role ?? 'Unknown';
    }
  }

  Color _roleColor(String? role) {
    switch (role) {
      case 'police_officer':
        return AppColors.info;
      case 'lawyer':
        return AppColors.accent;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Account Verifications'),
        backgroundColor: AppColors.primaryDark,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Rejected'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.error),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchUsers,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _users.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 64,
                            color: AppColors.textMuted.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No ${_tabs[_tabController.index]} accounts found',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchUsers,
                      color: AppColors.accent,
                      backgroundColor: AppColors.surface,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final user = _users[index] as Map<String, dynamic>;
                          final profile = (user['profile'] as Map<String, dynamic>?) ?? {};
                          final role = user['role'] as String?;
                          final name = profile['fullName'] ?? 'Unnamed User';
                          final email = user['email'] ?? 'No email';
                          final policeId = profile['policeId'] as String?;
                          final lawyerId = profile['lawyerId'] as String?;
                          final province = profile['province'] as String?;
                          final district = profile['district'] as String?;
                          final userId = user['_id'] as String;
                          final status = user['approvalStatus'] as String? ?? 'pending';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header: Name + Role Badge
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        name,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _roleColor(role).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: _roleColor(role).withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        _formatRole(role),
                                        style: TextStyle(
                                          color: _roleColor(role),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  email,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                                const SizedBox(height: 12),
                                const Divider(color: AppColors.divider, height: 1),
                                const SizedBox(height: 12),

                                // Role Credentials
                                if (policeId != null && policeId.isNotEmpty) ...[
                                  _DetailRow(
                                    icon: Icons.local_police_outlined,
                                    label: 'Police ID',
                                    value: policeId,
                                    highlight: true,
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                if (lawyerId != null && lawyerId.isNotEmpty) ...[
                                  _DetailRow(
                                    icon: Icons.gavel_rounded,
                                    label: 'Lawyer ID',
                                    value: lawyerId,
                                    highlight: true,
                                  ),
                                  const SizedBox(height: 6),
                                ],
                                if (province != null && province.isNotEmpty) ...[
                                  _DetailRow(
                                    icon: Icons.map_outlined,
                                    label: 'Location',
                                    value: district != null && district.isNotEmpty
                                        ? '$district, $province'
                                        : province,
                                    highlight: false,
                                  ),
                                  const SizedBox(height: 6),
                                ],

                                // Actions (Approve / Reject) for Pending
                                if (status == 'pending') ...[
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppColors.error,
                                            side: const BorderSide(color: AppColors.error),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          icon: const Icon(Icons.close_rounded, size: 18),
                                          label: const Text('Reject'),
                                          onPressed: () => _updateStatus(userId, 'rejected', name),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.success,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          icon: const Icon(Icons.check_rounded, size: 18),
                                          label: const Text('Approve'),
                                          onPressed: () => _updateStatus(userId, 'approved', name),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: highlight ? AppColors.accent : AppColors.textMuted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppColors.accent : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: highlight ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
