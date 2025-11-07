// screens/dream_gallery_screen.dart
import 'package:flutter/material.dart';
import 'package:dreamr/models/dream.dart';
import 'package:dreamr/services/api_service.dart';
import 'package:dreamr/screens/image_viewer_screen.dart';
import 'package:dreamr/constants.dart';
import 'package:dreamr/widgets/dream_image.dart';
import 'package:dreamr/services/image_store.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mime/mime.dart';
import 'dart:io';
import 'package:dreamr/services/dio_client.dart';



class DreamGalleryScreen extends StatefulWidget {
  final ValueNotifier<int> refreshTrigger;
  const DreamGalleryScreen({super.key, required this.refreshTrigger});

  @override
  State<DreamGalleryScreen> createState() => _DreamGalleryScreenState();
}

class _DreamGalleryScreenState extends State<DreamGalleryScreen> {
  List<Dream> _dreams = [];            // all dreams
  bool _loading = true;
  
  // Map to store share anchor keys for each dream
  final Map<int, GlobalKey> _shareAnchorKeys = {};

  @override
  void initState() {
    super.initState();

    // Initial load
    _loadDreams();

    // Refresh every time index changes
    widget.refreshTrigger.addListener(() {
      _loadDreams(); 
    });

    // Listen for changes to dream data
    dreamDataChanged.addListener(_handleDreamDataChanged);
  }

  void _handleDreamDataChanged() {
    if (dreamDataChanged.value) {
      _loadDreams(); // 👈 Refresh gallery
      dreamDataChanged.value = false;
    }
  }

  @override
  void dispose() {
    dreamDataChanged.removeListener(_handleDreamDataChanged);
    widget.refreshTrigger.removeListener(_loadDreams);  // if you used addListener inline above
    super.dispose();
  }
  
  // Get origin Rect from GlobalKey
  Rect _originFromKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return const Rect.fromLTWH(100, 100, 1, 1); // safe fallback
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || box.size.isEmpty) {
      return const Rect.fromLTWH(100, 100, 1, 1);
    }
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  // Build shareable text content for a dream
  String _buildShareText(Dream dream) {
    final userText = dream.text.trim();
    final summary = dream.summary.trim();
    final parts = <String>[];
    
    if (summary.isNotEmpty) parts.add(summary);
    if (userText.isNotEmpty) parts.add(userText);
    
    return parts.join('\n\n-- Dream Details\n\n');
  }

  // Resolve image file for sharing
  Future<File?> _resolveImageFileForShare(Dream dream) async {
    if (dream.imageFile == null || dream.imageFile!.isEmpty) return null;
    
    // Local-first; download once if missing
    final hit = await ImageStore.localIfExists(dream.id, DreamImageKind.file, dream.imageFile!);
    if (hit != null) return hit;
    
    try {
      return await ImageStore.download(dream.id, DreamImageKind.file, dream.imageFile!, dio: DioClient.dio);
    } catch (_) {
      return null;
    }
  }

  // Share dream image (with optional text)
  Future<void> _shareDreamImage({required Dream dream, required Rect origin, bool includeText = true}) async {
    final f = await _resolveImageFileForShare(dream);
    final shareText = includeText ? _buildShareText(dream) : '';

    if (f == null || !await f.exists()) {
      if (shareText.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(text: shareText, sharePositionOrigin: origin),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image not available to share')),
      );
      return;
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(f.path, mimeType: lookupMimeType(f.path) ?? 'image/jpeg')],
        text: shareText.isNotEmpty ? shareText : null,
        sharePositionOrigin: origin, // required on iPad/macOS
      ),
    );
  }

  Future<void> _loadDreams() async {
    setState(() {
      _loading = true;
    });

    final dreams = await ApiService.fetchGallery();

    setState(() {
      _dreams = dreams;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        itemCount: _dreams.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 24,
          childAspectRatio: 0.8,
        ),
        itemBuilder: (context, index) {
          final dream = _dreams[index];
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ImageViewerScreen(
                          dreams: _dreams,
                          initialIndex: index,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                      child: DreamImage(
                        dreamId: dream.id,
                        url: dream.imageFile ?? '',
                        kind: DreamImageKind.file,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: Container(
                          color: Colors.grey[300],
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        error: Container(
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image, size: 40)),
                        ),
                      ),
                    // child: Image.network(
                    //   dream.imageFile ?? '',
                    //   width: double.infinity,
                    //   fit: BoxFit.cover,
                    //   errorBuilder: (context, error, stackTrace) =>
                    //       const Center(child: Icon(Icons.broken_image, size: 40)),
                    // ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      dream.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                  // Share image button
                  Container(
                    key: _shareAnchorKeys[dream.id] ??= GlobalKey(),
                    padding: const EdgeInsets.all(4),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      tooltip: 'Share image',
                      onPressed: () {
                        final origin = _originFromKey(_shareAnchorKeys[dream.id]!);
                        _shareDreamImage(dream: dream, includeText: false, origin: origin);
                      },
                      icon: const Icon(
                        Icons.share,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
