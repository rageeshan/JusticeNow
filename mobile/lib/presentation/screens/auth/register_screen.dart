import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/sri_lanka_locations.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});
  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _policeIdCtrl = TextEditingController();
  final _lawyerIdCtrl = TextEditingController();

  String _selectedRole = 'citizen';
  String? _selectedProvince;
  String? _selectedDistrict;
  bool _obscurePassword = true;

  // Role options matching backend enum
  static const Map<String, String> _roleLabels = {
    'citizen': 'Citizen',
    'police_officer': 'Police Officer',
    'lawyer': 'Lawyer',
    'admin': 'Admin',
  };

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _policeIdCtrl.dispose();
    _lawyerIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final result = await ref.read(authProvider.notifier).register(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      fullName: _nameCtrl.text.trim(),
      role: _selectedRole,
      province: _selectedRole == 'citizen' ? _selectedProvince : null,
      district: _selectedRole == 'citizen' ? _selectedDistrict : null,
      policeId: _selectedRole == 'police_officer' ? _policeIdCtrl.text.trim() : null,
      lawyerId: _selectedRole == 'lawyer' ? _lawyerIdCtrl.text.trim() : null,
    );

    if (!mounted) return;

    if (result.success) {
      if (result.isPending) {
        // Show pending verification dialog for police officer or lawyer
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.hourglass_top_rounded, color: AppColors.warning, size: 28),
                SizedBox(width: 12),
                Text('Pending Verification', style: TextStyle(color: AppColors.textPrimary)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.message ??
                      'Your registration has been placed under pending review. An administrator must verify your account before you can log in.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.warning, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Role: ${_roleLabels[_selectedRole] ?? _selectedRole}\nStatus: Under Admin Review',
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.go(AppRoutes.login);
                },
                child: const Text('Back to Sign In'),
              ),
            ],
          ),
        );
      } else {
        // Direct login for citizen / active accounts
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          onPressed: () => context.go(AppRoutes.onboarding),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Text('Create account', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'Register to track your case history and get updates',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Full Name
                TextFormField(
                  controller: _nameCtrl,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Email
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                  ),
                  validator: (v) =>
                      v == null || !v.contains('@') ? 'Enter a valid email' : null,
                ),
                const SizedBox(height: 16),

                // Role Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  dropdownColor: AppColors.surface,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge_outlined, color: AppColors.textMuted),
                  ),
                  items: _roleLabels.entries.map((e) {
                    return DropdownMenuItem(
                      value: e.key,
                      child: Text(e.value),
                    );
                  }).toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _selectedRole = v;
                        // Reset role-specific selections when switching
                        if (_selectedRole != 'citizen') {
                          _selectedProvince = null;
                          _selectedDistrict = null;
                        }
                      });
                    }
                  },
                  validator: (v) => v == null ? 'Please select a role' : null,
                ),
                const SizedBox(height: 16),

                // ── Notice for Officer & Lawyer verification ──
                if (_selectedRole == 'police_officer' || _selectedRole == 'lawyer') ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Notice: ${_roleLabels[_selectedRole]} accounts require administrator verification and approval before you can sign in.',
                            style: const TextStyle(color: AppColors.warning, fontSize: 12, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Citizen Specific Fields: Province & District ──
                if (_selectedRole == 'citizen') ...[
                  DropdownButtonFormField<String>(
                    value: _selectedProvince,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Province *',
                      prefixIcon: Icon(Icons.map_outlined, color: AppColors.textMuted),
                    ),
                    hint: const Text('Select Province', style: TextStyle(color: AppColors.textMuted)),
                    items: SriLankaLocations.provinces.map((province) {
                      return DropdownMenuItem(
                        value: province,
                        child: Text(province),
                      );
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        _selectedProvince = v;
                        _selectedDistrict = null; // Reset district on province change
                      });
                    },
                    validator: (v) =>
                        _selectedRole == 'citizen' && (v == null || v.isEmpty)
                            ? 'Province is required'
                            : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: _selectedDistrict,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'District *',
                      prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textMuted),
                    ),
                    hint: Text(
                      _selectedProvince == null ? 'Select Province first' : 'Select District',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    items: availableDistricts.map((district) {
                      return DropdownMenuItem(
                        value: district,
                        child: Text(district),
                      );
                    }).toList(),
                    onChanged: _selectedProvince == null
                        ? null
                        : (v) {
                            setState(() => _selectedDistrict = v);
                          },
                    validator: (v) =>
                        _selectedRole == 'citizen' && (v == null || v.isEmpty)
                            ? 'District is required'
                            : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Police Officer Field: Police ID ──
                if (_selectedRole == 'police_officer') ...[
                  TextFormField(
                    controller: _policeIdCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Police ID / Badge Number *',
                      prefixIcon: Icon(Icons.local_police_outlined, color: AppColors.textMuted),
                      hintText: 'e.g. POL-12345',
                    ),
                    validator: (v) =>
                        _selectedRole == 'police_officer' && (v == null || v.trim().isEmpty)
                            ? 'Police ID is required'
                            : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // ── Lawyer Field: Lawyer ID ──
                if (_selectedRole == 'lawyer') ...[
                  TextFormField(
                    controller: _lawyerIdCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Lawyer ID / Bar Registration Number *',
                      prefixIcon: Icon(Icons.gavel_rounded, color: AppColors.textMuted),
                      hintText: 'e.g. BAR-67890',
                    ),
                    validator: (v) =>
                        _selectedRole == 'lawyer' && (v == null || v.trim().isEmpty)
                            ? 'Lawyer ID is required'
                            : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Password
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Password',
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
                      v == null || v.length < 8 ? 'Minimum 8 characters' : null,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    prefixIcon: Icon(Icons.lock_outline_rounded, color: AppColors.textMuted),
                  ),
                  validator: (v) =>
                      v != _passwordCtrl.text ? 'Passwords do not match' : null,
                ),

                // Error banner
                if (authState.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(authState.error!,
                        style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ),
                ],

                const SizedBox(height: 32),

                // Register Button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                        )
                      : const Text('Create Account'),
                ),

                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? ",
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: const Text('Sign In',
                          style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
