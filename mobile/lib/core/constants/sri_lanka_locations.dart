/// Sri Lanka Administrative Provinces and Districts
class SriLankaLocations {
  SriLankaLocations._();

  static const List<String> provinces = [
    'Central',
    'Eastern',
    'North Central',
    'Northern',
    'North Western',
    'Sabaragamuwa',
    'Southern',
    'Uva',
    'Western',
  ];

  static const Map<String, List<String>> districtsByProvince = {
    'Western': ['Colombo', 'Gampaha', 'Kalutara'],
    'Central': ['Kandy', 'Matale', 'Nuwara Eliya'],
    'Southern': ['Galle', 'Matara', 'Hambantota'],
    'Northern': ['Jaffna', 'Kilinochchi', 'Mannar', 'Vavuniya', 'Mullaitivu'],
    'Eastern': ['Batticaloa', 'Ampara', 'Trincomalee'],
    'North Western': ['Kurunegala', 'Puttalam'],
    'North Central': ['Anuradhapura', 'Polonnaruwa'],
    'Uva': ['Badulla', 'Monaragala'],
    'Sabaragamuwa': ['Ratnapura', 'Kegalle'],
  };

  static List<String> getDistrictsForProvince(String? province) {
    if (province == null) return [];
    return districtsByProvince[province] ?? [];
  }
}
