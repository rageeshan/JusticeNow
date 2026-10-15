class EvidenceRequestModel {
  final String id;
  final String caseId;
  final String description;
  final String reason;
  final String instructions;
  final DateTime? dueDate;
  final String status;
  final List<Map<String, dynamic>> responseEvidence;
  final String? reviewNotes;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final Map<String, dynamic>? requestedBy;
  final Map<String, dynamic>? caseData;

  const EvidenceRequestModel({
    required this.id,
    required this.caseId,
    required this.description,
    this.reason = '',
    this.instructions = '',
    this.dueDate,
    this.status = 'pending',
    this.responseEvidence = const [],
    this.reviewNotes,
    this.reviewedAt,
    required this.createdAt,
    this.requestedBy,
    this.caseData,
  });

  factory EvidenceRequestModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    String caseIdVal = '';
    Map<String, dynamic>? caseMap;
    if (json['case'] is Map) {
      caseMap = Map<String, dynamic>.from(json['case'] as Map);
      caseIdVal = caseMap['_id']?.toString() ?? '';
    } else if (json['case'] != null) {
      caseIdVal = json['case'].toString();
    }

    return EvidenceRequestModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      caseId: caseIdVal,
      description: json['description']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      instructions: json['instructions']?.toString() ?? '',
      dueDate: parseDate(json['dueDate']),
      status: json['status']?.toString() ?? 'pending',
      responseEvidence: (json['responseEvidence'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          [],
      reviewNotes: json['reviewNotes']?.toString(),
      reviewedAt: parseDate(json['reviewedAt']),
      createdAt: parseDate(json['createdAt']) ?? DateTime.now(),
      requestedBy: json['requestedBy'] is Map
          ? Map<String, dynamic>.from(json['requestedBy'] as Map)
          : null,
      caseData: caseMap,
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'case': caseId,
        'description': description,
        'reason': reason,
        'instructions': instructions,
        'dueDate': dueDate?.toIso8601String(),
        'status': status,
        'responseEvidence': responseEvidence,
        'reviewNotes': reviewNotes,
        'reviewedAt': reviewedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}
