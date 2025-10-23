// widgets/dream_journal_widget.dart
import 'package:dreamr/theme/colors.dart';
import 'package:flutter/material.dart';
import 'package:dreamr/models/dream.dart';
import 'package:dreamr/services/api_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:dreamr/services/image_store.dart';
import 'package:dreamr/services/dio_client.dart';



class DreamJournalWidget extends StatefulWidget { 
  final VoidCallback? onDreamsLoaded;

  const DreamJournalWidget({
    super.key,
    this.onDreamsLoaded,
  });

  @override
  State<DreamJournalWidget> createState() => DreamJournalWidgetState();
}

class ToneStyle {
  final Color background;
  final Color text;
  const ToneStyle(this.background, this.text);
}

class NotesSheet extends StatefulWidget {
  final int dreamId;
  const NotesSheet({super.key, required this.dreamId});

  @override
  State<NotesSheet> createState() => _NotesSheetState();
}

class _NotesSheetState extends State<NotesSheet> {
  final _controller = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  String? _lastSeenIso;
  String? _error;
  Map<String, dynamic>? _serverCopy;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getDreamNotes(widget.dreamId);
      if (!mounted) return;
      _controller.text = (data['notes'] as String?) ?? '';
      _lastSeenIso = data['notes_updated_at'] as String?;
    } catch (_) {
      if (!mounted) return;
      _error = 'Failed to load notes';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save({bool overwrite = false}) async {
    setState(() { _saving = true; _error = null; _serverCopy = null; });
    try {
      final res = await ApiService.saveDreamNotes(
        dreamId: widget.dreamId,
        notes: _controller.text,
        lastSeen: overwrite ? null : _lastSeenIso,
      );
      if (!mounted) return;
      _lastSeenIso = res['notes_updated_at'] as String?;
      Navigator.of(context).pop(true); // close sheet
      return;
    } on NotesTooLarge {
      if (mounted) setState(() => _error = 'Keep it under 8000 characters.');
    } on NotesConflict catch (c) {
      if (!mounted) return;
      _serverCopy = c.current;
      setState(() {}); // show conflict UI

      final action = await showDialog<String>(
        context: context,
        builder: (dctx) => AlertDialog(
          title: const Text('Notes changed elsewhere'),
          content: const Text('Load the latest from server or overwrite yours?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dctx, 'load'), child: const Text('Load theirs')),
            TextButton(onPressed: () => Navigator.pop(dctx, 'overwrite'), child: const Text('Overwrite')),
            TextButton(onPressed: () => Navigator.pop(dctx, 'cancel'), child: const Text('Cancel')),
          ],
        ),
      );
      if (!mounted) return;

      if (action == 'load' && _serverCopy != null) {
        _controller.text = (_serverCopy!['notes'] as String?) ?? '';
        _lastSeenIso = _serverCopy!['notes_updated_at'] as String?;
        setState(() => _serverCopy = null);
      } else if (action == 'overwrite') {
        await _save(overwrite: true); // will pop
        return;
      }
    } on NotesHttp {
      if (mounted) setState(() => _error = 'Save failed');
    }
    if (mounted) setState(() => _saving = false); // only if we didn’t pop
  }

  Future<void> _clear() async {
    setState(() { _saving = true; _error = null; _serverCopy = null; });
    try {
      final res = await ApiService.saveDreamNotes(
        dreamId: widget.dreamId,
        notes: null,
        lastSeen: _lastSeenIso,
      );
      if (!mounted) return;
      _lastSeenIso = res['notes_updated_at'] as String?;
      _controller.clear();
      Navigator.of(context).pop(true);
      return;
    } on NotesConflict catch (c) {
      if (!mounted) return;
      _serverCopy = c.current;
      setState(() {});
      final action = await showDialog<String>(
        context: context,
        builder: (dctx) => AlertDialog(
          title: const Text('Notes changed elsewhere'),
          content: const Text('Load latest or overwrite with clear?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dctx, 'load'), child: const Text('Load theirs')),
            TextButton(onPressed: () => Navigator.pop(dctx, 'overwrite'), child: const Text('Overwrite')),
            TextButton(onPressed: () => Navigator.pop(dctx, 'cancel'), child: const Text('Cancel')),
          ],
        ),
      );
      if (!mounted) return;

      if (action == 'load' && _serverCopy != null) {
        _controller.text = (_serverCopy!['notes'] as String?) ?? '';
        _lastSeenIso = _serverCopy!['notes_updated_at'] as String?;
        setState(() => _serverCopy = null);
      } else if (action == 'overwrite') {
        await ApiService.saveDreamNotes(dreamId: widget.dreamId, notes: null, lastSeen: null);
        if (mounted) Navigator.of(context).pop(true);
        return;
      }
    } on NotesHttp {
      if (mounted) setState(() => _error = 'Failed to clear');
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(child: Text('Notes (private)',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: Colors.white))),
              if (_saving) const SizedBox(height: 16, width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2)),
            ]),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              TextField(
                controller: _controller,
                maxLines: null,
                maxLength: 8000,
                decoration: const InputDecoration(
                  hintText: 'Jot down anything about this dream…',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                style: const TextStyle(color: Colors.black),
                enabled: !_saving,
              ),
              const SizedBox(height: 8),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              Row(children: [
                ElevatedButton(onPressed: _saving ? null : () => _save(overwrite: false), child: const Text('Save')),
                const SizedBox(width: 8),
                TextButton(onPressed: _saving ? null : () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                const Spacer(),
                TextButton(onPressed: _saving ? null : _clear, child: const Text('Clear')),
              ]),
              if (_lastSeenIso != null) ...[
                const SizedBox(height: 6),
                Text('Last edited: $_lastSeenIso',
                    style: const TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}


class DreamJournalWidgetState extends State<DreamJournalWidget> {
  
  List<Dream> _dreams = [];
  List<Dream> getDreams() => _dreams;

  final Map<int, bool> _expanded = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDreams();
  }

  
  ToneStyle _getToneStyle(String tone) {
    final t = tone.toLowerCase().trim();
    switch (t) {
      case 'peaceful / gentle':
        return ToneStyle(Colors.blue.shade100, Colors.black87);
      case 'epic / heroic':
        return ToneStyle(Colors.orange.shade100, Colors.black87);
      case 'whimsical / surreal':
        return ToneStyle(Colors.purple.shade100, Colors.black87);
      case 'nightmarish / dark':
        // return ToneStyle(Colors.black, Colors.red.shade500);  // 👈 spooky red
        return ToneStyle(Colors.grey.shade900, Colors.orange.shade200);  // 👈 spooky red
      case 'romantic / nostalgic':
        return ToneStyle(Colors.pink.shade100, Colors.black87);
      case 'ancient / mythic':
        return ToneStyle(Colors.brown.shade100, Colors.black87);
      case 'futuristic / uncanny':
        return ToneStyle(Colors.teal.shade100, Colors.black87);
      case 'elegant / ornate':
        return ToneStyle(Colors.indigo.shade100, Colors.black87);
      default:
        return ToneStyle(Colors.grey.shade100, Colors.black87);
    }
  }

  // Tone symbol helper 
  String toneSymbol(String tone) {
    final t = tone.toLowerCase();
    if (t.contains('peaceful')) return '☁️';             // soft cloud
    if (t.contains('epic')) return '⚔️';                 // sword/courage
    if (t.contains('whimsical')) return '✨';            // stars
    if (t.contains('nightmarish')) return '🕷️';          // spider
    if (t.contains('romantic')) return '🩷';             // flowers
    if (t.contains('ancient')) return '⚱️';              // urn / ancient relic
    if (t.contains('futuristic')) return '🔮';           // crystal ball
    // if (t.contains('elegant')) return '༻❁༺';           // ornate flower
    if (t.contains('elegant')) return '••࿐••';           // ornate flower
    return '✨';                                         // default separator
  }

  Future<void> _loadDreams() async {
    try {
      final dreams = await ApiService.fetchDreams();
      setState(() {
        _dreams = dreams;
        _loading = false;
      });
      widget.onDreamsLoaded?.call();
    } catch (e) {
      // print("❌ Failed to fetch dreams: $e");
      setState(() {
        _loading = false;
      });
    }
  }

  void refresh() {
    setState(() => _loading = true);
    _loadDreams();
  }

  Future<void> _openNotesEditor(int dreamId) async {
    final changed = await showModalBottomSheet<bool>(
    // await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black87,
      builder: (_) => NotesSheet(dreamId: dreamId),
    );

    if (changed == true && mounted) {
      // Pull latest notes from server and update just this dream
      final data  = await ApiService.getDreamNotes(dreamId);
      final notes = (data['notes'] as String?)?.trim() ?? "";

      setState(() {
        final i = _dreams.indexWhere((d) => d.id == dreamId);
        if (i != -1) {
          _dreams[i] = _dreams[i].copyWith(notes: notes);
        }
      });
    }
  }

    // Drop-in helper with fallback
    Widget netImageWithFallback(
    String? url, {
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? radius,
  }) {
    final widget = (url == null || url.isEmpty)
        ? Image.asset('assets/images/missing.png', width: width, height: height, fit: fit)
        : Image.network(
            url,
            width: width,
            height: height,
            fit: fit,
            // Show placeholder while loading
            loadingBuilder: (ctx, child, prog) =>
                prog == null ? child : Image.asset('assets/images/missing.png', width: width, height: height, fit: fit),
            // Show placeholder on 404/any error
            errorBuilder: (ctx, err, stack) =>
                Image.asset('assets/images/missing.png', width: width, height: height, fit: fit),
          );

    if (radius != null) {
      return ClipRRect(borderRadius: radius, child: widget);
    }
    return widget;
  }

  // Local-first image with same ergonomics as netImageWithFallback
  Widget localFirstImage({
    required int dreamId,
    required String? url,
    required DreamImageKind kind, // DreamImageKind.tile or DreamImageKind.file
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? radius,
  }) {
    Widget buildPlaceholder() =>
        Image.asset('assets/images/missing.png', width: width, height: height, fit: fit);

    return FutureBuilder<File?>(
      future: () async {
        if (url == null || url.isEmpty) return null;

        // 1) Try local
        final hit = await ImageStore.localIfExists(dreamId, kind, url);
        if (hit != null) return hit;

        // 2) Download once, then it lives on disk
        try {
          final f = await ImageStore.download(dreamId, kind, url, dio: DioClient.dio);
          return f;
        } catch (_) {
          return null;
        }
      }(),
      builder: (ctx, snap) {
        final file = snap.data;
        final w = (file != null)
            ? Image.file(file, width: width, height: height, fit: fit)
            : buildPlaceholder();

        if (radius != null) {
          return ClipRRect(borderRadius: radius, child: w);
        }
        return w;
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_dreams.isEmpty) return const Text("Your Dreams will appear here...");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0), // remove side gap
      child: ListView.builder(
        padding: EdgeInsets.zero, 
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _dreams.length,
        itemBuilder: (context, index) {
          final dream = _dreams[index];
          final isExpanded = _expanded[dream.id] ?? false;
          final toneStyle = _getToneStyle(dream.tone);

          final formattedDate = DateFormat('EEE, MMM d, y h:mm a').format(dream.createdAt.toLocal());

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3), // space between cards
            child: Container(
              width: double.infinity, // full width
              padding: const EdgeInsets.all(8), // inner padding inside the white box
              decoration: BoxDecoration(
                color: toneStyle.background,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _expanded[dream.id] = !isExpanded;
                      });
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (dream.imageTile != null && dream.imageTile!.isNotEmpty)
                          localFirstImage(
                            dreamId: dream.id,
                            url: dream.imageTile,
                            kind: DreamImageKind.tile,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            radius: BorderRadius.circular(4),
                          ),
                        // if (dream.imageTile != null && dream.imageTile!.isNotEmpty)
                        //   netImageWithFallback(
                        //     dream.imageTile,
                        //     width: 48,
                        //     height: 48,
                        //     fit: BoxFit.cover,
                        //     radius: BorderRadius.circular(4),
                        //   ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedDate,
                                style: TextStyle(fontSize: 12,color: toneStyle.text,),
                              ),
                              Text(
                                dream.summary,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,color: toneStyle.text,),
                              ),
                              Text(
                                dream.tone,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontStyle: FontStyle.italic,
                                  color: toneStyle.text,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
// Expanded content
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: isExpanded
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: toneStyle.text.withValues(alpha: 0.25),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      toneSymbol(dream.tone), // 🕷️, 🌸, ☁️, etc.
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: toneStyle.text.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: toneStyle.text.withValues(alpha: 0.25),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),

                              // Dream Text Header
                              Text(
                                "My Dream:",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: toneStyle.text),
                              ),

                              // Dream Text
                              if (dream.text.isNotEmpty) ...[
                                SelectableText(
                                  dream.text,
                                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: toneStyle.text),
                                ),
                                const SizedBox(height: 10),
                              ],

                              // Dream Image
                                if (dream.imageFile != null && dream.imageFile!.isNotEmpty)
                                  localFirstImage(
                                    dreamId: dream.id,
                                    url: dream.imageFile,
                                    kind: DreamImageKind.file,
                                    fit: BoxFit.cover,
                                    radius: BorderRadius.circular(8),
                                  ),
                              // if (dream.imageFile != null && dream.imageFile!.isNotEmpty)
                              //   netImageWithFallback(
                              //     dream.imageFile,
                              //     fit: BoxFit.cover,
                              //     radius: BorderRadius.circular(8),
                              //   ),

                              // Gradient Divider
                              Container(
                                height: 1,
                                margin: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      toneStyle.text.withValues(alpha: 0.7),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),

                              // Dream Analysis
                              if (dream.analysis.isNotEmpty) ...[
                                Text(
                                  "Analysis:",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: toneStyle.text),
                                ),
                                MarkdownBody(
                                  data: dream.analysis,
                                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                    p: TextStyle(color: toneStyle.text, fontSize: 13),
                                    strong: TextStyle(color: toneStyle.text, fontWeight: FontWeight.bold),
                                    em: TextStyle(color: toneStyle.text, fontStyle: FontStyle.italic),
                                    h1: TextStyle(color: toneStyle.text, fontSize: 18, fontWeight: FontWeight.bold),
                                    h2: TextStyle(color: toneStyle.text, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],

                              // Dream Notes
                              if (dream.notes.isNotEmpty) ...[
                                Text(
                                  "Personal Notes:",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: toneStyle.text),
                                ),
                                MarkdownBody(
                                  data: dream.notes,
                                  styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                                    p: TextStyle(color: toneStyle.text, fontSize: 12),
                                    strong: TextStyle(color: toneStyle.text, fontWeight: FontWeight.bold),
                                    em: TextStyle(color: toneStyle.text, fontStyle: FontStyle.italic),
                                    h1: TextStyle(color: toneStyle.text, fontSize: 18, fontWeight: FontWeight.bold),
                                    h2: TextStyle(color: toneStyle.text, fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 6),
                              ],

                              // Notes Button
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ElevatedButton.icon(
                                  onPressed: () => _openNotesEditor(dream.id),
                                  icon: const Icon(Icons.edit_note, size: 16),
                                  label: Text(((dream.notes).trim().isNotEmpty) ? 'Edit notes' : 'Add notes'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.purple600,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    elevation: 0,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),


                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
