import 'package:flutter/material.dart';
import '../widgets/dream_entry_widget.dart';
import '../widgets/dream_journal_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<DreamJournalWidgetState> _journalKey = GlobalKey();

  void _refreshJournal() {
    _journalKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dream Journal")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DreamEntryWidget(onSubmitComplete: _refreshJournal),
            const SizedBox(height: 20),
            DreamJournalWidget(key: _journalKey),
          ],
        ),
      ),
    );
  }
}
