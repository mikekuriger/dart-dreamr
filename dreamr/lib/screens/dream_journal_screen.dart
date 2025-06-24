import 'package:flutter/material.dart';
import 'package:dreamr/widgets/dream_journal_widget.dart';
import 'package:dreamr/widgets/main_scaffold.dart';
import 'package:table_calendar/table_calendar.dart';


class DreamJournalScreen extends StatefulWidget {
  const DreamJournalScreen({super.key});

  @override
  State<DreamJournalScreen> createState() => _DreamJournalScreenState();
}

class _DreamJournalScreenState extends State<DreamJournalScreen> {
  // //For Calendar
  // DateTime _focusedDay = DateTime.now();
  // DateTime? _selectedDay;
  // List<Dream> _allDreams = [];
  // Set<DateTime> _dreamDates = {};

  final ScrollController _scrollController = ScrollController();
  void _scrollToTop() {
    print('📢 Scroll attempt: offset = ${_scrollController.offset}');
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  int _dreamCount = 0;
  String _mostCommonTone = '';
  int _longestWordCount = 0;

  final GlobalKey<DreamJournalWidgetState> _journalKey = GlobalKey();

  void _refreshJournal() {
    _journalKey.currentState?.refresh();
  }

  void _loadStats() {
    final dreams = _journalKey.currentState?.getDreams() ?? [];

    setState(() {
      _dreamCount = dreams.length;

      final toneMap = <String, int>{};
      int maxWords = 0;

      for (var d in dreams) {
        final tone = d.tone.trim().toLowerCase();
        if (tone.isNotEmpty) {
          toneMap[tone] = (toneMap[tone] ?? 0) + 1;
        }

        final wordCount = d.text.trim().split(RegExp(r'\s+')).length;
        if (wordCount > maxWords) {
          maxWords = wordCount;
        }
      }

      // _mostCommonTone = toneMap.entries.fold('', (a, b) => b.value > (toneMap[a] ?? 0) ? b.key : a);
      final mostCommon = toneMap.entries.fold<MapEntry<String, int>?>(null, (prev, entry) {
        return (prev == null || entry.value > prev.value) ? entry : prev;
      });
      _mostCommonTone = mostCommon?.key ?? 'N/A';
      _longestWordCount = maxWords;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      onHomePressed: _scrollToTop,
      // title: const Text("Dream Journal ✍️", style: TextStyle(color: Colors.white)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Dreamr ✨ Journal ✍️",
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
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: Color(0xFFD1B2FF),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refreshJournal();
          _loadStats();
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(4),  // padding for dream boxes
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // TableCalendar(
              //   firstDay: DateTime.utc(2020),
              //   lastDay: DateTime.utc(2030),
              //   focusedDay: _focusedDay,
              //   selectedDayPredicate: (day) =>
              //       _selectedDay != null && isSameDay(_selectedDay, day),
              //   onDaySelected: (selectedDay, focusedDay) {
              //     setState(() {
              //       _selectedDay = selectedDay;
              //       _focusedDay = focusedDay;
              //       // For now, doesn't filter—just updates state
              //     });
              //   },
              //   calendarStyle: const CalendarStyle(
              //     todayDecoration: BoxDecoration(
              //       color: Colors.deepPurple,
              //       shape: BoxShape.circle,
              //     ),
              //     selectedDecoration: BoxDecoration(
              //       color: Colors.purple,
              //       shape: BoxShape.circle,
              //     ),
              //   ),
              // ),

              // STATS + BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.shade600,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "🧠 Dream Stats",
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text("Dreams Logged: $_dreamCount", style: const TextStyle(color: Colors.white)),
                      Text("Most Common Tone: $_mostCommonTone", style: const TextStyle(color: Colors.white)),
                      Text("Longest Dream: $_longestWordCount words", style: const TextStyle(color: Colors.white)),

                      const SizedBox(height: 10),

                      // 👇 New Dream button inside the box
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.edit_note),
                          label: const Text("Add a New Dream"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepPurple.shade600,
                          ),
                          onPressed: () {
                            Navigator.pushNamed(context, '/dashboard');
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // stats
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
              //   child: Container(
              //     width: double.infinity,
              //     padding: const EdgeInsets.all(12),
              //     decoration: BoxDecoration(
              //       color: Colors.deepPurple.shade600,
              //       borderRadius: BorderRadius.circular(8),
              //     ),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: [
              //         const Text(
              //           "🧠 Dream Stats",
              //           style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
              //         ),
              //         const SizedBox(height: 6),
              //         Text("Dreams Logged: $_dreamCount", style: const TextStyle(color: Colors.white)),
              //         Text("Most Common Tone: $_mostCommonTone", style: const TextStyle(color: Colors.white)),
              //         Text("Longest Dream: $_longestWordCount words", style: const TextStyle(color: Colors.white)),
              //       ],
              //     ),
              //   ),
              // ),

              // const SizedBox(height: 0),  // extra space 
              DreamJournalWidget(
                key: _journalKey,
                onDreamsLoaded: _loadStats,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
