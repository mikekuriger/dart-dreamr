import 'package:flutter/material.dart';
import '../models/dream.dart';
import '../services/api_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';

class DreamJournalWidget extends StatefulWidget {
  const DreamJournalWidget({Key? key}) : super(key: key);

  @override
  State<DreamJournalWidget> createState() => DreamJournalWidgetState();
}

class DreamJournalWidgetState extends State<DreamJournalWidget> {
  List<Dream> _dreams = [];
  Map<int, bool> _expanded = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDreams();
  }

  Future<void> _loadDreams() async {
    try {
      final dreams = await ApiService.fetchDreams();
      setState(() {
        _dreams = dreams;
        _loading = false;
      });
    } catch (e) {
      print("❌ Failed to fetch dreams: $e");
      setState(() {
        _loading = false;
      });
    }
  }


  void refresh() {
    setState(() => _loading = true);
    _loadDreams();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_dreams.isEmpty) return const Text("No dreams found.");

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _dreams.length,
      itemBuilder: (context, index) {
        final dream = _dreams[index];
        final isExpanded = _expanded[dream.id] ?? false;
        final formattedDate = DateFormat.yMMMd().add_jm().format(dream.createdAt);

        return Card(
          child: Column(
            children: [
              ListTile(
                title: Text(dream.summary),
                
                subtitle: Text(formattedDate),
                onTap: () {
                  setState(() {
                    _expanded[dream.id] = !isExpanded;
                  });
                },
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dream.text, style: const TextStyle(fontStyle: FontStyle.italic)),
                      const SizedBox(height: 8),
                      if (dream.imageFile != null)
                        Image.network(dream.imageFile!),
                      if (dream.tone.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: MarkdownBody(data: dream.tone),
                        ),
                    ],
                  ),
                )
            ],
          ),
        );
      },
    );
  }
}
