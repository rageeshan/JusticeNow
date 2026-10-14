import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/sri_lanka_locations.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../providers/auth_provider.dart';

class LawyerProfileUpdateScreen extends ConsumerStatefulWidget {
  const LawyerProfileUpdateScreen({super.key});

  @override
  ConsumerState<LawyerProfileUpdateScreen> createState() => _LawyerProfileUpdateScreenState();
}

class _LawyerProfileUpdateScreenState extends ConsumerState<LawyerProfileUpdateScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthRepository _authRepo = AuthRepository();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _courtNumController;
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
    _courtNumController = TextEditingController();
    _aboutController = TextEditingController();

    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _courtNumController.dispose();
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
      _courtNumController.text = profile['courtNumber']?.toString() ?? profile['lawyerId']?.toString() ?? '';
      _aboutController.text = profile['aboutMe']?.toString() ?? '';

      final lang = profile['preferredLanguage']?.toString();
      _selectedLanguage = (lang != null && ['Sinhala', 'Tamil', 'English'].contains(lang)) ? lang : 'English';

      final prov = profile['province']?.toString();
      _selectedProvince = (prov != null && SriLankaLocations.provinces.contains(prov)) ? prov : SriLankaLocations.provinces.first;

      final dist = profile['district']?.toString();
      final validDistricts = SriLankaLocations.getDistrictsForProvince(_selectedProvince);
      _selectedDistrict = (dist != null && validDistricts.contains(dist)) ? dist : (validDistricts.isNotEmpty ? validDistricts.first : null);
    } catch (_) {
      // Fallback to provider state
      final authState = ref.read(authProvider);
      final user = authState.user;
      final profile = user?['profile'] as Map<String, dynamic>? ?? {};
      _nameController.text = profile['fullName']?.toString() ?? user?['alias']?.toString() ?? '';
      _phoneController.text = profile['phone']?.toString() ?? '';
      _courtNumController.text = profile['courtNumber']?.toString() ?? '';
      _aboutController.text = profile['aboutMe']?.toString() ?? '';
      _selectedLanguage = 'English';
      _selectedProvince = SriLankaLocations.provinces.first;
      _selectedDistrict = SriLankaLocations.getDistrictsForProvince(_selectedProvince).first;
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final updatedUser = await _authRepo.updateProfile({
        'fullName': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'courtNumber': _courtNumController.text.trim(),
        'aboutMe': _aboutController.text.trim(),
        'preferredLanguage': _selectedLanguage,
        'province': _selectedProvince,
        'district': _selectedDistrict,
      });

      // Update provider
      ref.read(authProvider.notifier).setUser(updatedUser);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final districts = SriLankaLocations.getDistrictsForProvince(_selectedProvince);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Update Profile'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar & Title Header
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 42,
                              backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                              child: const Icon(Icons.person_rounded, size: 48, color: AppColors.accent),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Counsel Profile Details',
                              style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Keep your contact and professional information up to date',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Full Name
                      const Text('Full Name *', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.accent, size: 20),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your full name' : null,
                      ),
                      const SizedBox(height: 18),

                      // Court Number / Bar Roll ID
                      const Text('Court Number / SC Bar Roll ID', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _courtNumController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.gavel_rounded, color: AppColors.accent, size: 20),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Mobile Phone
                      const Text('Mobile Number *', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.accent, size: 20),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your phone number' : null,
                      ),
                      const SizedBox(height: 18),

                      // Preferred Language
                      const Text('Preferred Language', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedLanguage,
                        dropdownColor: AppColors.surface,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.language_rounded, color: AppColors.accent, size: 20),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        ),
                        items: ['Sinhala', 'Tamil', 'English']
                            .map((l) => DropdownMenuItem(value: l, child: Text(l, style: const TextStyle(color: AppColors.textPrimary))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedLanguage = val);
                        },
                      ),
                      const SizedBox(height: 18),

                      // Location: Province
                      const Text('Province', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedProvince,
                        dropdownColor: AppColors.surface,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.map_outlined, color: AppColors.accent, size: 20),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        ),
                        items: SriLankaLocations.provinces
                            .map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(color: AppColors.textPrimary))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedProvince = val;
                              final newDistricts = SriLankaLocations.getDistrictsForProvince(val);
                              _selectedDistrict = newDistricts.isNotEmpty ? newDistricts.first : null;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 18),

                      // Location: District
                      const Text('District', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _selectedDistrict,
                        dropdownColor: AppColors.surface,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.accent, size: 20),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        ),
                        items: districts
                            .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(color: AppColors.textPrimary))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedDistrict = val);
                        },
                      ),
                      const SizedBox(height: 18),

                      // About Me / Bio
                      const Text('Professional Bio / About Me', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _aboutController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'Brief introduction, practice areas, courts of practice...',
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveProfile,
                          icon: _isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark))
                              : const Icon(Icons.check_circle_rounded),
                          label: Text(
                            _isSaving ? 'Saving Changes...' : 'Save Profile Changes',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            foregroundColor: AppColors.primaryDark,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
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
