import 'package:flutter/material.dart';
import 'counsel_login_screen.dart';

class CounselRegistrationScreen extends StatefulWidget {
  const CounselRegistrationScreen({Key? key}) : super(key: key);

  @override
  State<CounselRegistrationScreen> createState() => _CounselRegistrationScreenState();
}

class _CounselRegistrationScreenState extends State<CounselRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LAWYER / LEGAL AID REGISTRATION')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Join JusticeNow Legal Assistance Network', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 16),
              TextFormField(decoration: const InputDecoration(labelText: 'FULL NAME', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(decoration: const InputDecoration(labelText: 'EMAIL ADDRESS', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(decoration: const InputDecoration(labelText: 'SPECIALIZATION / PRACTICE AREAS', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'PRIMARY LOCATION / DISTRICT', border: OutlineInputBorder()),
                items: const [DropdownMenuItem(value: 'colombo', child: Text('Colombo'))],
                onChanged: (val) {},
              ),
              const SizedBox(height: 12),
              TextFormField(decoration: const InputDecoration(labelText: 'NGO ALIGNMENT / BAR ID', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextFormField(obscureText: true, decoration: const InputDecoration(labelText: 'CREATE PASSWORD', border: OutlineInputBorder())),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const CounselLoginScreen()),
                  );
                },
                child: const Text('SUBMIT FOR VERIFICATION'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}