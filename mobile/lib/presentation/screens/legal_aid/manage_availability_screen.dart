import 'package:flutter/material.dart';

class ManageAvailabilityScreen extends StatefulWidget {
  const ManageAvailabilityScreen({Key? key}) : super(key: key);

  @override
  State<ManageAvailabilityScreen> createState() => _ManageAvailabilityScreenState();
}

class _ManageAvailabilityScreenState extends State<ManageAvailabilityScreen> {
  final List<String> days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  final Set<String> selectedDays = {'Tue'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Manage Availability')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 8),
            const Text('Edit Profile', textAlign: TextAlign.center),
            const SizedBox(height: 24),
            const Text('MANAGE AVAILABILITY SLOTS', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              children: days.map((day) {
                return FilterChip(
                  label: Text(day),
                  selected: selectedDays.contains(day),
                  onSelected: (val) {
                    setState(() {
                      val ? selectedDays.add(day) : selectedDays.remove(day);
                    });
                  },
                );
              }).toList(),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () {},
              child: const Text('SAVE PROFILE CHANGES'),
            )
          ],
        ),
      ),
    );
  }
}