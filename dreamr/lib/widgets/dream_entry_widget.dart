import 'package:flutter/material.dart';
import 'package:dreamr/services/api_service.dart';
import 'package:dreamr/theme/colors.dart';
import 'dart:developer' as developer;


class DreamEntryWidget extends StatefulWidget {
  final VoidCallback onSubmitComplete;

  const DreamEntryWidget({Key? key, required this.onSubmitComplete}) : super(key: key);

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
        _message = "Dream Interpretation:\n$analysis\n\nThis dream feels *$tone*.";
        _imageGenerating = true;
        developer.log("_imageGenerating set to TRUE", name: 'ButtonState');

      });

      _controller.clear();
      widget.onSubmitComplete();

      // ⏳ Now generate image in background
      await _generateDreamImage(dreamId);

    } catch (e) {
      developer.log("Dream submission failed", error: e, name: 'DreamEntry');
      setState(() {
        _message = "Dream submission failed.";
      });

    } finally {
      developer.log("Image URL received, setting state", name: 'ImageGen');
      setState(() {
        _loading = false;
      });
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
      
      developer.log("Image generated: $imagePath", name: 'ImageGen');

      // Optionally show image or update the UI
    } catch (e) {
      developer.log("Image generation failed", error: e, name: 'ImageGen');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserName();
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
          "Hello, ${_userName ?? "Sleepyhead"}",
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
            "So sit tight while the magic happens ✨",
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
              width: 130,
              child: Builder(
                builder: (context) {
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: (_loading || _imageGenerating) ? null : _submitDream,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_loading || _imageGenerating)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                        if (_loading || _imageGenerating) const SizedBox(width: 8),
                        Text(
                          _imageGenerating
                              ? "Generating..."
                              : _loading
                                  ? "Analyzing..."
                                  : "Analyze",
                        )
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),

            // Save Button
            SizedBox(
              width: 120,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: (_loading || _imageGenerating) ? null : _submitDream,
                child: const Text("Save"),
              ),
            ),
          ],
        ),


        // ElevatedButton(
        //   style: ElevatedButton.styleFrom(
        //     backgroundColor: AppColors.purple600, // Button background
        //     foregroundColor: Colors.white,  // Text (and spinner) color
        //     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
        //     textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        //     shape: RoundedRectangleBorder(
        //       borderRadius: BorderRadius.circular(8), // ← adjust this value
        //     ),
        //   ),
        //   onPressed: (_loading || _imageGenerating) ? null : _submitDream,
        //   child: Row(
        //     mainAxisSize: MainAxisSize.min,
        //     children: [
        //       if (_loading || _imageGenerating)
        //         const SizedBox(
        //           width: 18,
        //           height: 18,
        //           child: CircularProgressIndicator(
        //             strokeWidth: 2,
        //             color: Colors.white,
        //           ),
        //         ),
        //       if (_loading || _imageGenerating) const SizedBox(width: 8),
        //       Text(
        //         _loading
        //             ? "Analyzing Dream..."
        //             : _imageGenerating
        //                 ? "Generating Dream Image..."
        //                 : "Submit Dream",
        //       ),
        //     ],
        //   ),
        // ),
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
                Text(
                  _message!,
                  style: const TextStyle(color: Colors.black87),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _dreamImagePath!,
                      height: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Text("⚠️ Failed to load image."),
                    ),
                  ),
                ],
              ],
            ),
          ),
        // if (_message != null)
        //   Container(
        //     margin: const EdgeInsets.only(top: 12),
        //     padding: const EdgeInsets.all(12),
        //     decoration: BoxDecoration(
        //       color: Colors.purple.shade50,
        //       borderRadius: BorderRadius.circular(12),
        //     ),
        //     child: Text(
        //       _message!,
        //       style: const TextStyle(color: Colors.black87),
        //     ),
        //   ),

        //   if (_dreamImagePath != null)
        //   Padding(
        //     padding: const EdgeInsets.only(top: 12),
        //     child: Image.network(
        //       _dreamImagePath!,
        //       height: 300,
        //       fit: BoxFit.cover,
        //     ),
        //   ),
      ],
    );
  }
}
