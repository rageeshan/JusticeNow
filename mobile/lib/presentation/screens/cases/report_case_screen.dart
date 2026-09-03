import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/repositories/case_repository.dart';

class ReportCaseScreen extends ConsumerStatefulWidget {
  const ReportCaseScreen({super.key});
  @override
  ConsumerState<ReportCaseScreen> createState() => _ReportCaseScreenState();
}

class _ReportCaseScreenState extends ConsumerState<ReportCaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();

  String? _selectedCategory;
  DateTime? _incidentDate;
  bool _isSubmitting = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await CaseRepository().createCase({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _selectedCategory,
        'incidentDate': _incidentDate?.toIso8601String(),
        'location': {
          'city': _cityCtrl.text.trim(),
          'country': _countryCtrl.text.trim(),
        },
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Case submitted successfully'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Report an Incident')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep < 2) {
              setState(() => _currentStep++);
            } else {
              _submit();
            }
          },
          onStepCancel: () {
            if (_currentStep > 0) setState(() => _currentStep--);
          },
          connectorColor: WidgetStateProperty.all(AppColors.accent),
          steps: [
            // Step 1: Basic Info
            Step(
              title: Text('Incident Details',
                  style: TextStyle(
                      color: _currentStep >= 0 ? AppColors.textPrimary : AppColors.textMuted)),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _titleCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Incident Title *'),
                    validator: (v) => v == null || v.isEmpty ? 'Title is required' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(labelText: 'Category *'),
                    items: AppConstants.caseCategories.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    validator: (v) => v == null ? 'Please select a category' : null,
                  ),
                ],
              ),
            ),

            // Step 2: Description
            Step(
              title: Text('Description',
                  style: TextStyle(
                      color: _currentStep >= 1 ? AppColors.textPrimary : AppColors.textMuted)),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 6,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Describe what happened *',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) =>
                        v == null || v.length < 20 ? 'Please provide more detail (min 20 chars)' : null,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    tileColor: AppColors.surfaceVariant,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    leading: const Icon(Icons.calendar_today_outlined, color: AppColors.accent),
                    title: Text(
                      _incidentDate == null
                          ? 'Select Incident Date *'
                          : '${_incidentDate!.day}/${_incidentDate!.month}/${_incidentDate!.year}',
                      style: TextStyle(
                        color: _incidentDate == null ? AppColors.textMuted : AppColors.textPrimary,
                      ),
                    ),
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: const ColorScheme.dark(primary: AppColors.accent),
                          ),
                          child: child!,
                        ),
                      );
                      if (date != null) setState(() => _incidentDate = date);
                    },
                  ),
                ],
              ),
            ),

            // Step 3: Location
            Step(
              title: Text('Location',
                  style: TextStyle(
                      color: _currentStep >= 2 ? AppColors.textPrimary : AppColors.textMuted)),
              isActive: _currentStep >= 2,
              state: StepState.indexed,
              content: Column(
                children: [
                  TextFormField(
                    controller: _cityCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'City (optional)',
                      prefixIcon: Icon(Icons.location_city_outlined, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _countryCtrl,
                    style: const TextStyle(color: AppColors.textPrimary),
                    decoration: const InputDecoration(
                      labelText: 'Country (optional)',
                      prefixIcon: Icon(Icons.flag_outlined, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.shield_outlined, size: 16, color: AppColors.accent),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Your identity is protected. Location is used only for pattern analysis.',
                            style: TextStyle(color: AppColors.accent, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : details.onStepContinue,
                      child: _isSubmitting && _currentStep == 2
                          ? const SizedBox(
                              height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDark),
                            )
                          : Text(_currentStep == 2 ? 'Submit Report' : 'Continue'),
                    ),
                  ),
                  if (_currentStep > 0) ...[
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
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
