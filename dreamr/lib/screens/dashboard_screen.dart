// screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dreamr/services/api_service.dart';
import 'package:dreamr/constants.dart';
import 'package:dreamr/theme/colors.dart';
import 'package:dreamr/models/dream.dart';
import 'package:dreamr/services/image_store.dart';
import 'package:dreamr/services/dio_client.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mime/mime.dart';
import 'dart:io';


class DashboardScreen extends StatefulWidget {
  final ValueNotifier<int> refreshTrigger;
  final ValueChanged<bool>? onAnalyzingChange;

  const DashboardScreen({
    super.key,
    required this.refreshTrigger,
    this.onAnalyzingChange,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _controller = TextEditingController();
  final AudioPlayer _player = AudioPlayer();
  
  String? _userName;
  bool _enableAudio = false;
  bool _hasPlayedIntroAudio = false;

  bool _loading = false;
  bool _imageGenerating = false;
  String? _message;
  String? _dreamImagePath;
  String? _lastDreamText;
  int? _lastDreamId;

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _loadDraftText();

    _controller.addListener(() {
      if (_controller.text.trim().isNotEmpty) {
        _saveDraft(_controller.text);
      }
    });

    widget.refreshTrigger.addListener(_refreshFromTrigger);
  }

  @override
  void dispose() {
    _player.dispose();
    widget.refreshTrigger.removeListener(_refreshFromTrigger);
    super.dispose();
  }

  void _refreshFromTrigger() async {
    // clear old results
    setState(() {
      _message = null;
      _dreamImagePath = null;
    });

    _loadUserName();
    final prefs = await SharedPreferences.getInstance();
    final savedText = prefs.getString('draft_text');
    if (savedText != null && savedText.isNotEmpty) {
      setState(() {
        _controller.text = savedText;
      });
    }
  }

  Future<void> _playIntroAudioOnce() async {
    if (_hasPlayedIntroAudio || !_enableAudio) return;
    _hasPlayedIntroAudio = true;
    try {
      await _player.setAsset('assets/sound/tell_me_about.mp3');
      await _player.play();
    } catch (_) {}
  }

  Future<void> _loadUserName() async {
    try {
      final authData = await ApiService.checkAuth();
      if (authData['authenticated'] == true) {
        setState(() {
          _userName = authData['first_name'];
          _enableAudio = authData['enable_audio'] == true || authData['enable_audio'] == '1';
        });
        _playIntroAudioOnce();
      }
    } catch (_) {}
  }

  Future<void> _loadDraftText() async {
    final prefs = await SharedPreferences.getInstance();
    final savedText = prefs.getString('draft_text');
    if (savedText != null && savedText.isNotEmpty) {
      _controller.text = savedText;
    }
  }

  Future<void> _saveDraft(String text) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      await prefs.remove('draft_text');
    } else {
      await prefs.setString('draft_text', trimmed);
    }
  }

  Future<void> _submitDream() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _loading = true;
      _imageGenerating = false;
      _message = null;
      _dreamImagePath = null;
      _lastDreamText = text;
    });

    widget.onAnalyzingChange?.call(true); // 👈 disable/hide nav

    try {
      final result = await ApiService.submitDream(text);
      final analysis = result['analysis'] as String;
      final dreamId = int.parse(result['dream_id'].toString());
      setState(() { _lastDreamId = dreamId; });

      final shouldGen = (result['should_generate_image'] as bool?) ?? false;
      final isQuestion  = result['is_question'] == true; // optional: for copy/UX only
      final String? tone = (result['tone'] is String) ? (result['tone'] as String).trim() : null;
      final String? placeholderUrl = result['image_url'] as String?;

      // Build message: never show tone for questions
      final toneLine = (!isQuestion && tone != null && tone.isNotEmpty)
          ? "\n\nThis dream feels *$tone*."
          : "";

      setState(() {
        _message = "$analysis$toneLine";
        _imageGenerating = shouldGen;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('draft_text');
      dreamDataChanged.value = true;
      _controller.clear();

      if (shouldGen) {
        await _generateDreamImage(dreamId);
      } else {
        if (placeholderUrl != null && placeholderUrl.isNotEmpty) {
          setState(() => _dreamImagePath = placeholderUrl);
        }
        // ensure spinner is off
        setState(() => _imageGenerating = false);
      }

    } catch (e) {
      setState(() {
        _message = "Dream submission failed.";
        _imageGenerating = false; // make sure spinner is off on error
      });
    } finally {
      setState(() {
        _loading = false;
      });
      widget.onAnalyzingChange?.call(false); 
    }
  }

  Future<void> _generateDreamImage(int dreamId) async {
    try {
      final imagePath = await ApiService.generateDreamImage(dreamId);
      setState(() {
        _dreamImagePath = imagePath;
        _imageGenerating = false;
      });
    } catch (_) {
      setState(() => _imageGenerating = false);
    }
  }

// sharing
// Anchor key for share button
  final GlobalKey _shareAnchorKey = GlobalKey();

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

// Build shareable text content
  String _buildShareText() {
    final userText   = (_lastDreamText ?? '').trim();     // what user typed
    final analysisMd = (_message ?? '').trim();     // AI analysis (markdown)
    final parts = <String>[];
    if (userText.isNotEmpty) parts.add(userText);
    if (analysisMd.isNotEmpty) parts.add(analysisMd);
    return parts.join('\n\n-- Dreamr ✨ Analysis\n\n');               // separator
  }

// Resolve image file for sharing
  Future<File?> _resolveImageFileForShare() async {
    if (_dreamImagePath == null || _dreamImagePath!.isEmpty) return null;
    final id = _lastDreamId;
    if (id == null) return null;

    // Local-first; download once if missing
    final hit = await ImageStore.localIfExists(id, DreamImageKind.file, _dreamImagePath!);
    if (hit != null) return hit;
    try {
      return await ImageStore.download(id, DreamImageKind.file, _dreamImagePath!, dio: DioClient.dio);
    } catch (_) {
      return null;
    }
  }

// Share dream image (with optional text)
  Future<void> _shareDreamImage({required Rect origin, bool includeText = true}) async {
    final f = await _resolveImageFileForShare();
    final shareText = includeText ? _buildShareText() : '';

    if (f == null || !await f.exists()) {
      if (shareText.isNotEmpty) {
        await SharePlus.instance.share(
          ShareParams(text: shareText, sharePositionOrigin: origin),
        );
        return;
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to share yet')),
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



  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👋 Greeting
                Text(
                  "Hello, ${_userName ?? ""}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                // 📜 Intro
                const Text(
                  "Tell me about your dream in as much detail as you remember — characters, settings, emotions, anything that stood out. "
                  "After submitting, I will analyze your dream and generate a personalized interpretation. "
                  "Your dream interpretation takes a few moments, but your dream image will take me a minute or so to create.\n"
                  "So sit tight while the magic happens ✨",
                  style: TextStyle(fontSize: 13, color: Colors.white),
                ),
                const SizedBox(height: 16),

                // ✏️ Dream entry (locked while analyzing)
                TextField(
                  enabled: !_loading && !_imageGenerating, // ✅ disable typing while analyzing
                  controller: _controller,
                  keyboardType: TextInputType.multiline,
                  minLines: 9,
                  maxLines: null,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                  decoration: const InputDecoration(
                    hintText: "Describe your dream...",
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                // 🔮 Analyze button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple600,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.purple600.withValues(alpha: 0.5),
                      disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      overlayColor: Colors.white.withValues(alpha: 0.1),
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
                        if (_loading || _imageGenerating)
                          const SizedBox(width: 8),
                        Text(
                          _imageGenerating
                              ? "Generating Image"
                              : _loading
                                  ? "Analyzing..."
                                  : "Analyze",
                        ),
                      ],
                    ),
                  ),
                ),

                // 🖼️ Results
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
                            style: TextStyle(
                              fontStyle: FontStyle.italic,
                              color: Color.fromARGB(136, 246, 24, 24),
                            ),
                          ),
                        ],
                        if (_dreamImagePath != null && _dreamImagePath!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: _dreamImagePath!,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              placeholder: (context, url) =>
                                  const Center(child: CircularProgressIndicator()),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.broken_image, size: 48),
                            ),
                          ),
              // Share Dream
                          // Row(
                          //   children: [
                          //     ElevatedButton.icon(
                          //       onPressed: () => _shareDreamImage(includeText: false),
                          //       icon: const Icon(Icons.share, size: 16),
                          //       label: const Text('Share Image'),
                          //       style: ElevatedButton.styleFrom(
                          //         backgroundColor: Color.fromARGB(255, 75, 3, 143),
                          //         foregroundColor: Colors.white,
                          //         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          //         minimumSize: const Size(0, 0),
                          //         tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          //         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          //         textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          //         elevation: 0,
                          //       ),
                          //     ),
                          //     PopupMenuButton<String>(
                          //       icon: const Icon(Icons.share),
                          //       onSelected: (v) => _shareDreamImage(includeText: v == 'with_text'),
                          //       itemBuilder: (_) => const [
                          //         PopupMenuItem(value: 'image_only', child: Text('Share image')),
                          //         PopupMenuItem(value: 'with_text',  child: Text('Share image + dream')),
                          //       ],
                          //     ),
                          //   ],
                          // ),
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: PopupMenuButton<String>(
                              padding: EdgeInsets.zero,
                              tooltip: 'Share ✨',
                              offset: const Offset(0, 32),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              onSelected: (v) {
                                final origin = _originFromKey(_shareAnchorKey);
                                _shareDreamImage(includeText: v == 'with_text', origin: origin);
                              },
                              itemBuilder: (ctx) => const [
                                PopupMenuItem(value: 'image_only', child: Text('Share image')),
                                PopupMenuItem(value: 'with_text',  child: Text('Share image + dream')),
                              ],
                              // Custom trigger: icon + text
                              child: Container(
                                key: _shareAnchorKey,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color.fromARGB(255, 75, 3, 143), // match your button color
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.share, size: 16, color: Colors.white),
                                    SizedBox(width: 6),
                                    Text('Share ✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    SizedBox(width: 2),
                                    // Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}