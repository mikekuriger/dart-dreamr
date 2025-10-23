// screens/image_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:dreamr/models/dream.dart';
import 'package:dreamr/widgets/dream_image.dart';
import 'package:dreamr/services/image_store.dart';

class ImageViewerScreen extends StatefulWidget {
  final List<Dream> dreams;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.dreams,
    required this.initialIndex,
  });

  @override
  State<ImageViewerScreen> createState() => _ImageViewerScreenState();
}

class _ImageViewerScreenState extends State<ImageViewerScreen> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.dreams.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          final dream = widget.dreams[index];
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                InteractiveViewer(
                  child: DreamImage(
                    dreamId: dream.id,
                    url: dream.imageFile,
                    kind: DreamImageKind.file,
                    fit: BoxFit.contain,
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height * 0.6,
                    placeholder: const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: const Center(
                      child: Icon(Icons.broken_image, size: 40, color: Colors.white),
                    ),
                  ),
                  // child: Image.network(
                  //   dream.imageFile ?? '',
                  //   fit: BoxFit.contain,
                  //   errorBuilder: (context, error, stackTrace) =>
                  //       const Center(child: Icon(Icons.broken_image, size: 40, color: Colors.white)),
                  // ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    dream.summary,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32), // Add bottom padding so text doesn’t hit edge
              ],
            ),
          );
        },
      ),
    );
  }
}
