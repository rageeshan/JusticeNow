import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/services/api_service.dart';
import '../../../core/constants/app_constants.dart';
import 'dart:convert';

class ReportIncidentScreen extends ConsumerStatefulWidget {
  const ReportIncidentScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ReportIncidentScreen> createState() => _ReportIncidentScreenState();
}

class _ReportIncidentScreenState extends ConsumerState<ReportIncidentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  String _selectedCategory = 'arbitrary_detention';
  bool _isLoading = false;

  // Mirror of AppConstants.caseCategories — kept local for UI display
  final Map<String, String> _categories = AppConstants.caseCategories;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _submitIncident() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Use the singleton Dio client — auto-attaches Bearer token via _AuthInterceptor
      final dio = ApiService.instance.client;

      final response = await dio.post(
        '/cases',
        data: {
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'category': _selectedCategory,
          // Backend schema: location.address, not top-level 'address'
          'location': {
            'address': _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
          },
          // incidentDate defaults to now on the backend if omitted
        },
      );

      setState(() => _isLoading = false);

      final data = response.data;
      if (data['success'] == true) {
        final caseData = data['data']?['case'] ?? {};
        final refNumber = caseData['referenceNumber'] ?? 'CASE-SUBMITTED';
        _showSuccessDialog(refNumber);
      } else {
        _showSnackBar(data['message'] ?? 'Submission failed');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      // Friendly error: check if it's a 401 so we can hint the user to log in
      final msg = e.toString().contains('401')
          ? 'Please log in before submitting a case.'
          : 'Connection error. Make sure the backend is running.';
      _showSnackBar(msg);
    }
  }

  void _showSuccessDialog(String referenceNumber) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Column(
          children: const [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 60),
            SizedBox(height: 12),
            Text(
              'Incident Recorded!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your incident has been submitted anonymously. Please save this reference code to check case updates:',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.black70),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade300, width: 1.5),
              ),
              child: SelectableText(
                referenceNumber,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _formKey.currentState!.reset();
                _titleController.clear();
                _descriptionController.clear();
                _addressController.clear();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report an Incident'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Incident Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  border: OutlineInputBorder(),
                ),
                items: _categories.entries.map((entry) {
                  return DropdownMenuItem(value: entry.key, child: Text(entry.value));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Incident Details / Description *',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Please enter details' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Location / Address (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _submitIncident,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Submit Incident',
                        style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}