import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
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

  // Evidence
  final List<File> _evidenceFiles = [];
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    super.dispose();
  }

  // ── Evidence pickers ──────────────────────────────────────────────────────

  Future<void> _pickFromCamera() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _evidenceFiles.add(File(picked.path)));
  }

  Future<void> _pickFromGallery() async {
    final picked = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      setState(() => _evidenceFiles.addAll(picked.map((x) => File(x.path))));
    }
  }

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'mp4', 'mov', 'avi', 'webm', 'mp3', 'wav', 'doc', 'docx', 'txt'],
    );
    if (files != null) {
      setState(() {
        for (final f in files) {
          if (f.path?.isNotEmpty == true) _evidenceFiles.add(File(f.path!));
        }
      });
    }
  }

  void _removeEvidence(int index) => setState(() => _evidenceFiles.removeAt(index));

  IconData _fileIcon(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext)) return Icons.image_outlined;
    if (['mp4', 'mov', 'avi', 'webm'].contains(ext)) return Icons.videocam_outlined;
    if (['mp3', 'wav', 'ogg', 'aac'].contains(ext)) return Icons.audiotrack_outlined;
    if (ext == 'pdf') return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
  }

  bool _isImage(File file) {
    final ext = file.path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'].contains(ext);
  }

  String _shortName(File file) {
    final name = file.path.split('/').last;
    return name.length > 28 ? '${name.substring(0, 25)}...' : name;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final caseData = await CaseRepository().createCase({
        'title': _titleCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'category': _selectedCategory,
        'incidentDate': (_incidentDate ?? DateTime.now()).toIso8601String(),
        'location': {
          'city': _cityCtrl.text.trim(),
          'country': _countryCtrl.text.trim(),
        },
      });

      // Upload evidence files (if any)
      final caseId = caseData['_id'] as String?;
      if (caseId != null && _evidenceFiles.isNotEmpty) {
        await CaseRepository().uploadEvidence(
          caseId,
          _evidenceFiles.map((f) => f.path).toList(),
        );
      }

      if (mounted) {
        final referenceNumber = caseData['referenceNumber'] ?? 'N/A';

        // Show success dialog with case reference
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                SizedBox(width: 12),
                Text('Case Submitted', style: TextStyle(color: AppColors.textPrimary)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _evidenceFiles.isNotEmpty
                      ? 'Your report and ${_evidenceFiles.length} evidence file(s) were submitted.'
                      : 'Your incident report has been submitted successfully.',
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Case Reference',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        referenceNumber.toString(),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Save this reference number to track your case.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  context.pop();
                },
                child: const Text('Done'),
              ),
            ],
          ),
        );
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
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: const Text('Report an Incident')),
      body: Form(
        key: _formKey,
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            FocusManager.instance.primaryFocus?.unfocus();
            debugPrint('onStepContinue called, currentStep=$_currentStep');
            
            // Validate current step before advancing
            if (_currentStep == 0) {
              // Step 1: Validate title and category
              if (_titleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter an incident title'), backgroundColor: Colors.red),
                );
                return;
              }
              if (_selectedCategory == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a category'), backgroundColor: Colors.red),
                );
                return;
              }
            } else if (_currentStep == 1) {
              // Step 2: Validate description and date
              if (_descCtrl.text.trim().length < 20) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide more detail (min 20 chars)'), backgroundColor: Colors.red),
                );
                return;
              }
              if (_incidentDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select an incident date'), backgroundColor: Colors.red),
                );
                return;
              }
            }
            
            if (_currentStep < 3) {
              setState(() => _currentStep++);
            } else {
              _submit();
            }
          },
          onStepCancel: () {
            FocusManager.instance.primaryFocus?.unfocus();
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
                    initialValue: _selectedCategory,
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
                    textInputAction: TextInputAction.done,
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

            // ── Step 3: Location ──────────────────────────────────────
            Step(
              title: Text('Location',
                  style: TextStyle(
                      color: _currentStep >= 2 ? AppColors.textPrimary : AppColors.textMuted)),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ? StepState.complete : StepState.indexed,
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
                    child: const Row(
                      children: [
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

            // ── Step 4: Evidence ──────────────────────────────────────
            Step(
              title: Text('Evidence',
                  style: TextStyle(
                      color: _currentStep >= 3 ? AppColors.textPrimary : AppColors.textMuted)),
              isActive: _currentStep >= 3,
              state: StepState.indexed,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Upload supporting evidence (optional)',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Images, videos, audio, PDFs — up to 10 files, 50 MB each.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  // Picker buttons
                  Row(
                    children: [
                      _EvidencePickButton(
                        icon: Icons.camera_alt_outlined,
                        label: 'Camera',
                        onTap: _pickFromCamera,
                      ),
                      const SizedBox(width: 10),
                      _EvidencePickButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Gallery',
                        onTap: _pickFromGallery,
                      ),
                      const SizedBox(width: 10),
                      _EvidencePickButton(
                        icon: Icons.attach_file_rounded,
                        label: 'Files',
                        onTap: _pickFile,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // File list or empty state
                  if (_evidenceFiles.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppColors.textMuted.withValues(alpha: 0.2)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.cloud_upload_outlined,
                              size: 36, color: AppColors.textMuted),
                          SizedBox(height: 8),
                          Text('No files selected',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 13)),
                          SizedBox(height: 2),
                          Text('Tap a button above to add evidence',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _evidenceFiles.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final file = _evidenceFiles[i];
                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.2)),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            leading: _isImage(file)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: Image.file(file,
                                        width: 44,
                                        height: 44,
                                        fit: BoxFit.cover),
                                  )
                                : Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(_fileIcon(file),
                                        color: AppColors.accent, size: 22),
                                  ),
                            title: Text(
                              _shortName(file),
                              style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                            subtitle: FutureBuilder<int>(
                              future: file.length(),
                              builder: (ctx, snap) {
                                if (!snap.hasData) return const SizedBox.shrink();
                                final kb = snap.data! / 1024;
                                final label = kb > 1024
                                    ? '${(kb / 1024).toStringAsFixed(1)} MB'
                                    : '${kb.toStringAsFixed(0)} KB';
                                return Text(label,
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11));
                              },
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: AppColors.textMuted, size: 18),
                              onPressed: () => _removeEvidence(i),
                              tooltip: 'Remove',
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_outline_rounded,
                            size: 14, color: AppColors.accent),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'All evidence is encrypted and stored securely.',
                            style: TextStyle(
                                color: AppColors.accent, fontSize: 11),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          controlsBuilder: (BuildContext context, ControlsDetails details) {
            return Container(
              margin: const EdgeInsets.only(top: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : details.onStepContinue,
                      child: _isSubmitting && _currentStep == 3
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: AppColors.primaryDark),
                            )
                          : Text(_currentStep == 3 ? 'Submit Report' : 'Continue'),
                    ),
                  ),
                  if (_currentStep > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Back'),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Evidence pick button ─────────────────────────────────────────────────────

class _EvidencePickButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _EvidencePickButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.accent, size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
