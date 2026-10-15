import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/constants/sri_lanka_locations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for Common fields
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // Controllers for Role-specific fields
  final _courtNumberCtrl = TextEditingController();
  final _policeIdCtrl = TextEditingController();
  final _aboutMeCtrl = TextEditingController();

  // Selections
  String _selectedRole = 'citizen'; // 'citizen', 'lawyer', 'police_officer'
  String? _selectedGender = 'Male'; // 'Male', 'Female'
  String? _selectedProvince;
  String? _selectedDistrict;
  String? _selectedLanguage = 'English'; // 'Sinhala', 'Tamil', 'English'

  // Certificate upload
  File? _certificateFile;
  String? _certificateFileName;
  bool _isUploadingFile = false;

  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _nicCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _courtNumberCtrl.dispose();
    _policeIdCtrl.dispose();
    _aboutMeCtrl.dispose();
    super.dispose();
  }

  // ── Certificate Pickers ───────────────────────────────────────
  Future<void> _pickCertificateImage() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null) {
      setState(() {
        _certificateFile = File(picked.path);
        _certificateFileName = picked.name;
      });
    }
  }

  Future<void> _pickCertificatePdf() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (files.isNotEmpty) {
      final first = files.first;
      if (first.path != null && first.path!.isNotEmpty) {
        setState(() {
          _certificateFile = File(first.path!);
          _certificateFileName = first.name;
        });
      }
    }
  }

  void _showCertificatePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Upload Supreme Court Certificate',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error),
                title: const Text('PDF Document', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Upload official certificate PDF', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCertificatePdf();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.accent),
                title: const Text('Photo / Image', style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Select photo from gallery', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickCertificateImage();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Form Submission ───────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedRole == 'lawyer' && _certificateFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload your Supreme Court Certificate (Photo or PDF)'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    String? certificateUrl;

    if (_selectedRole == 'lawyer' && _certificateFile != null) {
      setState(() => _isUploadingFile = true);
      try {
        final repo = ref.read(authRepositoryProvider);
        certificateUrl = await repo.uploadCertificate(_certificateFile!);
      } catch (e) {
        if (!mounted) return;
        setState(() => _isUploadingFile = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload certificate: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      if (!mounted) return;
      setState(() => _isUploadingFile = false);
    }

    final result = await ref.read(authProvider.notifier).register(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      fullName: _nameCtrl.text.trim(),
      role: _selectedRole,
      phone: _phoneCtrl.text.trim(),
      nic: _nicCtrl.text.trim(),
      gender: _selectedGender,
      province: _selectedProvince,
      district: _selectedDistrict,
      policeId: _selectedRole == 'police_officer' ? _policeIdCtrl.text.trim() : null,
      courtNumber: _selectedRole == 'lawyer' ? _courtNumberCtrl.text.trim() : null,
      lawyerId: _selectedRole == 'lawyer' ? _courtNumberCtrl.text.trim() : null,
      certificateUrl: certificateUrl,
      aboutMe: _aboutMeCtrl.text.trim().isNotEmpty ? _aboutMeCtrl.text.trim() : null,
      preferredLanguage: _selectedLanguage,
    );

    if (!mounted) return;

    if (result.success) {
      if (result.isPending) {
        context.go(AppRoutes.registerSuccess, extra: _selectedRole);
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final availableDistricts = SriLankaLocations.getDistrictsForProvince(_selectedProvince);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.go(AppRoutes.login),
        ),
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                Text(
                  'Join JusticeNow',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose your role and complete your registration profile',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 24),

                // ── 1. Top of page: Role Selector ──
                Text(
                  'SELECT YOUR ROLE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.accent,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _RoleOptionCard(
                      label: 'Citizen',
                      icon: Icons.person_rounded,
                      isSelected: _selectedRole == 'citizen',
                      onTap: () => setState(() => _selectedRole = 'citizen'),
                    ),
                    const SizedBox(width: 8),
                    _RoleOptionCard(
                      label: 'Lawyer',
                      icon: Icons.gavel_rounded,
                      isSelected: _selectedRole == 'lawyer',
                      onTap: () => setState(() => _selectedRole = 'lawyer'),
                    ),
                    const SizedBox(width: 8),
                    _RoleOptionCard(
                      label: 'Police Officer',
                      icon: Icons.local_police_rounded,
                      isSelected: _selectedRole == 'police_officer',
                      onTap: () => setState(() => _selectedRole = 'police_officer'),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── 2. Common Fields (Everyone Fills) ──
                Text(
                  'COMMON DETAILS',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 14),

                // Full Name
                TextFormField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Full Name *',
                    prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted),
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Full Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email Address *',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                  ),
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Enter a valid email address' : null,
                ),
                const SizedBox(height: 16),

                // Mobile Number
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number *',
                    hintText: 'e.g. 0771234567',
                    prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textMuted),
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 9 ? 'Enter a valid mobile phone number' : null,
                ),
                const SizedBox(height: 16),

                // NIC
                TextFormField(
                  controller: _nicCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'NIC (National Identity Card) *',
                    hintText: 'e.g. 199512345678 or 951234567V',
                    prefixIcon: Icon(Icons.credit_card_rounded, color: AppColors.textMuted),
                  ),
                  validator: (v) =>
                      v == null || v.trim().length < 9 ? 'Enter a valid NIC number' : null,
                ),
                const SizedBox(height: 16),

                // Gender (Male / Female)
                DropdownButtonFormField<String>(
                  value: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Gender *',
                    prefixIcon: Icon(Icons.people_alt_outlined, color: AppColors.textMuted),
                  ),
                  dropdownColor: AppColors.surface,
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                  ],
                  onChanged: (val) => setState(() => _selectedGender = val),
                  validator: (v) => v == null ? 'Please select gender' : null,
                ),
                const SizedBox(height: 16),

                // Province Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  decoration: const InputDecoration(
                    labelText: 'Province *',
                    prefixIcon: Icon(Icons.map_outlined, color: AppColors.textMuted),
                  ),
                  dropdownColor: AppColors.surface,
                  items: SriLankaLocations.provinces.map((prov) {
                    return DropdownMenuItem(value: prov, child: Text(prov));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedProvince = val;
                      _selectedDistrict = null;
                    });
                  },
                  validator: (v) => v == null ? 'Please select province' : null,
                ),
                const SizedBox(height: 16),

                // District Dropdown (Filters based on Province)
                DropdownButtonFormField<String>(
                  value: _selectedDistrict,
                  decoration: const InputDecoration(
                    labelText: 'District *',
                    prefixIcon: Icon(Icons.location_city_outlined, color: AppColors.textMuted),
                  ),
                  dropdownColor: AppColors.surface,
                  items: availableDistricts.map((dist) {
                    return DropdownMenuItem(value: dist, child: Text(dist));
                  }).toList(),
                  onChanged: _selectedProvince == null
                      ? null
                      : (val) => setState(() => _selectedDistrict = val),
                  validator: (v) => v == null ? 'Please select district' : null,
                ),
                const SizedBox(height: 16),

                // Password
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password *',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.length < 8 ? 'Password must be at least 8 characters' : null,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password *',
                    prefixIcon: const Icon(Icons.lock_reset_rounded, color: AppColors.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: AppColors.textMuted,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirm your password';
                    if (v != _passwordCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // ── 3. Role-Specific Fields ──
                if (_selectedRole == 'lawyer') ...[
                  Text(
                    'LAWYER CREDENTIALS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.accent,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 14),

                  // Court Number
                  TextFormField(
                    controller: _courtNumberCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Court Number / Bar Enrollment No. *',
                      hintText: 'e.g. SC/BAR/2020/1234',
                      prefixIcon: Icon(Icons.account_balance_rounded, color: AppColors.textMuted),
                    ),
                    validator: (v) =>
                        _selectedRole == 'lawyer' && (v == null || v.trim().isEmpty)
                            ? 'Court Number is required'
                            : null,
                  ),
                  const SizedBox(height: 16),

                  // Supreme Court Certificate Upload (Photo / PDF)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _certificateFile != null ? AppColors.surfaceGreen : AppColors.surfaceSubtle,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _certificateFile != null
                            ? AppColors.borderGreen
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceBlueMuted,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              'Supreme Court Certificate *',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Upload photo or PDF copy of your Supreme Court enrollment certificate',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        if (_certificateFile != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.borderGreen),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _certificateFileName ?? 'Certificate Attached',
                                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _certificateFile = null;
                                      _certificateFileName = null;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        OutlinedButton.icon(
                          onPressed: _showCertificatePickerOptions,
                          icon: const Icon(Icons.upload_file_rounded),
                          label: Text(_certificateFile == null ? 'Upload Photo / PDF' : 'Change File'),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: AppColors.surface,
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.borderBlue),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // About Me
                  TextFormField(
                    controller: _aboutMeCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'About Me',
                      hintText: 'Brief summary of your legal expertise and practice areas...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preferred Language
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Preferred Language *',
                      prefixIcon: Icon(Icons.language_rounded, color: AppColors.textMuted),
                    ),
                    dropdownColor: AppColors.surface,
                    items: const [
                      DropdownMenuItem(value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'Sinhala', child: Text('Sinhala')),
                      DropdownMenuItem(value: 'Tamil', child: Text('Tamil')),
                    ],
                    onChanged: (val) => setState(() => _selectedLanguage = val),
                  ),
                  const SizedBox(height: 28),
                ],

                if (_selectedRole == 'police_officer') ...[
                  Text(
                    'POLICE CREDENTIALS',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.accent,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 14),

                  // Police ID
                  TextFormField(
                    controller: _policeIdCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Police Service ID / Badge No. *',
                      hintText: 'e.g. SLPS-48291',
                      prefixIcon: Icon(Icons.local_police_outlined, color: AppColors.textMuted),
                    ),
                    validator: (v) =>
                        _selectedRole == 'police_officer' && (v == null || v.trim().isEmpty)
                            ? 'Police ID is required'
                            : null,
                  ),
                  const SizedBox(height: 16),

                  // About Me
                  TextFormField(
                    controller: _aboutMeCtrl,
                    maxLines: 3,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'About Me',
                      hintText: 'Station, division or departmental role summary...',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Preferred Language
                  DropdownButtonFormField<String>(
                    value: _selectedLanguage,
                    decoration: const InputDecoration(
                      labelText: 'Preferred Language *',
                      prefixIcon: Icon(Icons.language_rounded, color: AppColors.textMuted),
                    ),
                    dropdownColor: AppColors.surface,
                    items: const [
                      DropdownMenuItem(value: 'English', child: Text('English')),
                      DropdownMenuItem(value: 'Sinhala', child: Text('Sinhala')),
                      DropdownMenuItem(value: 'Tamil', child: Text('Tamil')),
                    ],
                    onChanged: (val) => setState(() => _selectedLanguage = val),
                  ),
                  const SizedBox(height: 28),
                ],

                // Error Message if any
                if (authState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      authState.error!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── 4. Bottom: Submit Button ──
                ElevatedButton(
                  onPressed: (authState.isLoading || _isUploadingFile) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: (authState.isLoading || _isUploadingFile)
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_selectedRole == 'citizen' ? 'Create Account' : 'Submit for Verification'),
                ),
                const SizedBox(height: 16),

                // Back to login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already registered? ',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOptionCard({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceBlue : AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.border,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              if (isSelected)
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              else
                const BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.surfaceBlueMuted : AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
