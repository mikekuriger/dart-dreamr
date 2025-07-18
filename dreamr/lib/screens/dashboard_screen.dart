import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:dreamr/services/api_service.dart';
import 'package:dreamr/constants.dart';
import 'package:dreamr/theme/colors.dart';

class DashboardScreen extends StatefulWidget {
  final ValueNotifier<int> refreshTrigger;
  const DashboardScreen({super.key, required this.refreshTrigger});

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
    });

    try {
      final result = await ApiService.submitDream(text);
      final analysis = result['analysis'] as String;
      final tone = result['tone'] as String;
      final dreamId = int.parse(result['dream_id'].toString());

      setState(() {
        final toneLine = (tone.trim().isNotEmpty && tone != 'null')
            ? "\n\nThis dream feels *$tone*."
            : "";
        _message = "Dream Interpretation:\n$analysis$toneLine";
        _imageGenerating = true;
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('draft_text');
      dreamDataChanged.value = true;
      _controller.clear();

      await _generateDreamImage(dreamId);
    } catch (e) {
      setState(() {
        _message = "Dream submission failed.";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _generateDreamImage(int dreamId) async {
    try {
      final imagePath = await ApiService.generateDreamImage(dreamId);
      setState(() {
        _dreamImagePath = imagePath;
        _imageGenerating = false;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 👋 Greeting
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Hello, ${_userName ?? ""}",
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  "Tell me about your dream in as much detail as you remember — characters, settings, emotions, anything that stood out. "
                  "After submitting, I will analyze your dream and generate a personalized interpretation. "
                  "Your dream interpretation takes a few moments, but your dream image will take me a minute or so to create.\n"
                  "So sit tight while the magic happens ✨",
                  style: TextStyle(fontSize: 13, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),

              // ✏️ Entry area
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.multiline,
                          maxLines: null,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            hintText: "Describe your dream...",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔮 Analyze button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
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
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 🖼️ Results area
              if (_message != null)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Container(
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
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}