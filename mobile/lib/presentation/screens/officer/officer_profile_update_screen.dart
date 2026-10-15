import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/sri_lanka_locations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../providers/auth_provider.dart';

class OfficerProfileUpdateScreen extends ConsumerStatefulWidget {
  const OfficerProfileUpdateScreen({super.key});

  @override
  ConsumerState<OfficerProfileUpdateScreen> createState() => _OfficerProfileUpdateScreenState();
}

class _OfficerProfileUpdateScreenState extends ConsumerState<OfficerProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthRepository _authRepo = AuthRepository();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _policeIdController;
  late TextEditingController _aboutController;

  String? _selectedLanguage;
  String? _selectedProvince;
  String? _selectedDistrict;

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _policeIdController = TextEditingController();
    _aboutController = TextEditingController();

    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _policeIdController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authRepo.getMe();
      final profile = user['profile'] as Map<String, dynamic>? ?? {};

      _nameController.text = profile['fullName']?.toString() ?? user['alias']?.toString() ?? '';
      _phoneController.text = profile['phone']?.toString() ?? '';
      _policeIdController.text = profile['policeId']?.toString() ?? '';
      _aboutController.text = profile['aboutMe']?.toString() ?? '';

      _selectedLanguage = profile['preferredLanguage']?.toString();
      _selectedProvince = profile['province']?.toString();
      _selectedDistrict = profile['district']?.toString();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _authRepo.updateProfile({
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'policeId': _policeIdController.text.trim(),
        'aboutMe': _aboutController.text.trim(),
        if (_selectedLanguage != null) 'preferredLanguage': _selectedLanguage,
        if (_selectedProvince != null) 'province': _selectedProvince,
        if (_selectedDistrict != null) 'district': _selectedDistrict,
      });

      // Refresh auth state
      ref.read(authProvider.notifier).refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Officer profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Confirm Logout', style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('Are you sure you want to log out of the Officer portal?',
            style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Officer Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final districtList = SriLankaLocations.getDistrictsForProvince(_selectedProvince);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Update Profile'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Log Out',
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header badge
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accentLight,
                          border: Border.all(color: AppColors.accent, width: 2),
                        ),
                        child: const Icon(Icons.shield_rounded, color: AppColors.primary, size: 40),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Police Officer Credentials',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Manage your department contact & investigation details',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name
                const Text('Officer Full Name *', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Insp. Kamal Perera',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Full name is required' : null,
                ),
                const SizedBox(height: 16),

                // Mobile Phone
                const Text('Mobile Number *', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'e.g. 0771234567',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 16),

                // Police Badge / ID
                const Text('Police ID / Badge Number *', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _policeIdController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. PO-89211',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Police ID is required' : null,
                ),
                const SizedBox(height: 16),

                // Province Dropdown
                const Text('Province *', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedProvince,
                  decoration: const InputDecoration(
                    hintText: 'Select Province',
                    prefixIcon: Icon(Icons.map_outlined),
                  ),
                  items: SriLankaLocations.provinces.map((prov) {
                    return DropdownMenuItem(value: prov, child: Text(prov));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedProvince = val;
                      _selectedDistrict = null;
                    });
                  },
                  validator: (v) => v == null ? 'Please select a province' : null,
                ),
                const SizedBox(height: 16),

                // District Dropdown
                const Text('District / Station Jurisdiction *', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDistrict,
                  decoration: const InputDecoration(
                    hintText: 'Select District',
                    prefixIcon: Icon(Icons.location_city_outlined),
                  ),
                  items: districtList.map((dist) {
                    return DropdownMenuItem(value: dist, child: Text(dist));
                  }).toList(),
                  onChanged: (val) {
                    setState(() => _selectedDistrict = val);
                  },
                  validator: (v) => v == null ? 'Please select a district' : null,
                ),
                const SizedBox(height: 16),

                // Preferred Language
                const Text('Preferred Language', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  decoration: const InputDecoration(
                    hintText: 'Select Language',
                    prefixIcon: Icon(Icons.translate_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'English', child: Text('English')),
                    DropdownMenuItem(value: 'Sinhala', child: Text('Sinhala')),
                    DropdownMenuItem(value: 'Tamil', child: Text('Tamil')),
                  ],
                  onChanged: (val) => setState(() => _selectedLanguage = val),
                ),
                const SizedBox(height: 16),

                // About / Department Notes
                const Text('Department / Station Details', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _aboutController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Criminal Investigation Department - Colombo Central Station',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 28),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text(
                            'Save Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
