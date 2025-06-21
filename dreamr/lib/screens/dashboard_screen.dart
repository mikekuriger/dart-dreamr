import 'package:flutter/material.dart';
import 'package:dreamr/widgets/dream_entry_widget.dart';
import 'package:dreamr/widgets/dream_journal_widget.dart';
import 'package:dreamr/theme/colors.dart';

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
      appBar: AppBar(
        backgroundColor: AppColors.purple900, // use your darkest shade
        elevation: 4,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              "Welcome to Dreamr ✨",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              "Your personal AI-powered dream analysis",
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Color(0xFFD1B2FF), // soft lavender/purple for subtext
              ),
            ),
          ],
        ),
      ),

      body: RefreshIndicator(
        onRefresh: () async {
          _refreshJournal();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Required to allow pull gesture
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DreamEntryWidget(onSubmitComplete: _refreshJournal),
              const SizedBox(height: 20),
              DreamJournalWidget(key: _journalKey),
            ],
          ),
        ),
      ),
    );
  }
}
