import 'package:flutter/material.dart';
import 'manage_availability_screen.dart';

class CounselDashboardScreen extends StatefulWidget {
  const CounselDashboardScreen({Key? key}) : super(key: key);

  @override
  State<CounselDashboardScreen> createState() => _CounselDashboardScreenState();
}

class _CounselDashboardScreenState extends State<CounselDashboardScreen> {
  bool isAvailable = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Counsel Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const ListTile(
              leading: CircleAvatar(child: Icon(Icons.person)),
              title: Text('Counsel Name', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Verified Partner'),
            ),
            SwitchListTile(
              title: const Text('MY AVAILABILITY STATUS'),
              value: isAvailable,
              onChanged: (val) => setState(() => isAvailable = val),
            ),
            Row(
              children: const [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('03', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('PENDING REQUESTS'),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text('12', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text('ACCEPTED CONSULTATIONS'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('INCOMING CONSULTATION REQUESTS', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () {
                    // Navigate to Requests Screen
                  },
                  child: const Text('View All'),
                )
              ],
            ),
            Card(
              child: ListTile(
                title: const Text('Client Name'),
                subtitle: const Text('Category • Requested date & time\nCase ID: #----'),
                trailing: ElevatedButton(
                  onPressed: () {
                    // Review Request action
                  },
                  child: const Text('Review Request'),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ManageAvailabilityScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Requests'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Calendar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}