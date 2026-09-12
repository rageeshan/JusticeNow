import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/officer_static_data.dart';

class OfficerCasesNotifier extends StateNotifier<List<Map<String, dynamic>>> {
  OfficerCasesNotifier() : super(OfficerStaticData.seedCases());

  Map<String, dynamic>? getById(String id) {
    try {
      return state.firstWhere((c) => c['_id'] == id);
    } catch (_) {
      return null;
    }
  }

  void _updateCase(String id, Map<String, dynamic> Function(Map<String, dynamic>) updater) {
    state = [
      for (final c in state)
        if (c['_id'] == id) updater(Map<String, dynamic>.from(c)) else c,
    ];
  }

  void requestEvidence({
    required String caseId,
    required String message,
    required String internalNote,
  }) {
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
      final now = DateTime.now().toIso8601String();

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
  }

  void startInvestigation({
    required String caseId,
    String? note,
  }) {
    _updateCase(caseId, (c) {
      final timeline = List<Map<String, dynamic>>.from(
        (c['timeline'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      final publicUpdates = List<Map<String, dynamic>>.from(
        (c['publicUpdates'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      final now = DateTime.now().toIso8601String();
      final noteText = (note ?? '').trim().isEmpty
          ? 'Investigation opened by case officer'
          : note!.trim();

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
  }

  void submitFeedbackAndClose({
    required String caseId,
    required String adminFeedback,
    required String userFeedback,
    required bool resolve,
  }) {
    _updateCase(caseId, (c) {
      final status = resolve ? 'resolved' : 'closed';
      final timeline = List<Map<String, dynamic>>.from(
        (c['timeline'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      final publicUpdates = List<Map<String, dynamic>>.from(
        (c['publicUpdates'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      final internalNotes = List<Map<String, dynamic>>.from(
        (c['internalNotes'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      final now = DateTime.now().toIso8601String();

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
  }

  void markUnderReview(String caseId) {
    _updateCase(caseId, (c) {
      if (c['status'] != 'submitted') return c;
      final timeline = List<Map<String, dynamic>>.from(
        (c['timeline'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)) ?? [],
      );
      final now = DateTime.now().toIso8601String();
      timeline.add({
        'status': 'under_review',
        'note': 'Case opened for review by officer',
        'createdAt': now,
      });
      return {...c, 'status': 'under_review', 'timeline': timeline};
    });
  }
}

final officerCasesProvider =
    StateNotifierProvider<OfficerCasesNotifier, List<Map<String, dynamic>>>(
  (ref) => OfficerCasesNotifier(),
);

final officerCaseByIdProvider = Provider.family<Map<String, dynamic>?, String>((ref, id) {
  final cases = ref.watch(officerCasesProvider);
  try {
    return cases.firstWhere((c) => c['_id'] == id);
  } catch (_) {
    return null;
  }
});

/// Filter key for the officer queue: all | submitted | under_review | investigating | evidence_requested | closed
final officerQueueFilterProvider = StateProvider<String>((ref) => 'all');
