class AppConstants {
  AppConstants._();

  // API
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:3000/api', // Android emulator → localhost
  );

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
