import 'package:flutter/material.dart';
import 'counsel_dashboard_screen.dart';
import 'registration_screen.dart';

class CounselLoginScreen extends StatelessWidget {
  const CounselLoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.gavel, size: 64),
            const SizedBox(height: 16),
            const Text('JUSTICENOW', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('COUNSEL PORTAL', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            TextField(decoration: const InputDecoration(labelText: 'EMAIL OR BAR ID', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(obscureText: true, decoration: const InputDecoration(labelText: 'PASSWORD', border: OutlineInputBorder())),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const CounselDashboardScreen()),
                );
              },
              child: const Text('LOGIN'),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const CounselRegistrationScreen()));
              },
              child: const Text("Don't have a counsel account? Register Here"),
            )
          ],
        ),
      ),
    );
  }
}