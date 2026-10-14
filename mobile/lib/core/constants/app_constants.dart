import 'dart:io';

class AppConstants {
  AppConstants._();

  // API
// API
  static final String baseUrl = _getBaseUrl();
  static String get apiBaseUrl => baseUrl;

  static String _getBaseUrl() {
    const configuredUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    if (configuredUrl.isNotEmpty) return configuredUrl;

    return Platform.isAndroid
        ? 'http://10.0.2.2:3000/api'
        : 'http://localhost:3000/api';
  }

  static String get serverOrigin => baseUrl.replaceAll('/api', '');

  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$serverOrigin$cleanPath';
  }

  // Secure storage keys
  static const String tokenKey = 'jn_auth_token';
  static const String userKey = 'jn_user_data';

  // Case status labels
  static const Map<String, String> caseStatusLabels = {
    'submitted': 'Submitted',
    'under_review': 'Under Review',
    'investigating': 'Investigating',
    'evidence_requested': 'Evidence Requested',
    'referred_to_ngo': 'Referred to NGO',
    'legal_action_initiated': 'Legal Action Initiated',
    'awaiting_lawyer_selection': 'Approved - Select Lawyer',
    'waiting_for_lawyer_approval': 'Waiting for Lawyer Approval',
    'approved_scheduled': 'Approved – Scheduled',
    'assigned_to_police': 'Assigned to Police',
    'in_progress_police': 'In Progress – Police',
    'suspect_identified': 'Suspect Identified',
    'referred_to_court': 'Referred to Court',
    'police_declined': 'Police Declined',
    'in_progress': 'In Progress',
    'completed': 'Completed',
    'lawyer_declined': 'Lawyer Declined',
    'resolved': 'Resolved',
    'closed': 'Closed',
    'rejected': 'Rejected',
  };

  // Case categories
  static const Map<String, String> caseCategories = {
    'arbitrary_detention': 'Arbitrary Detention',
    'torture': 'Torture',
    'forced_disappearance': 'Forced Disappearance',
    'extrajudicial_killing': 'Extrajudicial Killing',
    'discrimination': 'Discrimination',
    'freedom_of_expression': 'Freedom of Expression',
    'freedom_of_assembly': 'Freedom of Assembly',
    'right_to_fair_trial': 'Right to Fair Trial',
    'other': 'Other',
  };

  // Priority labels
  static const Map<String, String> priorityLabels = {
    'low': 'Low',
    'medium': 'Medium',
    'high': 'High',
    'critical': 'Critical',
  };

  // Pagination
  static const int defaultPageSize = 20;

  // File upload
  static const int maxFileSizeMB = 50;
  static const int maxFilesPerUpload = 10;
}
