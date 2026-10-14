import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Sri Lanka Geographic Constants & Centroids
// ─────────────────────────────────────────────────────────────────────────────

const Map<String, List<String>> sriLankaProvinces = {
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

const Map<String, LatLng> districtCentroids = {
  'Colombo': LatLng(6.9271, 79.8612),
  'Gampaha': LatLng(7.0840, 79.9935),
  'Kalutara': LatLng(6.5854, 79.9607),
  'Kandy': LatLng(7.2906, 80.6337),
  'Matale': LatLng(7.4675, 80.6234),
  'Nuwara Eliya': LatLng(6.9497, 80.7891),
  'Galle': LatLng(6.0535, 80.2210),
  'Matara': LatLng(5.9549, 80.5550),
  'Hambantota': LatLng(6.1429, 81.1212),
  'Jaffna': LatLng(9.6615, 80.0255),
  'Kilinochchi': LatLng(9.3803, 80.3770),
  'Mannar': LatLng(8.9810, 79.9044),
  'Vavuniya': LatLng(8.7542, 80.4982),
  'Mullaitivu': LatLng(9.2671, 80.8143),
  'Batticaloa': LatLng(7.7310, 81.6747),
  'Ampara': LatLng(7.2912, 81.6724),
  'Trincomalee': LatLng(8.5874, 81.2152),
  'Kurunegala': LatLng(7.4863, 80.3623),
  'Puttalam': LatLng(8.0408, 79.8394),
  'Anuradhapura': LatLng(8.3114, 80.4037),
  'Polonnaruwa': LatLng(7.9403, 81.0188),
  'Badulla': LatLng(6.9934, 81.0550),
  'Monaragala': LatLng(6.8728, 81.3507),
  'Ratnapura': LatLng(6.6828, 80.3992),
  'Kegalle': LatLng(7.2513, 80.3464),
};

const Map<String, String> incidentCategories = {
  'theft': 'Theft',
  'harassment': 'Harassment',
  'land_dispute': 'Land Dispute',
  'assault': 'Assault',
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

const Map<String, Color> categoryColorPalette = {
  'theft': Color(0xFF3B82F6),
  'harassment': Color(0xFFEC4899),
  'land_dispute': Color(0xFF8B5CF6),
  'assault': Color(0xFFEF4444),
  'arbitrary_detention': Color(0xFFF97316),
  'torture': Color(0xFFDC2626),
  'forced_disappearance': Color(0xFFB91C1C),
  'extrajudicial_killing': Color(0xFF7F1D1D),
  'discrimination': Color(0xFFF59E0B),
  'freedom_of_expression': Color(0xFF10B981),
  'freedom_of_assembly': Color(0xFF06B6D4),
  'right_to_fair_trial': Color(0xFF6366F1),
  'other': Color(0xFF6B7280),
};

/// Screen for descriptive clustering-based hotspot detection & risk visualization
class AdminHotspotMapScreen extends StatefulWidget {
  const AdminHotspotMapScreen({super.key});

  @override
  State<AdminHotspotMapScreen> createState() => _AdminHotspotMapScreenState();
}

class _AdminHotspotMapScreenState extends State<AdminHotspotMapScreen> {
  final MapController _mapController = MapController();

  // Filters
  String _dateRange = 'this_month';
  String _selectedProvince = 'All';
  String _selectedDistrict = 'All';
  final Set<String> _selectedCategories = {};
  DateTime? _customStartDate;
  DateTime? _customEndDate;

  // View Controls
  bool _showHeatmapOverlay = true;
  bool _isLoading = true;
  String? _errorMessage;

  // Data from backend
  List<dynamic> _hotspots = [];
  List<dynamic> _markers = [];
  List<dynamic> _heatZones = [];
  Map<String, dynamic> _summary = {};

  // Selected Marker for callout preview
  Map<String, dynamic>? _selectedMarker;

  @override
  void initState() {
    super.initState();
    _fetchHotspotData();
  }

  Future<void> _fetchHotspotData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final queryParams = <String, dynamic>{
        'dateRange': _dateRange,
        if (_selectedProvince != 'All') 'province': _selectedProvince,
        if (_selectedDistrict != 'All') 'district': _selectedDistrict,
        if (_selectedCategories.isNotEmpty) 'categories': _selectedCategories.join(','),
        if (_dateRange == 'custom' && _customStartDate != null)
          'startDate': _customStartDate!.toIso8601String(),
        if (_dateRange == 'custom' && _customEndDate != null)
          'endDate': _customEndDate!.toIso8601String(),
      };

      final response = await ApiService.instance.client.get(
        '/analytics/hotspots',
        queryParameters: queryParams,
      );

      final data = response.data['data'] as Map<String, dynamic>? ?? {};

      if (mounted) {
        setState(() {
          _hotspots = (data['hotspots'] as List<dynamic>?) ?? [];
          _markers = (data['markers'] as List<dynamic>?) ?? [];
          _heatZones = (data['heatZones'] as List<dynamic>?) ?? [];
          _summary = (data['summary'] as Map<String, dynamic>?) ?? {};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  List<String> get _availableDistricts {
    if (_selectedProvince == 'All') {
      return ['All', ...districtCentroids.keys];
    }
    return ['All', ...(sriLankaProvinces[_selectedProvince] ?? [])];
  }

  Color _getRiskColor(String? riskLevel) {
    switch (riskLevel?.toLowerCase()) {
      case 'critical':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
      default:
        return const Color(0xFF10B981);
    }
  }

  Color _getDensityColor(String? densityLevel) {
    switch (densityLevel?.toLowerCase()) {
      case 'very high':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF97316);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
      default:
        return const Color(0xFF10B981);
    }
  }

  void _zoomToDistrict(String districtName) {
    final centroid = districtCentroids[districtName];
    if (centroid != null) {
      _mapController.move(centroid, 11.0);
    }
  }

  void _resetMapOverview() {
    _mapController.move(const LatLng(7.8731, 80.7718), 7.8);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Category Multi-Select Filter Modal
  // ─────────────────────────────────────────────────────────────────────────
  void _openCategoryFilterModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.75,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter by Incident Category',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategories.clear();
                            _selectedCategories.addAll(incidentCategories.keys);
                          });
                        },
                        child: const Text('Select All', style: TextStyle(color: AppColors.accent, fontSize: 13)),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedCategories.clear();
                          });
                        },
                        child: const Text('Clear All', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                      ),
                    ],
                  ),
                  const Divider(color: AppColors.divider),
                  Expanded(
                    child: ListView(
                      children: incidentCategories.entries.map((entry) {
                        final isSelected = _selectedCategories.contains(entry.key);
                        final catColor = categoryColorPalette[entry.key] ?? AppColors.textMuted;
                        return CheckboxListTile(
                          dense: true,
                          value: isSelected,
                          activeColor: AppColors.accent,
                          title: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                _selectedCategories.add(entry.key);
                              } else {
                                _selectedCategories.remove(entry.key);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _fetchHotspotData();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Apply Category Filters', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Custom Date Range Picker
  // ─────────────────────────────────────────────────────────────────────────
  Future<void> _selectCustomDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = 'custom';
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
      _fetchHotspotData();
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Bottom Sheet for District Hotspots & Summary Stats
  // ─────────────────────────────────────────────────────────────────────────
  void _openHotspotsSidePanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.65,
          minChildSize: 0.35,
          maxChildSize: 0.90,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: AppColors.warning, size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Hotspot Districts & Risk Analysis',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const Text(
                    'Descriptive incident density ranking across districts for the selected range',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 16),

                  // ── Top 5 Hotspot Districts ──
                  const Text(
                    'TOP 5 HOTSPOT DISTRICTS',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (_hotspots.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: const Center(
                        child: Text(
                          'No incident hotspots found in the selected date range and filters.',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ..._hotspots.map((h) {
                      final district = h['district']?.toString() ?? 'Unknown';
                      final count = h['count'] ?? 0;
                      final mainCategoryLabel = h['mainCategoryLabel'] ?? 'Incident';
                      final riskLevel = h['riskLevel']?.toString() ?? 'Low';
                      final trend = h['trend'] as Map<String, dynamic>? ?? {};
                      final trendDir = trend['direction']?.toString() ?? 'flat';
                      final trendLabel = trend['label']?.toString() ?? '0%';
                      final riskColor = _getRiskColor(riskLevel);

                      return InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _zoomToDistrict(district);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: riskColor.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: riskColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    '#${h['rank'] ?? 1}',
                                    style: TextStyle(
                                      color: riskColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          district,
                                          style: const TextStyle(
                                            color: AppColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '(${h['province'] ?? ''})',
                                          style: const TextStyle(
                                            color: AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Primary: $mainCategoryLabel',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        '$count cases',
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      _buildTrendBadge(trendDir, trendLabel),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: riskColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: riskColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      '$riskLevel Risk',
                                      style: TextStyle(
                                        color: riskColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textMuted),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 12),

                  // ── Summary Stats ──
                  const Text(
                    'INCIDENT SUMMARY & METRICS',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Total cases banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Total Cases in Period', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(
                              '${_summary['totalCases'] ?? 0}',
                              style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.verified_outlined, size: 14, color: AppColors.accent),
                              SizedBox(width: 6),
                              Text('Approved Cases', style: TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Category Breakdown
                  const Text('Breakdown by Category', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ...((_summary['categoryBreakdown'] as List<dynamic>?) ?? []).map((cat) {
                    final label = cat['label']?.toString() ?? 'Other';
                    final cnt = cat['count'] ?? 0;
                    final pct = cat['percentage'] ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                              Text('$cnt ($pct%)', style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: (pct as num) / 100.0,
                            backgroundColor: AppColors.surfaceVariant,
                            color: AppColors.accent,
                            minHeight: 4,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  // Status Breakdown
                  const Text('Breakdown by Status', style: TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildStatusStatCard('Approved', _getStatusCount('approved'), AppColors.info),
                      const SizedBox(width: 8),
                      _buildStatusStatCard('In Progress', _getStatusCount('in_progress'), AppColors.warning),
                      const SizedBox(width: 8),
                      _buildStatusStatCard('Completed', _getStatusCount('completed'), AppColors.success),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTrendBadge(String direction, String label) {
    Color color = AppColors.textMuted;
    IconData icon = Icons.remove_rounded;

    if (direction == 'up') {
      color = AppColors.error;
      icon = Icons.arrow_upward_rounded;
    } else if (direction == 'down') {
      color = AppColors.success;
      icon = Icons.arrow_downward_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 2),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  int _getStatusCount(String statusKey) {
    final list = (_summary['statusBreakdown'] as List<dynamic>?) ?? [];
    for (final item in list) {
      if (item['status'] == statusKey) {
        return (item['count'] as num?)?.toInt() ?? 0;
      }
    }
    return 0;
  }

  Widget _buildStatusStatCard(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Hotspot Detection Map'),
        backgroundColor: AppColors.primaryDark,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _showHeatmapOverlay ? Icons.local_fire_department_rounded : Icons.local_fire_department_outlined,
              color: _showHeatmapOverlay ? AppColors.warning : AppColors.textMuted,
            ),
            tooltip: _showHeatmapOverlay ? 'Heatmap Overlay: ON' : 'Heatmap Overlay: OFF',
            onPressed: () {
              setState(() {
                _showHeatmapOverlay = !_showHeatmapOverlay;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.analytics_outlined, color: AppColors.accent),
            tooltip: 'View Hotspot Districts & Metrics',
            onPressed: _openHotspotsSidePanel,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
            tooltip: 'Refresh Map',
            onPressed: _fetchHotspotData,
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // ── Filter Top Bar ──
              _buildFilterTopBar(),

              // ── Main Map Canvas ──
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: const MapOptions(
                        initialCenter: LatLng(7.8731, 80.7718),
                        initialZoom: 7.6,
                        minZoom: 6.5,
                        maxZoom: 16.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.justicenow.justice_now',
                        ),
                        if (_showHeatmapOverlay)
                          CircleLayer(
                            circles: _buildHeatCircles(),
                          ),
                        MarkerLayer(
                          markers: _buildCaseMarkers(),
                        ),
                      ],
                    ),

                    if (_isLoading)
                      Container(
                        color: Colors.black.withValues(alpha: 0.4),
                        child: const Center(
                          child: CircularProgressIndicator(color: AppColors.accent),
                        ),
                      ),

                    if (_errorMessage != null)
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Error loading map data: $_errorMessage',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 16),
                                onPressed: () => setState(() => _errorMessage = null),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Map Floating Controls (Right Side)
                    Positioned(
                      right: 14,
                      top: 14,
                      child: Column(
                        children: [
                          _buildFloatingMapButton(
                            icon: Icons.add_rounded,
                            tooltip: 'Zoom In',
                            onTap: () {
                              _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom + 1,
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          _buildFloatingMapButton(
                            icon: Icons.remove_rounded,
                            tooltip: 'Zoom Out',
                            onTap: () {
                              _mapController.move(
                                _mapController.camera.center,
                                _mapController.camera.zoom - 1,
                              );
                            },
                          ),
                          const SizedBox(height: 6),
                          _buildFloatingMapButton(
                            icon: Icons.center_focus_strong_rounded,
                            tooltip: 'Reset to Sri Lanka Overview',
                            onTap: _resetMapOverview,
                          ),
                          const SizedBox(height: 6),
                          _buildFloatingMapButton(
                            icon: _showHeatmapOverlay ? Icons.layers_rounded : Icons.layers_outlined,
                            tooltip: 'Toggle Heatmap Density',
                            active: _showHeatmapOverlay,
                            onTap: () {
                              setState(() => _showHeatmapOverlay = !_showHeatmapOverlay);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Map Density Legend (Bottom-Left)
                    Positioned(
                      left: 14,
                      bottom: 14,
                      child: _buildMapLegend(),
                    ),

                    // Side Panel Shortcut Pill (Bottom-Center)
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: ElevatedButton.icon(
                        onPressed: _openHotspotsSidePanel,
                        icon: const Icon(Icons.insights_rounded, size: 16),
                        label: Text('Top Hotspots (${_hotspots.length})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryDark,
                          foregroundColor: AppColors.accent,
                          side: const BorderSide(color: AppColors.accent),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Selected Marker Callout Popup Card ──
          if (_selectedMarker != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildMarkerCalloutCard(_selectedMarker!),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Filter Top Bar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFilterTopBar() {
    final catCount = _selectedCategories.length;
    final catLabel = catCount == 0
        ? 'All Categories'
        : catCount == 1
            ? incidentCategories[_selectedCategories.first] ?? '1 Category'
            : '$catCount Categories';

    return Container(
      color: AppColors.primaryDark,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Date Range Filter Chip
                _buildFilterDropdown(
                  icon: Icons.calendar_today_rounded,
                  label: _dateRange == 'custom'
                      ? 'Custom Date'
                      : _dateRange.replaceAll('_', ' ').toUpperCase(),
                  onTap: _showDateRangeDialog,
                ),
                const SizedBox(width: 8),

                // Province Filter
                _buildFilterDropdown(
                  icon: Icons.map_outlined,
                  label: _selectedProvince == 'All' ? 'All Provinces' : _selectedProvince,
                  onTap: _showProvinceDialog,
                ),
                const SizedBox(width: 8),

                // District Filter
                _buildFilterDropdown(
                  icon: Icons.location_city_rounded,
                  label: _selectedDistrict == 'All' ? 'All Districts' : _selectedDistrict,
                  onTap: _showDistrictDialog,
                ),
                const SizedBox(width: 8),

                // Category Multi-select Filter
                InkWell(
                  onTap: _openCategoryFilterModal,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: catCount > 0
                          ? AppColors.accent.withValues(alpha: 0.15)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: catCount > 0 ? AppColors.accent : AppColors.divider,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.category_outlined,
                          size: 14,
                          color: catCount > 0 ? AppColors.accent : AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          catLabel,
                          style: TextStyle(
                            color: catCount > 0 ? AppColors.accent : AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  void _showDateRangeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Select Incident Date Range', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        children: [
          ...['today', 'this_week', 'last_week', 'this_month', 'last_month'].map(
            (r) => SimpleDialogOption(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _dateRange = r);
                _fetchHotspotData();
              },
              child: Text(
                r.replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  color: _dateRange == r ? AppColors.accent : AppColors.textPrimary,
                  fontWeight: _dateRange == r ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              _selectCustomDateRange();
            },
            child: Text(
              'CUSTOM RANGE...',
              style: TextStyle(
                color: _dateRange == 'custom' ? AppColors.accent : AppColors.textPrimary,
                fontWeight: _dateRange == 'custom' ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProvinceDialog() {
    final provinces = ['All', ...sriLankaProvinces.keys];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Filter by Province', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        children: provinces.map(
          (p) => SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _selectedProvince = p;
                _selectedDistrict = 'All'; // reset district if province changes
              });
              _fetchHotspotData();
            },
            child: Text(
              p,
              style: TextStyle(
                color: _selectedProvince == p ? AppColors.accent : AppColors.textPrimary,
                fontWeight: _selectedProvince == p ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ).toList(),
      ),
    );
  }

  void _showDistrictDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Filter by District', style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        children: _availableDistricts.map(
          (d) => SimpleDialogOption(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _selectedDistrict = d);
              _fetchHotspotData();
              if (d != 'All') _zoomToDistrict(d);
            },
            child: Text(
              d,
              style: TextStyle(
                color: _selectedDistrict == d ? AppColors.accent : AppColors.textPrimary,
                fontWeight: _selectedDistrict == d ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ).toList(),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Map Layers: Circles & Markers
  // ─────────────────────────────────────────────────────────────────────────
  List<CircleMarker> _buildHeatCircles() {
    return _heatZones.map((z) {
      final lat = (z['lat'] as num?)?.toDouble() ?? 0.0;
      final lng = (z['lng'] as num?)?.toDouble() ?? 0.0;
      final densityLevel = z['densityLevel']?.toString() ?? 'Low';
      final color = _getDensityColor(densityLevel);
      final count = (z['count'] as num?)?.toInt() ?? 1;

      // Dynamic radius based on incident volume
      final radius = count >= 10 ? 38.0 : count >= 6 ? 28.0 : count >= 3 ? 20.0 : 15.0;

      return CircleMarker(
        point: LatLng(lat, lng),
        radius: radius,
        useRadiusInMeter: false,
        color: color.withValues(alpha: 0.28),
        borderColor: color.withValues(alpha: 0.8),
        borderStrokeWidth: 2,
      );
    }).toList();
  }

  List<Marker> _buildCaseMarkers() {
    return _markers.map((m) {
      final lat = (m['lat'] as num?)?.toDouble() ?? 0.0;
      final lng = (m['lng'] as num?)?.toDouble() ?? 0.0;
      final cat = m['category']?.toString() ?? 'other';
      final pinColor = categoryColorPalette[cat] ?? AppColors.accent;
      final isSelected = _selectedMarker != null && _selectedMarker!['id'] == m['id'];

      return Marker(
        point: LatLng(lat, lng),
        width: isSelected ? 42 : 32,
        height: isSelected ? 42 : 32,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedMarker = m;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: pinColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.black45,
                width: isSelected ? 3 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: pinColor.withValues(alpha: 0.5),
                  blurRadius: isSelected ? 12 : 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.place_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
      );
    }).toList();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Marker Callout Preview Card
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildMarkerCalloutCard(Map<String, dynamic> marker) {
    final title = marker['title']?.toString() ?? 'Incident Report';
    final categoryLabel = marker['categoryLabel']?.toString() ?? 'Incident';
    final formattedDate = marker['formattedDate']?.toString() ?? '';
    final district = marker['district']?.toString() ?? '';
    final province = marker['province']?.toString() ?? '';
    final statusLabel = marker['statusLabel']?.toString() ?? 'Approved';
    final caseId = marker['id']?.toString() ?? '';
    final refNum = marker['referenceNumber']?.toString() ?? '';
    final catColor = categoryColorPalette[marker['category']] ?? AppColors.accent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: catColor.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: catColor, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(categoryLabel, style: TextStyle(color: catColor, fontSize: 11, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              const Spacer(),
              if (refNum.isNotEmpty)
                Text(refNum, style: const TextStyle(color: AppColors.accent, fontSize: 11, fontWeight: FontWeight.w600)),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                onPressed: () => setState(() => _selectedMarker = null),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text(formattedDate, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(width: 14),
              const Icon(Icons.location_on_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('$district, $province', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text('Status: $statusLabel', style: const TextStyle(color: AppColors.info, fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.push('${AppRoutes.adminCases}/$caseId');
              },
              icon: const Icon(Icons.visibility_rounded, size: 16),
              label: const Text('View Case Details', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Floating Controls & Density Legend
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFloatingMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: active ? AppColors.accent : AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: active ? AppColors.accent : AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: active ? AppColors.primaryDark : AppColors.textPrimary),
        tooltip: tooltip,
        onPressed: onTap,
      ),
    );
  }

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('DENSITY LEGEND', style: TextStyle(color: AppColors.textMuted, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          const SizedBox(height: 6),
          _buildLegendItem(const Color(0xFF10B981), 'Low (1–2)'),
          const SizedBox(height: 3),
          _buildLegendItem(const Color(0xFFF59E0B), 'Medium (3–5)'),
          const SizedBox(height: 3),
          _buildLegendItem(const Color(0xFFF97316), 'High (6–9)'),
          const SizedBox(height: 3),
          _buildLegendItem(const Color(0xFFEF4444), 'Very High (10+)'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
      ],
    );
  }
}
