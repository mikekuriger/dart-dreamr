import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DreamEntryWidget extends StatefulWidget {
  final VoidCallback onSubmitComplete;

  const DreamEntryWidget({Key? key, required this.onSubmitComplete}) : super(key: key);

  @override
  State<DreamEntryWidget> createState() => _DreamEntryWidgetState();
}

class _DreamEntryWidgetState extends State<DreamEntryWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _submitDream() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _message = "Analyzing your dream...";
    });

    try {
      final analysis = await ApiService.submitDream(text);
      setState(() {
        _message = "AI Response: $analysis";
      });

      _controller.clear();
      widget.onSubmitComplete(); // trigger refresh in parent
    } catch (e) {
      setState(() {
        _message = "Submission failed.";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: "Describe your dream...",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: _loading ? null : _submitDream,
          child: _loading ? const CircularProgressIndicator() : const Text("Submit Dream"),
        ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(_message!, style: const TextStyle(color: Colors.purple)),
          )
      ],
    );
  }
}
