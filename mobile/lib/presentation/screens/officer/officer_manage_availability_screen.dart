import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/services/api_service.dart';

class OfficerManageAvailabilityScreen extends StatefulWidget {
  const OfficerManageAvailabilityScreen({super.key});

  @override
  State<OfficerManageAvailabilityScreen> createState() =>
      _OfficerManageAvailabilityScreenState();
}

class _OfficerManageAvailabilityScreenState
    extends State<OfficerManageAvailabilityScreen> {
  bool _isLoading = true;
  bool _isSaving = false;

  final List<String> _daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  Map<String, Map<String, dynamic>> _schedule = {};

  @override
  void initState() {
    super.initState();
    _initDefaultSchedule();
    _fetchAvailability();
  }

  void _initDefaultSchedule() {
    _schedule = {
      for (final day in _daysOfWeek)
        day: {
          'isUnavailable': day == 'Sunday',
          'slots': day == 'Sunday'
              ? <Map<String, String>>[]
              : <Map<String, String>>[
                  {'startTime': '09:00 AM', 'endTime': '12:00 PM'},
                  {'startTime': '02:00 PM', 'endTime': '05:00 PM'},
                ],
        }
    };
  }

  Future<void> _fetchAvailability() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService.instance.client.get('/cases/officer/availability');
      final rawAvail = response.data['data']?['availability'];
      if (rawAvail is Map && rawAvail.isNotEmpty) {
        final res = Map<String, dynamic>.from(rawAvail);
        for (final day in _daysOfWeek) {
          if (res.containsKey(day) && res[day] is Map) {
            final dayData = Map<String, dynamic>.from(res[day] as Map);
            final rawSlots = dayData['slots'] as List<dynamic>? ?? [];
            final List<Map<String, String>> parsedSlots = [];
            for (final s in rawSlots) {
              if (s is Map) {
                parsedSlots.add({
                  'startTime': s['startTime']?.toString() ?? '09:00 AM',
                  'endTime': s['endTime']?.toString() ?? '12:00 PM',
                });
              }
            }
            _schedule[day] = {
              'isUnavailable': dayData['isUnavailable'] == true,
              'slots': parsedSlots,
            };
          }
        }
      }
    } catch (_) {
      // Use default schedule if network fetch fails
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAvailability() async {
    setState(() => _isSaving = true);
    try {
      await ApiService.instance.client.put(
        '/cases/officer/availability',
        data: {'availability': _schedule},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Duty availability schedule saved successfully! Slots are now active for case approvals.',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save schedule: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickTime(
    BuildContext context,
    String day,
    int slotIndex,
    bool isStart,
  ) async {
    final slots =
        List<Map<String, String>>.from(_schedule[day]!['slots'] as List);
    final currentStr =
        isStart ? slots[slotIndex]['startTime']! : slots[slotIndex]['endTime']!;

    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    try {
      final parts = currentStr.split(' ');
      final hm = parts[0].split(':');
      var hour = int.parse(hm[0]);
      final minute = int.parse(hm[1]);
      if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour < 12) {
        hour += 12;
      }
      if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }
      initial = TimeOfDay(hour: hour, minute: minute);
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final hour = picked.hourOfPeriod == 0 ? 12 : picked.hourOfPeriod;
      final minute = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      final formatted = '${hour.toString().padLeft(2, '0')}:$minute $period';

      setState(() {
        if (isStart) {
          slots[slotIndex]['startTime'] = formatted;
        } else {
          slots[slotIndex]['endTime'] = formatted;
        }
        _schedule[day]!['slots'] = slots;
      });
    }
  }

  void _addSlot(String day) {
    setState(() {
      final slots =
          List<Map<String, String>>.from(_schedule[day]!['slots'] as List);
      slots.add({'startTime': '09:00 AM', 'endTime': '01:00 PM'});
      _schedule[day]!['slots'] = slots;
      _schedule[day]!['isUnavailable'] = false;
    });
  }

  void _removeSlot(String day, int index) {
    setState(() {
      final slots =
          List<Map<String, String>>.from(_schedule[day]!['slots'] as List);
      slots.removeAt(index);
      _schedule[day]!['slots'] = slots;
    });
  }

  void _applyStandardPreset() {
    setState(() {
      for (final day in _daysOfWeek) {
        if (day == 'Saturday' || day == 'Sunday') {
          _schedule[day] = {
            'isUnavailable': true,
            'slots': <Map<String, String>>[],
          };
        } else {
          _schedule[day] = {
            'isUnavailable': false,
            'slots': <Map<String, String>>[
              {'startTime': '09:00 AM', 'endTime': '12:00 PM'},
              {'startTime': '02:00 PM', 'endTime': '05:00 PM'},
            ],
          };
        }
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Applied standard shifts: Mon–Fri (9:00 AM–12:00 PM, 2:00 PM–5:00 PM). Remember to tap Save!'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Set Availability'),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            color: AppColors.surface,
            onSelected: (value) {
              if (value == 'preset') {
                _applyStandardPreset();
              } else if (value == 'reload') {
                _fetchAvailability();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'preset',
                child: Row(
                  children: [
                    Icon(Icons.auto_fix_high_rounded, color: AppColors.accent, size: 18),
                    SizedBox(width: 10),
                    Text('Apply Standard Shifts', style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reload',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 18),
                    SizedBox(width: 10),
                    Text('Reload from Server', style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // ── Hero Info Banner ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: const Border(
                        bottom: BorderSide(color: AppColors.divider),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.access_time_filled_rounded,
                                color: AppColors.accent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Define Your Weekly Duty Slots',
                                    style: TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'When approving a case, only these saved slots are offered. This prevents double-booking.',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Visual Example Card
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Row(
                            children: const [
                              Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 14),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ex: Mon → 9:00 AM – 12:00 PM, 2:00 PM – 5:00 PM • Wed → Unavailable',
                                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Weekly Schedule List (Mon–Sun) ──
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _daysOfWeek.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final day = _daysOfWeek[index];
                        final dayData = _schedule[day]!;
                        final isUnavailable = dayData['isUnavailable'] == true;
                        final slots =
                            List<Map<String, String>>.from(dayData['slots'] as List);

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isUnavailable
                                  ? AppColors.divider
                                  : AppColors.accent.withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Day Header Row
                                Row(
                                  children: [
                                    // Day Badge (MON, TUE, etc.)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isUnavailable
                                            ? AppColors.surfaceVariant
                                            : AppColors.accent.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        day.substring(0, 3).toUpperCase(),
                                        style: TextStyle(
                                          color: isUnavailable
                                              ? AppColors.textMuted
                                              : AppColors.accent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      day,
                                      style: TextStyle(
                                        color: isUnavailable
                                            ? AppColors.textMuted
                                            : AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const Spacer(),

                                    // Unavailable Switch Toggle
                                    Row(
                                      children: [
                                        Text(
                                          'Unavailable',
                                          style: TextStyle(
                                            color: isUnavailable
                                                ? AppColors.warning
                                                : AppColors.textMuted,
                                            fontSize: 12,
                                            fontWeight: isUnavailable
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                        Transform.scale(
                                          scale: 0.8,
                                          child: Switch(
                                            value: isUnavailable,
                                            activeThumbColor: AppColors.warning,
                                            onChanged: (val) {
                                              setState(() {
                                                dayData['isUnavailable'] = val;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // Slots Body
                                if (!isUnavailable) ...[
                                  const SizedBox(height: 12),
                                  const Divider(color: AppColors.divider, height: 1),
                                  const SizedBox(height: 12),

                                  if (slots.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Row(
                                        children: const [
                                          Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
                                          SizedBox(width: 6),
                                          Text(
                                            'No time slots configured. Tap below to add a slot.',
                                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: slots.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(height: 10),
                                      itemBuilder: (ctx, slotIdx) {
                                        final slot = slots[slotIdx];
                                        return Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: AppColors.surfaceVariant,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                                color: AppColors.divider),
                                          ),
                                          child: Row(
                                            children: [
                                              // Start Time Button
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () => _pickTime(
                                                      context, day, slotIdx, true),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.surface,
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                      border: Border.all(
                                                          color: AppColors.divider),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(
                                                          Icons.access_time_rounded,
                                                          color: AppColors.accent,
                                                          size: 14,
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          slot['startTime']!,
                                                          style: const TextStyle(
                                                            color: AppColors.textPrimary,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8),
                                                child: Icon(
                                                  Icons.arrow_forward_rounded,
                                                  color: AppColors.textMuted,
                                                  size: 14,
                                                ),
                                              ),
                                              // End Time Button
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () => _pickTime(
                                                      context, day, slotIdx, false),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 8,
                                                            vertical: 8),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.surface,
                                                      borderRadius:
                                                          BorderRadius.circular(6),
                                                      border: Border.all(
                                                          color: AppColors.divider),
                                                    ),
                                                    child: Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(
                                                          Icons.access_time_rounded,
                                                          color: AppColors.info,
                                                          size: 14,
                                                        ),
                                                        const SizedBox(width: 6),
                                                        Text(
                                                          slot['endTime']!,
                                                          style: const TextStyle(
                                                            color: AppColors.textPrimary,
                                                            fontWeight: FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              // Remove Slot Button
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline_rounded,
                                                  color: AppColors.error,
                                                  size: 18,
                                                ),
                                                padding: EdgeInsets.zero,
                                                constraints: const BoxConstraints(),
                                                tooltip: 'Remove Slot',
                                                onPressed: () =>
                                                    _removeSlot(day, slotIdx),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  const SizedBox(height: 10),

                                  // Add Slot Button
                                  OutlinedButton.icon(
                                    onPressed: () => _addSlot(day),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.accent,
                                      side: BorderSide(
                                        color: AppColors.accent.withValues(alpha: 0.5),
                                        style: BorderStyle.solid,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                    ),
                                    icon: const Icon(Icons.add_rounded, size: 16),
                                    label: const Text(
                                      'Add Slot',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.warning.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.warning.withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: const Text(
                                      'Off Duty / Unavailable — No case investigation can be scheduled on this day.',
                                      style: TextStyle(
                                        color: AppColors.warning,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      // ── Fixed Bottom Save Button ──
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.divider)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _saveAvailability,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 20),
            label: Text(
              _isSaving ? 'Saving Schedule...' : 'Save Availability Schedule',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
