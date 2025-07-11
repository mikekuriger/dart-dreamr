import 'package:flutter/material.dart';
import 'package:dreamr/services/api_service.dart';
import 'package:dreamr/theme/colors.dart';
// import 'dart:developer' as developer;
import 'package:dreamr/constants.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';



class DreamEntryWidget extends StatefulWidget {
  final String? initialText;     // preload text
  final VoidCallback? onSubmitComplete;
  final ValueNotifier<int> refreshTrigger;

  const DreamEntryWidget({
    super.key,
    this.initialText,
    this.onSubmitComplete,
    required this.refreshTrigger,
  });

  @override
  State<DreamEntryWidget> createState() => _DreamEntryWidgetState();
}

class _DreamEntryWidgetState extends State<DreamEntryWidget> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  bool _imageGenerating = false;
  String? _message;
  String? _userName;
  String? _dreamImagePath;
  // bool _suppressAutosave = false;

  // void _refreshFromTrigger() {
  //   // Logic to refresh Dream Entry UI
  //   setState(() {
  //     _message = null;
  //     _controller.clear();
  //     _dreamImagePath = null;
  //   });
  // }

  void _refreshFromTrigger() async {
    final prefs = await SharedPreferences.getInstance();
    final savedText = prefs.getString('draft_text');
    if (savedText != null && savedText.isNotEmpty) {
      setState(() {
        _controller.text = savedText;
      });
    }
  }
  
  // Submit Dream
  Future<void> _submitDream() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _imageGenerating = false;
      _message = null;
      _dreamImagePath = null;
    });

    try {
      final result = await ApiService.submitDream(text);
      final String analysis = result['analysis'];
      final String tone = result['tone'];
      final int dreamId = int.parse(result['dream_id'].toString());

      setState(() {
        final toneLine = (tone.trim().isNotEmpty && tone != 'null')
            ? "\n\nThis dream feels *$tone*."
            : "";

        _message = "Dream Interpretation:\n$analysis$toneLine";
        _imageGenerating = true;
      });

      // Clear saved prefs and other stuff
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('draft_text');
      dreamDataChanged.value = true;
      _controller.clear();
      widget.onSubmitComplete?.call();

      // ⏳ Now generate image in background
      await _generateDreamImage(dreamId);

    } catch (e) {
      // developer.log("Dream submission failed", error: e, name: 'DreamEntry');
      setState(() {
        _message = "Dream submission failed.";
      });

    } finally {
      // developer.log("Image URL received, setting state", name: 'ImageGen');
      setState(() {
        _loading = false;
      });
    }
  }

  // Save Dream Draft
  Future<void> _saveDraft(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = text.trim();

    if (trimmed.isEmpty) {
      await prefs.remove('draft_text');
    } else {
      await prefs.setString('draft_text', trimmed);
    }
  }


  // Generate Image
  Future<void> _generateDreamImage(int dreamId) async {
    try {
      final imagePath = await ApiService.generateDreamImage(dreamId);
      setState(() {
        _dreamImagePath = imagePath;
        _imageGenerating = false;
      });
      
    } catch (e) {
      // print("Failed to generate image: $e");
    }
  }

  @override
  void dispose() {
    widget.refreshTrigger.removeListener(_refreshFromTrigger);
    super.dispose();
  }
  
  @override
  void initState() {
    super.initState();

    _loadDraftText();
    _controller.addListener(() {
      if (_controller.text.trim().isNotEmpty) {
        _saveDraft(_controller.text);
      }
    });

    widget.refreshTrigger.addListener(_refreshFromTrigger);
    _loadUserName();
  }

  void _loadDraftText() async {
    final prefs = await SharedPreferences.getInstance();
    final savedText = prefs.getString('draft_text');
    if (savedText != null && savedText.isNotEmpty) {
      _controller.text = savedText;
    }
  }

  Future<void> _loadUserName() async {
    try {
      final authData = await ApiService.checkAuth();
      if (authData['authenticated'] == true) {
        setState(() {
          _userName = authData['first_name'];
        });
      }
    } catch (e) {
      // print("Failed to load user name: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Hello, ${_userName ?? ""}",
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: Text(
            "Tell me about your dream in as much detail as you remember — characters, settings, emotions, anything that stood out. "
            "After submitting, I will take a moment to analyze your dream and generate a personalized interpretation. "
            "Your dream interpretation takes a few moments, but your dream image will take me a minute or so to create.\n"
            "So go poop while the magic happens ✨",
            // "So sit tight while the magic happens ✨",
            style: TextStyle(
              fontSize: 13,
              color: Colors.white,
            ),
          ),
        ),
  
  // Dream entry field
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          maxLines: 4,
          decoration: const InputDecoration(
            filled: true,
            fillColor: Colors.white,
            hintText: "Describe your dream...",
            border: OutlineInputBorder(),
          ),
        ),

  // Analyze button
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Analyze Button
            SizedBox(
              width: 150,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple600,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.red,
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: (_loading || _imageGenerating) ? null : _submitDream,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_loading && !_imageGenerating)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    if (_loading && !_imageGenerating) const SizedBox(width: 8),
                    Text(
                      _imageGenerating
                          ? "Generating Image"
                          : _loading
                              ? "Analyzing..."
                              : "Analyze",
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8), // gap between buttons

            // Draft / Save Button
        //     SizedBox(
        //       width: 100,
        //       child: ElevatedButton(
        //         style: ElevatedButton.styleFrom(
        //           backgroundColor: AppColors.purple600,
        //           foregroundColor: Colors.white,
        //           disabledBackgroundColor: Colors.red,
        //           disabledForegroundColor: Colors.white,
        //           padding: const EdgeInsets.symmetric(vertical: 12),
        //           textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        //           shape: RoundedRectangleBorder(
        //             borderRadius: BorderRadius.circular(10),
        //           ),
        //         ),
        //         onPressed: (_loading || _imageGenerating) ? null : _saveDraft,
        //         child: const Text("Save Draft"),
        //       ),
        //     ),
          ],
        ),

        if (_message != null)
          Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(
                  data: _message!,
                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                    p: const TextStyle(color: Colors.black87),
                  ),
                ),

                if (_imageGenerating) ...[
                  const SizedBox(height: 12),
                  const Text(
                    "Hang tight — your dream image is being drawn...",
                    style: TextStyle(fontStyle: FontStyle.italic, color: Color.fromARGB(136, 246, 24, 24)),
                  ),
                ],

                if (_dreamImagePath != null && _dreamImagePath!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _dreamImagePath!,
                          width: constraints.maxWidth,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Text("⚠️ Failed to load image."),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
