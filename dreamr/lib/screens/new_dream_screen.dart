import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'dashboard_screen.dart';

class NewDreamScreen extends StatefulWidget {
  const NewDreamScreen({Key? key}) : super(key: key);

  @override
  _NewDreamScreenState createState() => _NewDreamScreenState();
}

class _NewDreamScreenState extends State<NewDreamScreen> {
  final _controller = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _aiResponse;

  void _submitDream() async {
    final dreamText = _controller.text.trim();
    if (dreamText.isEmpty) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _aiResponse = null;
    });

    try {
      final analysis = await ApiService.submitDream(dreamText);
      setState(() {
        _aiResponse = analysis;
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Submission failed.";
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _goBackToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("New Dream")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              maxLines: 10,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Describe your dream...',
              ),
            ),
            const SizedBox(height: 12),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submitDream,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Submit"),
            ),
            const SizedBox(height: 20),
            if (_aiResponse != null) ...[
              const Text("AI Analysis:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text(_aiResponse!),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _goBackToDashboard,
                child: const Text("Done"),
              )
            ]
          ],
        ),
      ),
    );
  }
}
