import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/models/incident_categories.dart';
import '../../../providers/citizen_cases_provider.dart';
import '../../widgets/step_progress_bar.dart';
import '../../widgets/demo_data_banner.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Report Case Screen — 6-step guided incident reporting flow
// ─────────────────────────────────────────────────────────────────────────────

const _stepLabels = [
  'Start',
  'Category',
  'Details',
  'Evidence',
  'Identity',
  'Review',
];

class ReportCaseScreen extends ConsumerStatefulWidget {
  const ReportCaseScreen({super.key});

  @override
  ConsumerState<ReportCaseScreen> createState() => _ReportCaseScreenState();
}

class _ReportCaseScreenState extends ConsumerState<ReportCaseScreen> {
  // Local controllers (kept in sync with provider on change)
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Reset form when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reportFormProvider.notifier).reset();
    });
  }

  bool _canContinue(ReportFormState form) {
    return switch (form.currentStep) {
      1 => true,
      2 => form.isStep2Valid,
      3 => form.isStep3Valid,
      4 => true,
      5 => form.isStep5Valid,
      _ => true,
    };
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(reportFormProvider);
    final notifier = ref.read(reportFormProvider.notifier);

    // ── Confirmation screen (step 7)
    if (form.currentStep == 7 && form.submittedCaseId != null) {
      return _ConfirmationScreen(
        caseId: form.submittedCaseId!,
        onTrackCase: () {
          notifier.reset();
          context.go('/my-cases');
        },
        onReportAnother: () => notifier.reset(),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            _showExitDialog(context, notifier);
          },
        ),
        title: const Text('Report an Incident'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: const DemoDataBanner(),
        ),
      ),
      body: Column(
        children: [
          // ── Progress bar
          if (form.currentStep <= 6)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: StepProgressBar(
                currentStep: form.currentStep,
                totalSteps: 6,
                labels: _stepLabels,
              ),
            ),

          // ── Step content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0.04, 0), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(
                  key: ValueKey(form.currentStep),
                  child: _buildStep(form, notifier),
                ),
              ),
            ),
          ),

          // ── Bottom nav buttons
          if (form.currentStep <= 6) _buildBottomButtons(form, notifier),
        ],
      ),
    );
  }

  Widget _buildStep(ReportFormState form, ReportFormNotifier notifier) {
    return switch (form.currentStep) {
      1 => _Step1Welcome(notifier: notifier),
      2 => _Step2Category(form: form, notifier: notifier),
      3 => _Step3Details(
          form: form,
          notifier: notifier,
          titleCtrl: _titleCtrl,
          descCtrl: _descCtrl,
          locationCtrl: _locationCtrl,
        ),
      4 => _Step4Evidence(form: form, notifier: notifier),
      5 => _Step5Identity(
          form: form,
          notifier: notifier,
          nameCtrl: _nameCtrl,
          emailCtrl: _emailCtrl,
        ),
      6 => _Step6Review(form: form),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _buildBottomButtons(ReportFormState form, ReportFormNotifier notifier) {
    final canContinue = _canContinue(form);
    final isLastStep = form.currentStep == 6;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          if (form.currentStep > 1)
            OutlinedButton(
              onPressed: () => notifier.prevStep(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(90, 48),
              ),
              child: const Text('Back'),
            ),
          if (form.currentStep > 1) const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: canContinue
                  ? () {
                      if (isLastStep) {
                        notifier.submitCase();
                      } else {
                        // Sync text fields to state on advance
                        _syncFields(notifier, form);
                        notifier.nextStep();
                      }
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: form.isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.primaryDark,
                      ),
                    )
                  : Text(
                      isLastStep ? 'Submit Report' : 'Continue',
                      style: const TextStyle(fontSize: 15),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _syncFields(ReportFormNotifier notifier, ReportFormState form) {
    if (_titleCtrl.text.isNotEmpty) notifier.setTitle(_titleCtrl.text);
    if (_descCtrl.text.isNotEmpty) notifier.setDescription(_descCtrl.text);
    if (_locationCtrl.text.isNotEmpty) notifier.setLocation(_locationCtrl.text);
    if (_nameCtrl.text.isNotEmpty) notifier.setContactName(_nameCtrl.text);
    if (_emailCtrl.text.isNotEmpty) notifier.setContactEmail(_emailCtrl.text);
  }

  void _showExitDialog(BuildContext ctx, ReportFormNotifier notifier) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard report?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'Your progress will be lost if you leave now.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep editing',
                style: TextStyle(color: AppColors.accent)),
          ),
          TextButton(
            onPressed: () {
              notifier.reset();
              Navigator.pop(ctx);
              ctx.pop();
            },
            child: const Text('Discard',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Step 1: Welcome / Privacy Introduction
// ─────────────────────────────────────────────────────────────────────────────

class _Step1Welcome extends StatelessWidget {
  final ReportFormNotifier notifier;
  const _Step1Welcome({required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hero icon
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.shield_outlined,
              size: 32, color: AppColors.accent),
        ),
        const SizedBox(height: 20),

        Text('Report an Incident',
            style: Theme.of(context).textTheme.headlineLarge),
        const SizedBox(height: 10),
        const Text(
          'This tool helps you safely document and report a human rights concern. You are in control of what you share.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 15, height: 1.6),
        ),
        const SizedBox(height: 28),

        // Promise cards
        _PromiseCard(
          icon: Icons.lock_outline,
          title: 'Your information is protected',
          body:
              'All data is encrypted. You choose how much to share — including the option to report anonymously.',
        ),
        const SizedBox(height: 12),
        _PromiseCard(
          icon: Icons.visibility_off_outlined,
          title: 'Anonymous reporting is available',
          body:
              'You do not have to provide your name, phone number, or email if you feel unsafe doing so.',
        ),
        const SizedBox(height: 12),
        _PromiseCard(
          icon: Icons.schedule_outlined,
          title: 'Takes about 5–7 minutes',
          body:
              'The process is step-by-step. You can go back at any time before submitting.',
        ),
        const SizedBox(height: 28),

        const PrivacyNoticeCard(
          message:
              'Your report will only be accessible to trained case officers. It will never be shared publicly or with the media without your explicit consent.',
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _PromiseCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _PromiseCard(
      {required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Step 2: Incident Category Selection
// ─────────────────────────────────────────────────────────────────────────────

class _Step2Category extends StatelessWidget {
  final ReportFormState form;
  final ReportFormNotifier notifier;
  const _Step2Category({required this.form, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('What type of incident are you reporting?',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'Select the category that best describes the situation. You can only choose one.',
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Category grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: kIncidentCategories.length,
          itemBuilder: (_, i) {
            final cat = kIncidentCategories[i];
            final isSelected = form.selectedCategory == cat.id;
            return GestureDetector(
              onTap: () => notifier.setCategory(cat.id, cat.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accent.withValues(alpha: 0.12)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : AppColors.divider,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      cat.icon,
                      size: 24,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textSecondary,
                    ),
                    const Spacer(),
                    Text(
                      cat.label,
                      style: TextStyle(
                        color: isSelected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        if (form.selectedCategory.isEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: AppColors.textMuted),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please select a category to continue.',
                    style:
                        TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Step 3: Incident Details
// ─────────────────────────────────────────────────────────────────────────────

class _Step3Details extends StatelessWidget {
  final ReportFormState form;
  final ReportFormNotifier notifier;
  final TextEditingController titleCtrl;
  final TextEditingController descCtrl;
  final TextEditingController locationCtrl;

  const _Step3Details({
    required this.form,
    required this.notifier,
    required this.titleCtrl,
    required this.descCtrl,
    required this.locationCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tell us what happened',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'Use your own words. You do not need to use legal terms. Just describe what you witnessed or experienced.',
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Title
        _FieldLabel('Short title for the incident *'),
        TextFormField(
          controller: titleCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          maxLength: 120,
          decoration: const InputDecoration(
            hintText: 'e.g. "Detained without charges in Kandy"',
            counterStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 20),

        // Description
        _FieldLabel('Describe what happened *'),
        TextFormField(
          controller: descCtrl,
          style: const TextStyle(color: AppColors.textPrimary, height: 1.5),
          maxLines: 6,
          maxLength: 2000,
          decoration: const InputDecoration(
            hintText:
                'Include what happened, when, and any details you remember...',
            alignLabelWithHint: true,
            counterStyle: TextStyle(color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 20),

        // Date
        _FieldLabel('When did this happen? *'),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: form.incidentDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime.now(),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.dark(
                    primary: AppColors.accent,
                    onPrimary: AppColors.primaryDark,
                    surface: AppColors.surface,
                    onSurface: AppColors.textPrimary,
                  ),
                ),
                child: child!,
              ),
            );
            if (date != null) notifier.setIncidentDate(date);
          },
          child: Container(
            height: 54,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: form.incidentDate != null
                    ? AppColors.accent
                    : AppColors.divider,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: form.incidentDate != null
                      ? AppColors.accent
                      : AppColors.textMuted,
                ),
                const SizedBox(width: 12),
                Text(
                  form.incidentDate == null
                      ? 'Select a date'
                      : '${form.incidentDate!.day} / ${form.incidentDate!.month} / ${form.incidentDate!.year}',
                  style: TextStyle(
                    color: form.incidentDate == null
                        ? AppColors.textMuted
                        : AppColors.textPrimary,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Location
        _FieldLabel('Where did this happen? *'),
        TextFormField(
          controller: locationCtrl,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: const InputDecoration(
            hintText: 'e.g. Colombo, Kandy, or a general area',
            prefixIcon: Icon(Icons.location_on_outlined,
                color: AppColors.textMuted, size: 20),
          ),
        ),
        const SizedBox(height: 20),

        const PrivacyNoticeCard(
          message:
              'Location information is used only for pattern analysis and is never shared publicly.',
          icon: Icons.location_off_outlined,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Step 4: Evidence Upload (Mock UI)
// ─────────────────────────────────────────────────────────────────────────────

class _Step4Evidence extends StatelessWidget {
  final ReportFormState form;
  final ReportFormNotifier notifier;
  const _Step4Evidence({required this.form, required this.notifier});

  // Simulates picking a file
  void _simulatePick(BuildContext ctx) {
    final fakeNames = [
      'photo_evidence_01.jpg',
      'video_clip.mp4',
      'document_scan.pdf',
      'screenshot.png',
      'witness_statement.pdf',
    ];
    final used = form.evidenceFileNames.length;
    if (used >= fakeNames.length) return;
    notifier.addFile(fakeNames[used]);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Add evidence (optional)',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'Photos, videos, or documents can strengthen your report. This step is completely optional — you can submit without any files.',
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 20),

        // Upload button
        GestureDetector(
          onTap: form.evidenceFileNames.length < 10
              ? () => _simulatePick(context)
              : null,
          child: Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.divider, width: 1.5,
                  style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 36,
                  color: form.evidenceFileNames.length < 10
                      ? AppColors.accent
                      : AppColors.textMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  form.evidenceFileNames.length < 10
                      ? 'Tap to add a file'
                      : 'Maximum 10 files reached',
                  style: TextStyle(
                    color: form.evidenceFileNames.length < 10
                        ? AppColors.accent
                        : AppColors.textMuted,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'JPG, PNG, MP4, PDF — max 50 MB each',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // File list
        if (form.evidenceFileNames.isNotEmpty) ...[
          Text(
            '${form.evidenceFileNames.length} file(s) added',
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          ...form.evidenceFileNames.asMap().entries.map((e) {
            final i = e.key;
            final name = e.value;
            final isImage = name.endsWith('.jpg') || name.endsWith('.png');
            final isVideo = name.endsWith('.mp4');
            final icon = isImage
                ? Icons.image_outlined
                : isVideo
                    ? Icons.videocam_outlined
                    : Icons.description_outlined;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.divider),
              ),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.accent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13)),
                  ),
                  GestureDetector(
                    onTap: () => notifier.removeFile(i),
                    child: const Icon(Icons.close_rounded,
                        size: 16, color: AppColors.textMuted),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
        ],

        const PrivacyNoticeCard(
          message:
              'All uploaded files are encrypted immediately upon upload and are stored securely. Files are never shared without your consent.',
          icon: Icons.lock_outline,
        ),
        const SizedBox(height: 16),

        // Skip note
        const Center(
          child: Text(
            'You can continue without adding any files.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Step 5: Anonymous vs. Identified
// ─────────────────────────────────────────────────────────────────────────────

class _Step5Identity extends StatelessWidget {
  final ReportFormState form;
  final ReportFormNotifier notifier;
  final TextEditingController nameCtrl;
  final TextEditingController emailCtrl;
  const _Step5Identity({
    required this.form,
    required this.notifier,
    required this.nameCtrl,
    required this.emailCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How would you like to report?',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'You can report without revealing who you are. Read both options and choose what feels right for your situation.',
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),

        // Option: Anonymous
        _IdentityOption(
          isSelected: form.isAnonymous,
          title: 'Report anonymously',
          subtitle:
              'No personal information will be collected. You can still track your case using your Case ID. We cannot contact you with updates.',
          icon: Icons.visibility_off_outlined,
          tag: 'Recommended if you feel at risk',
          tagColor: AppColors.statusInvestigating,
          onTap: () => notifier.setIsAnonymous(true),
        ),
        const SizedBox(height: 12),

        // Option: Identified
        _IdentityOption(
          isSelected: !form.isAnonymous,
          title: 'Provide my contact details',
          subtitle:
              'Case officers can reach out with updates, request clarification, or connect you with legal aid. Your details are never shared publicly.',
          icon: Icons.person_outline,
          tag: 'Allows investigators to contact you',
          tagColor: AppColors.success,
          onTap: () => notifier.setIsAnonymous(false),
        ),

        // Contact fields (only if not anonymous)
        if (!form.isAnonymous) ...[
          const SizedBox(height: 24),
          const PrivacyNoticeCard(
            message:
                'Your contact details are stored securely and only visible to case officers. They are never shared publicly.',
            icon: Icons.security_outlined,
          ),
          const SizedBox(height: 20),
          _FieldLabel('Your name *'),
          TextFormField(
            controller: nameCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Full name',
              prefixIcon: Icon(Icons.person_outline,
                  color: AppColors.textMuted, size: 20),
            ),
          ),
          const SizedBox(height: 16),
          _FieldLabel('Email address (optional)'),
          TextFormField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'you@example.com',
              prefixIcon:
                  Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _IdentityOption extends StatelessWidget {
  final bool isSelected;
  final String title;
  final String subtitle;
  final IconData icon;
  final String tag;
  final Color tagColor;
  final VoidCallback onTap;

  const _IdentityOption({
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.tag,
    required this.tagColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.divider,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Radio
            Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.textMuted,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: AppColors.accent, shape: BoxShape.circle),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon,
                          size: 18,
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: tagColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      tag,
                      style: TextStyle(
                          color: tagColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600),
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

// ─────────────────────────────────────────────────────────────────────────────
//  Step 6: Review & Confirm
// ─────────────────────────────────────────────────────────────────────────────

class _Step6Review extends StatelessWidget {
  final ReportFormState form;
  const _Step6Review({required this.form});

  String _formatDate(DateTime? d) {
    if (d == null) return 'Not provided';
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review your report',
            style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        const Text(
          'Please take a moment to check the information below before submitting. You can go back to make changes.',
          style:
              TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),

        _ReviewSection(
          title: 'Category',
          content: form.categoryLabel,
          icon: Icons.category_outlined,
        ),
        _ReviewSection(
          title: 'Incident Title',
          content: form.title.isEmpty ? 'Not provided' : form.title,
          icon: Icons.title_outlined,
        ),
        _ReviewSection(
          title: 'Description',
          content: form.description.isEmpty
              ? 'Not provided'
              : form.description.length > 180
                  ? '${form.description.substring(0, 180)}...'
                  : form.description,
          icon: Icons.notes_outlined,
        ),
        _ReviewSection(
          title: 'Incident Date',
          content: _formatDate(form.incidentDate),
          icon: Icons.calendar_today_outlined,
        ),
        _ReviewSection(
          title: 'Location',
          content: form.location.isEmpty ? 'Not provided' : form.location,
          icon: Icons.location_on_outlined,
        ),
        _ReviewSection(
          title: 'Evidence Files',
          content: form.evidenceFileNames.isEmpty
              ? 'None attached'
              : '${form.evidenceFileNames.length} file(s) attached',
          icon: Icons.attach_file_outlined,
        ),
        _ReviewSection(
          title: 'Reporting As',
          content: form.isAnonymous
              ? 'Anonymously (no personal details shared)'
              : form.contactName.isEmpty
                  ? 'Identified (name not provided)'
                  : '${form.contactName} (identified)',
          icon: form.isAnonymous
              ? Icons.visibility_off_outlined
              : Icons.person_outline,
        ),

        const SizedBox(height: 24),
        const PrivacyNoticeCard(
          message:
              'By submitting, you confirm that the information provided is accurate to the best of your knowledge. False reports may undermine legitimate cases.',
          icon: Icons.gavel_outlined,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _ReviewSection extends StatelessWidget {
  final String title;
  final String content;
  final IconData icon;
  const _ReviewSection(
      {required this.title, required this.content, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(content,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Confirmation Screen (Step 7)
// ─────────────────────────────────────────────────────────────────────────────

class _ConfirmationScreen extends StatelessWidget {
  final String caseId;
  final VoidCallback onTrackCase;
  final VoidCallback onReportAnother;

  const _ConfirmationScreen({
    required this.caseId,
    required this.onTrackCase,
    required this.onReportAnother,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Success icon
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: AppColors.statusResolved.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  size: 48,
                  color: AppColors.statusResolved,
                ),
              ),
              const SizedBox(height: 24),

              Text('Report Submitted',
                  style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 10),
              const Text(
                'Thank you for your courage in reporting this. Your case has been securely submitted and will be reviewed by a trained officer.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 15, height: 1.6),
              ),
              const SizedBox(height: 36),

              // Case ID card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'YOUR CASE ID',
                      style: TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      caseId,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Save this ID to track your case at any time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // What happens next
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('What happens next?',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    _NextStep(
                        num: '1',
                        text:
                            'A trained case officer will review your report within 5 business days.'),
                    _NextStep(
                        num: '2',
                        text:
                            'Your case will be assigned a status and added to our secure investigation system.'),
                    _NextStep(
                        num: '3',
                        text:
                            'You can track progress anytime using your Case ID in the "Track My Case" section.'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // CTA buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: onTrackCase,
                  icon: const Icon(Icons.track_changes_outlined),
                  label: const Text('Track My Case'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onReportAnother,
                  child: const Text('Report Another Incident'),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  final String num;
  final String text;
  const _NextStep({required this.num, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(num,
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.5)),
          ),
        ],
      ),
    );
  }
}


