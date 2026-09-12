import 'package:flutter/material.dart';
import 'request_details_screen.dart';

class ConsultationRequestsScreen extends StatefulWidget {
  const ConsultationRequestsScreen({Key? key}) : super(key: key);

  @override
  State<ConsultationRequestsScreen> createState() => _ConsultationRequestsScreenState();
}

class _ConsultationRequestsScreenState extends State<ConsultationRequestsScreen> {
  String selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consultation Requests')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['All (3)', 'Pending', 'Accepted', 'Completed'].map((filter) {
                return ChoiceChip(
                  label: Text(filter),
                  selected: selectedFilter == filter,
                  onSelected: (val) => setState(() => selectedFilter = filter),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Request from S. Silva (Citizen)', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(40)),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const RequestDetailsScreen()));
                      },
                      child: const Text('View & Process'),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}