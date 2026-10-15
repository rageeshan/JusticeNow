import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../data/repositories/legal_aid_repository.dart';

class ManageAvailabilityScreen extends StatefulWidget {
  const ManageAvailabilityScreen({super.key});

  @override
  State<ManageAvailabilityScreen> createState() => _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  final LegalAidRepository _repo = LegalAidRepository();
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
          'isUnavailable': day == 'Saturday' || day == 'Sunday',
          'slots': day == 'Saturday' || day == 'Sunday'
              ? <Map<String, String>>[]
              : <Map<String, String>>[
                  {'startTime': '09:00 AM', 'endTime': '12:00 PM'},
                  {'startTime': '02:00 PM', 'endTime': '05:00 PM'},
                ],
        }
    };
  }

  Future<void> _fetchAvailability() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final res = await _repo.getLawyerAvailability();
      if (res.isNotEmpty) {
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
      // Keep default schedule if fetch fails
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveAvailability() async {
    setState(() => _isSaving = true);
    try {
      await _repo.updateLawyerAvailability(_schedule);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability schedule saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save availability: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickTimeForSlot(String day, int slotIndex, bool isStart) async {
    final slots = _schedule[day]!['slots'] as List<Map<String, String>>;
    final currentStr = isStart ? slots[slotIndex]['startTime']! : slots[slotIndex]['endTime']!;

    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    try {
      final parts = currentStr.split(' ');
      final timeParts = parts[0].split(':');
      var hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && hour < 12) {
        hour += 12;
      } else if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && hour == 12) {
        hour = 0;
      }
      initial = TimeOfDay(hour: hour, minute: minute);
    } catch (_) {}

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      setState(() {
        final formatted = picked.format(context);
        if (isStart) {
          slots[slotIndex]['startTime'] = formatted;
        } else {
          slots[slotIndex]['endTime'] = formatted;
        }
      });
    }
  }

  void _addSlot(String day) {
    setState(() {
      final slots = _schedule[day]!['slots'] as List<Map<String, String>>;
      slots.add({'startTime': '09:00 AM', 'endTime': '12:00 PM'});
      _schedule[day]!['isUnavailable'] = false;
    });
  }

  void _removeSlot(String day, int index) {
    setState(() {
      final slots = _schedule[day]!['slots'] as List<Map<String, String>>;
      slots.removeAt(index);
    });
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
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Reset/Reload',
            onPressed: _fetchAvailability,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Info banner
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceBlue,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderBlue),
                      boxShadow: const [AppColors.cardShadow],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Define your weekly consultation time slots. Only these slots are shown when scheduling case appointments to prevent double-booking.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Weekly List
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _daysOfWeek.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final day = _daysOfWeek[index];
                        final dayData = _schedule[day]!;
                        final isUnavailable = dayData['isUnavailable'] == true;
                        final slots = (dayData['slots'] as List).cast<Map<String, String>>();

                        return Container(
                          decoration: BoxDecoration(
                            color: isUnavailable ? AppColors.surfaceSubtle : AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isUnavailable
                                  ? AppColors.border
                                  : AppColors.borderBlue,
                              width: isUnavailable ? 1 : 1.2,
                            ),
                            boxShadow: const [AppColors.cardShadow],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Day Header & Unavailable toggle
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: isUnavailable
                                            ? AppColors.surfaceVariant
                                            : AppColors.surfaceBlue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        day.substring(0, 3).toUpperCase(),
                                        style: TextStyle(
                                          color: isUnavailable ? AppColors.textMuted : AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      day,
                                      style: TextStyle(
                                        color: isUnavailable ? AppColors.textMuted : AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        Text(
                                          'Unavailable',
                                          style: TextStyle(
                                            color: isUnavailable ? AppColors.warning : AppColors.textMuted,
                                            fontSize: 12,
                                            fontWeight: isUnavailable ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                        Transform.scale(
                                          scale: 0.8,
                                          child: Switch(
                                            value: isUnavailable,
                                            activeColor: AppColors.warning,
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

                                if (!isUnavailable) ...[
                                  const SizedBox(height: 12),
                                  const Divider(color: AppColors.border, height: 1),
                                  const SizedBox(height: 12),

                                  if (slots.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      child: Text(
                                        'No slots added yet for $day.',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13, fontStyle: FontStyle.italic),
                                      ),
                                    )
                                  else
                                    ...slots.asMap().entries.map((entry) {
                                      final slotIdx = entry.key;
                                      final slot = entry.value;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 10),
                                        child: Row(
                                          children: [
                                            // Start time chip
                                            Expanded(
                                              child: InkWell(
                                                onTap: () => _pickTimeForSlot(day, slotIdx, true),
                                                borderRadius: BorderRadius.circular(10),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surfaceSubtle,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: AppColors.border),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        slot['startTime'] ?? '09:00 AM',
                                                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                                      ),
                                                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8),
                                              child: Text('–', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                                            ),
                                            // End time chip
                                            Expanded(
                                              child: InkWell(
                                                onTap: () => _pickTimeForSlot(day, slotIdx, false),
                                                borderRadius: BorderRadius.circular(10),
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surfaceSubtle,
                                                    borderRadius: BorderRadius.circular(10),
                                                    border: Border.all(color: AppColors.border),
                                                  ),
                                                  child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        slot['endTime'] ?? '12:00 PM',
                                                        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 13),
                                                      ),
                                                      const Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            // Delete slot button
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                              onPressed: () => _removeSlot(day, slotIdx),
                                              tooltip: 'Remove slot',
                                            ),
                                          ],
                                        ),
                                      );
                                    }),

                                  // + Add Slot button
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: TextButton.icon(
                                      onPressed: () => _addSlot(day),
                                      icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                                      label: const Text('+ Add slot', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Marked as Unavailable for consultations.',
                                    style: TextStyle(color: AppColors.textMuted.withValues(alpha: 0.8), fontSize: 12, fontStyle: FontStyle.italic),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Save Button Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(top: BorderSide(color: AppColors.border)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 8,
                          offset: Offset(0, -3),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveAvailability,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.save_rounded),
                        label: Text(
                          _isSaving ? 'Saving Schedule...' : 'Save Availability Schedule',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}