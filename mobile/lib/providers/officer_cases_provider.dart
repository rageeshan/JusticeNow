import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/evidence_request_model.dart';
import '../data/repositories/case_repository.dart';

final caseRepositoryProvider = Provider<CaseRepository>((ref) {
  return CaseRepository();
});

class OfficerCasesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  final CaseRepository _repo;
  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  OfficerCasesNotifier(this._repo) : super(const []) {
    // Initial sync from backend MongoDB API
    fetchCases();
  }

  Map<String, dynamic>? getById(String id) {
    try {
      return state.firstWhere(
        (c) => c['_id'] == id || c['id'] == id || c['referenceNumber'] == id,
      );
    } catch (_) {
      return null;
    }
  }

  void _updateCase(String id, Map<String, dynamic> Function(Map<String, dynamic>) updater) {
    state = [
      for (final c in state)
        if (c['_id'] == id || c['id'] == id || c['referenceNumber'] == id)
          updater(Map<String, dynamic>.from(c))
        else
          c,
    ];
  }

  /// Sync cases directly from backend MongoDB API
  Future<void> fetchCases({bool force = false}) async {
    _isLoading = true;
    _error = null;
    try {
      // Try assigned cases first
      final res = await _repo.getAssignedCases(page: 1, limit: 50);
      final rawList = res['cases'] as List?;
      if (rawList != null && rawList.isNotEmpty) {
        state = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        return;
      }

      // If assigned list is empty, fetch general case list
      final allRes = await _repo.getCases(page: 1, limit: 50);
      final allList = allRes['cases'] as List?;
      if (allList != null) {
        state = allList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
    }
  }

  /// Request additional evidence from reporter via API
  Future<void> requestEvidence({
    required String caseId,
    required String message,
    required String internalNote,
  }) async {
    final now = DateTime.now().toIso8601String();

    // Optimistic UI update
    _updateCase(caseId, (c) {
      final timeline = List<Map<String, dynamic>>.from(
        (c['timeline'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      final publicUpdates = List<Map<String, dynamic>>.from(
        (c['publicUpdates'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      final internalNotes = List<Map<String, dynamic>>.from(
        (c['internalNotes'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );

      timeline.add({
        'status': 'evidence_requested',
        'note': message,
        'createdAt': now,
      });
      publicUpdates.add({'message': message, 'createdAt': now});
      if (internalNote.trim().isNotEmpty) {
        internalNotes.add({'note': internalNote.trim(), 'createdAt': now});
      }

      return {
        ...c,
        'status': 'evidence_requested',
        'timeline': timeline,
        'publicUpdates': publicUpdates,
        'internalNotes': internalNotes,
      };
    });

    // API Call
    try {
      await _repo.createEvidenceRequest(
        caseId,
        description: message,
        reason: internalNote,
        internalNote: internalNote,
      );
      await _repo.updateCaseStatus(
        caseId,
        'evidence_requested',
        note: message,
      );
    } catch (_) {
      // Optimistic update already in place
    }
  }

  /// Start investigating the case
  Future<void> startInvestigation({
    required String caseId,
    String? note,
  }) async {
    final now = DateTime.now().toIso8601String();
    final noteText = (note ?? '').trim().isEmpty
        ? 'Investigation opened by case officer'
        : note!.trim();

    // Optimistic UI update
    _updateCase(caseId, (c) {
      final timeline = List<Map<String, dynamic>>.from(
        (c['timeline'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      final publicUpdates = List<Map<String, dynamic>>.from(
        (c['publicUpdates'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );

      timeline.add({
        'status': 'investigating',
        'note': noteText,
        'createdAt': now,
      });
      publicUpdates.add({
        'message': 'Your case is now under active investigation.',
        'createdAt': now,
      });

      return {
        ...c,
        'status': 'investigating',
        'timeline': timeline,
        'publicUpdates': publicUpdates,
      };
    });

    // API Call
    final targetId = getById(caseId)?['_id']?.toString() ?? caseId;
    try {
      await _repo.updateCaseStatus(
        targetId,
        'investigating',
        note: noteText,
      );
    } catch (_) {
      // Optimistic state preserved
    }
  }

  /// Add internal confidential note
  Future<void> addInternalNote({
    required String caseId,
    required String note,
  }) async {
    final now = DateTime.now().toIso8601String();

    _updateCase(caseId, (c) {
      final internalNotes = List<Map<String, dynamic>>.from(
        (c['internalNotes'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      internalNotes.add({'note': note.trim(), 'createdAt': now});
      return {
        ...c,
        'internalNotes': internalNotes,
      };
    });

    try {
      await _repo.addInternalNote(caseId, note.trim());
    } catch (_) {}
  }

  /// Submit outcome feedback and close or resolve case
  Future<void> submitFeedbackAndClose({
    required String caseId,
    required String adminFeedback,
    required String userFeedback,
    required bool resolve,
  }) async {
    final status = resolve ? 'resolved' : 'closed';
    final now = DateTime.now().toIso8601String();

    _updateCase(caseId, (c) {
      final timeline = List<Map<String, dynamic>>.from(
        (c['timeline'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      final publicUpdates = List<Map<String, dynamic>>.from(
        (c['publicUpdates'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      final internalNotes = List<Map<String, dynamic>>.from(
        (c['internalNotes'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );

      timeline.add({
        'status': status,
        'note': adminFeedback.trim(),
        'createdAt': now,
      });
      publicUpdates.add({'message': userFeedback.trim(), 'createdAt': now});
      internalNotes.add({
        'note': 'Admin feedback: ${adminFeedback.trim()}',
        'createdAt': now,
      });

      return {
        ...c,
        'status': status,
        'adminFeedback': adminFeedback.trim(),
        'userFeedback': userFeedback.trim(),
        'timeline': timeline,
        'publicUpdates': publicUpdates,
        'internalNotes': internalNotes,
      };
    });

    final targetId = getById(caseId)?['_id']?.toString() ?? caseId;
    try {
      await _repo.updateCaseStatus(targetId, status, note: adminFeedback);
      if (adminFeedback.trim().isNotEmpty) {
        await _repo.addInternalNote(targetId, 'Admin Feedback: ${adminFeedback.trim()}');
      }
    } catch (_) {}
  }

  /// Mark case as under review
  Future<void> markUnderReview(String caseId) async {
    final now = DateTime.now().toIso8601String();
    _updateCase(caseId, (c) {
      if (c['status'] != 'submitted') return c;
      final timeline = List<Map<String, dynamic>>.from(
        (c['timeline'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      timeline.add({
        'status': 'under_review',
        'note': 'Case opened for review by officer',
        'createdAt': now,
      });
      return {...c, 'status': 'under_review', 'timeline': timeline};
    });

    try {
      await _repo.updateCaseStatus(caseId, 'under_review', note: 'Case assigned for review');
    } catch (_) {}
  }
}

// ─── Main Provider ───────────────────────────────────────────────────────────

final officerCasesProvider =
    StateNotifierProvider<OfficerCasesNotifier, List<Map<String, dynamic>>>(
  (ref) => OfficerCasesNotifier(ref.watch(caseRepositoryProvider)),
);

final officerCaseByIdProvider = Provider.family<Map<String, dynamic>?, String>((ref, id) {
  final cases = ref.watch(officerCasesProvider);
  try {
    return cases.firstWhere(
      (c) => c['_id'] == id || c['id'] == id || c['referenceNumber'] == id,
    );
  } catch (_) {
    return null;
  }
});

// ─── Filter & Search Providers ───────────────────────────────────────────────

/// Filter key for status: all | submitted | under_review | investigating | evidence_requested | resolved | closed
final officerQueueFilterProvider = StateProvider<String>((ref) => 'all');

/// Filter key for priority: all | critical | high | medium | low
final officerPriorityFilterProvider = StateProvider<String>((ref) => 'all');

/// Filter key for category: all | arbitrary_detention | torture | etc.
final officerCategoryFilterProvider = StateProvider<String>((ref) => 'all');

/// Search query text
final officerSearchQueryProvider = StateProvider<String>((ref) => '');

/// Filtered cases provider
final filteredOfficerCasesProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final allCases = ref.watch(officerCasesProvider);
  final statusFilter = ref.watch(officerQueueFilterProvider);
  final priorityFilter = ref.watch(officerPriorityFilterProvider);
  final categoryFilter = ref.watch(officerCategoryFilterProvider);
  final searchQuery = ref.watch(officerSearchQueryProvider).trim().toLowerCase();

  return allCases.where((c) {
    // Status filter
    if (statusFilter != 'all' && c['status'] != statusFilter) {
      return false;
    }
    // Priority filter
    if (priorityFilter != 'all' && c['priority'] != priorityFilter) {
      return false;
    }
    // Category filter
    if (categoryFilter != 'all' && c['category'] != categoryFilter) {
      return false;
    }
    // Search query
    if (searchQuery.isNotEmpty) {
      final title = (c['title'] as String? ?? '').toLowerCase();
      final refNum = (c['referenceNumber'] as String? ?? '').toLowerCase();
      final desc = (c['description'] as String? ?? '').toLowerCase();
      final category = (c['category'] as String? ?? '').toLowerCase();
      if (!title.contains(searchQuery) &&
          !refNum.contains(searchQuery) &&
          !desc.contains(searchQuery) &&
          !category.contains(searchQuery)) {
        return false;
      }
    }
    return true;
  }).toList();
});

// ─── Officer Statistics Provider ─────────────────────────────────────────────

class OfficerStatsData {
  final int totalAssigned;
  final int awaitingReview;
  final int activeInvestigations;
  final int evidenceRequested;
  final int resolved;
  final int critical;

  const OfficerStatsData({
    required this.totalAssigned,
    required this.awaitingReview,
    required this.activeInvestigations,
    required this.evidenceRequested,
    required this.resolved,
    required this.critical,
  });
}

final officerStatsProvider = FutureProvider<OfficerStatsData>((ref) async {
  final repo = ref.watch(caseRepositoryProvider);
  final cases = ref.watch(officerCasesProvider);

  try {
    final stats = await repo.getOfficerStats();
    return OfficerStatsData(
      totalAssigned: (stats['totalAssigned'] as num?)?.toInt() ?? cases.length,
      awaitingReview: (stats['awaitingReview'] as num?)?.toInt() ??
          cases.where((c) => c['status'] == 'submitted' || c['status'] == 'under_review').length,
      activeInvestigations: (stats['activeInvestigations'] as num?)?.toInt() ??
          cases.where((c) => c['status'] == 'investigating').length,
      evidenceRequested: (stats['evidenceRequested'] as num?)?.toInt() ??
          cases.where((c) => c['status'] == 'evidence_requested').length,
      resolved: (stats['resolved'] as num?)?.toInt() ??
          cases.where((c) => c['status'] == 'resolved' || c['status'] == 'closed').length,
      critical: cases.where((c) => c['priority'] == 'critical').length,
    );
  } catch (_) {
    // Calculate from local list on error/offline
    return OfficerStatsData(
      totalAssigned: cases.length,
      awaitingReview: cases.where((c) => c['status'] == 'submitted' || c['status'] == 'under_review').length,
      activeInvestigations: cases.where((c) => c['status'] == 'investigating').length,
      evidenceRequested: cases.where((c) => c['status'] == 'evidence_requested').length,
      resolved: cases.where((c) => c['status'] == 'resolved' || c['status'] == 'closed').length,
      critical: cases.where((c) => c['priority'] == 'critical').length,
    );
  }
});

// ─── Evidence Requests Provider ──────────────────────────────────────────────

final officerEvidenceRequestsProvider =
    FutureProvider<List<EvidenceRequestModel>>((ref) async {
  final repo = ref.watch(caseRepositoryProvider);
  try {
    final res = await repo.getOfficerEvidenceRequests();
    final list = res['requests'] as List?;
    if (list != null) {
      return list
          .map((e) => EvidenceRequestModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
  } catch (_) {}
  return [];
});
