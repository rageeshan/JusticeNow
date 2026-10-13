import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/case_model.dart';
import 'officer_cases_provider.dart' show caseRepositoryProvider;

// ─────────────────────────────────────────────────────────────────────────────
//  Citizen Cases Provider — live MongoDB database connection
// ─────────────────────────────────────────────────────────────────────────────

/// Returns all cases from MongoDB API
final citizenCasesProvider = FutureProvider<List<CaseModel>>((ref) async {
  final repo = ref.watch(caseRepositoryProvider);
  try {
    final res = await repo.getMyCases(page: 1, limit: 50);
    final rawList = res['cases'] as List?;
    if (rawList != null && rawList.isNotEmpty) {
      return rawList
          .map((e) => CaseModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
  } catch (_) {}

  try {
    final res = await repo.getCases(page: 1, limit: 50);
    final rawList = res['cases'] as List?;
    if (rawList != null && rawList.isNotEmpty) {
      return rawList
          .map((e) => CaseModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
  } catch (_) {}

  return [];
});

/// Returns a single case by ID or Reference Number from MongoDB
final caseDetailProvider =
    FutureProvider.family<CaseModel?, String>((ref, id) async {
  final repo = ref.watch(caseRepositoryProvider);
  try {
    if (id.startsWith('JN-')) {
      final res = await repo.trackByReferenceNumber(id);
      return CaseModel.fromJson(res);
    }
    final res = await repo.getCaseById(id);
    return CaseModel.fromJson(res);
  } catch (_) {}

  try {
    final allCases = await ref.watch(citizenCasesProvider.future);
    return allCases.firstWhere(
      (c) => c.id.toLowerCase() == id.toLowerCase(),
    );
  } catch (_) {
    return null;
  }
});

// ─────────────────────────────────────────────────────────────────────────────
//  Report Form State
// ─────────────────────────────────────────────────────────────────────────────

class ReportFormState {
  final int currentStep;
  final String selectedCategory;
  final String categoryLabel;
  final String title;
  final String description;
  final DateTime? incidentDate;
  final String location;
  final String locationDetail;
  final List<String> evidenceFileNames; // mock — just file names
  final bool isAnonymous;
  final String contactName;
  final String contactEmail;
  final bool isSubmitting;
  final String? submittedCaseId;

  const ReportFormState({
    this.currentStep = 1,
    this.selectedCategory = '',
    this.categoryLabel = '',
    this.title = '',
    this.description = '',
    this.incidentDate,
    this.location = '',
    this.locationDetail = '',
    this.evidenceFileNames = const [],
    this.isAnonymous = false,
    this.contactName = '',
    this.contactEmail = '',
    this.isSubmitting = false,
    this.submittedCaseId,
  });

  ReportFormState copyWith({
    int? currentStep,
    String? selectedCategory,
    String? categoryLabel,
    String? title,
    String? description,
    DateTime? incidentDate,
    String? location,
    String? locationDetail,
    List<String>? evidenceFileNames,
    bool? isAnonymous,
    String? contactName,
    String? contactEmail,
    bool? isSubmitting,
    String? submittedCaseId,
  }) {
    return ReportFormState(
      currentStep: currentStep ?? this.currentStep,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      title: title ?? this.title,
      description: description ?? this.description,
      incidentDate: incidentDate ?? this.incidentDate,
      location: location ?? this.location,
      locationDetail: locationDetail ?? this.locationDetail,
      evidenceFileNames: evidenceFileNames ?? this.evidenceFileNames,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      contactName: contactName ?? this.contactName,
      contactEmail: contactEmail ?? this.contactEmail,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      submittedCaseId: submittedCaseId ?? this.submittedCaseId,
    );
  }

  bool get isStep2Valid => selectedCategory.isNotEmpty;

  bool get isStep3Valid =>
      title.trim().length >= 5 &&
      description.trim().length >= 10 &&
      incidentDate != null &&
      location.trim().isNotEmpty;

  bool get isStep5Valid => isAnonymous || contactName.trim().isNotEmpty;
}

class ReportFormNotifier extends StateNotifier<ReportFormState> {
  ReportFormNotifier() : super(const ReportFormState());

  void nextStep() {
    if (state.currentStep < 6) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void prevStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void goToStep(int step) => state = state.copyWith(currentStep: step);

  void setCategory(String id, String label) =>
      state = state.copyWith(selectedCategory: id, categoryLabel: label);

  void setTitle(String v) => state = state.copyWith(title: v);
  void setDescription(String v) => state = state.copyWith(description: v);
  void setIncidentDate(DateTime d) => state = state.copyWith(incidentDate: d);
  void setLocation(String v) => state = state.copyWith(location: v);
  void setLocationDetail(String v) => state = state.copyWith(locationDetail: v);
  void setIsAnonymous(bool v) => state = state.copyWith(isAnonymous: v);
  void setContactName(String v) => state = state.copyWith(contactName: v);
  void setContactEmail(String v) => state = state.copyWith(contactEmail: v);

  void addFile(String name) {
    if (state.evidenceFileNames.length >= 10) return;
    state = state.copyWith(
        evidenceFileNames: [...state.evidenceFileNames, name]);
  }

  void removeFile(int index) {
    final updated = List<String>.from(state.evidenceFileNames)..removeAt(index);
    state = state.copyWith(evidenceFileNames: updated);
  }

  Future<void> submitCase() async {
    state = state.copyWith(isSubmitting: true);
    await Future.delayed(const Duration(milliseconds: 1800));
    final year = DateTime.now().year;
    final num = 1000 + DateTime.now().millisecond % 9000;
    final id = 'JN-$year-$num';
    state = state.copyWith(
      isSubmitting: false,
      submittedCaseId: id,
      currentStep: 7,
    );
  }

  void reset() => state = const ReportFormState();
}

final reportFormProvider =
    StateNotifierProvider<ReportFormNotifier, ReportFormState>(
  (ref) => ReportFormNotifier(),
);
