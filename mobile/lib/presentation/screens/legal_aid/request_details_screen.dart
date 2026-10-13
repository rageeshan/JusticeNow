import 'package:flutter/material.dart';

class RequestDetailsScreen extends StatefulWidget {
  const RequestDetailsScreen({Key? key}) : super(key: key);

  @override
  State<RequestDetailsScreen> createState() => _RequestDetailsScreenState();
}

class _RequestDetailsScreenState extends State<RequestDetailsScreen> {
  bool isTranslated = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Text('Request from S. Silva (Citizen)\nStatus: ACTION REQ', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            SwitchListTile(
              title: const Text('Translation EN=SI=TA'),
              value: isTranslated,
              onChanged: (val) => setState(() => isTranslated = val),
            ),
            const SizedBox(height: 8),
            const Text('CASE NOTES / DESCRIPTION', style: TextStyle(fontWeight: FontWeight.bold)),
            const TextField(
              maxLines: 4,
              decoration: InputDecoration(border: OutlineInputBorder(), hintText: 'Case details text...'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black, minimumSize: const Size.fromHeight(45)),
              onPressed: () {},
              child: const Text('ACCEPT APPOINTMENT', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Reschedule Slot'))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: () {}, child: const Text('Share Resource'))),
              ],
            ),
            TextButton(onPressed: () {}, child: const Text('Reject Request', style: TextStyle(color: Colors.red)))
          ],
        ),
      ),
    );
  }
}