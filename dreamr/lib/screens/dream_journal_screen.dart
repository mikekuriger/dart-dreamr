// screens/dream_journal_screen.dart
import 'package:dreamr/theme/colors.dart' show AppColors;
import 'package:dreamr/widgets/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:dreamr/widgets/dream_journal_widget.dart';
import 'package:dreamr/constants.dart';



class DreamJournalScreen extends StatefulWidget {
  final ValueNotifier<int> refreshTrigger;
  const DreamJournalScreen({super.key, required this.refreshTrigger});

  @override
  State<DreamJournalScreen> createState() => _DreamJournalScreenState();
}

class _DreamJournalScreenState extends State<DreamJournalScreen> {
  bool _statsExpanded = true;
  Map<String, int> _toneCounts = {};


  //For Calendar
  // DateTime _focusedDay = DateTime.now();
  // DateTime? _selectedDay;
  // List<Dream> _allDreams = [];
  // Set<DateTime> _dreamDates = {};

  // final ScrollController _scrollController = ScrollController();
  // void _scrollToTop() {
  //   _scrollController.animateTo(
  //     0.0,
  //     duration: const Duration(milliseconds: 300),
  //     curve: Curves.easeOut,
  //   );
  // }

  @override
  void initState() {
    super.initState();

    // Initial load after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });

    // ✅ Listen for bottom nav tab refresh
    widget.refreshTrigger.addListener(_refreshJournal);

    // Refresh journal if a new dream was added
    dreamDataChanged.addListener(() {
      if (dreamDataChanged.value == true) {
        _refreshJournal();
        _loadStats();
        dreamDataChanged.value = false;
      }
    });
  }

  int _dreamCount = 0;
  String _mostCommonTone = '';
  // int _longestWordCount = 0;

  final GlobalKey<DreamJournalWidgetState> _journalKey = GlobalKey();

  void _refreshJournal() {
    _journalKey.currentState?.refresh();

    // 👇 collapse stats box whenever this screen is triggered to refresh
    // setState(() {
    //   _statsExpanded = true;
    // });
  }

  void _loadStats() {
    final dreams = _journalKey.currentState?.getDreams() ?? [];

    setState(() {
      _dreamCount = dreams.length;

      final toneMap = <String, int>{};
      // int maxWords = 0;

      for (var d in dreams) {
        final tone = d.tone.trim().toLowerCase();
        if (tone.isNotEmpty) {
          toneMap[tone] = (toneMap[tone] ?? 0) + 1;
        }
      }

      _toneCounts = toneMap;
      
      final mostCommon = toneMap.entries.fold<MapEntry<String, int>?>(null, (prev, entry) {
        return (prev == null || entry.value > prev.value) ? entry : prev;
      });

      _mostCommonTone = mostCommon?.key ?? 'N/A';
    });
  }
  
  @override
  void dispose() {
    widget.refreshTrigger.removeListener(_refreshJournal);
    dreamDataChanged.removeListener(_refreshJournal);  // if you want to clean that too
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshJournal();
        _loadStats();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(4),
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _statsExpanded = !_statsExpanded;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 0, 0).withOpacity(.4),  
                    // color: AppColors.purple850,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header row with title and arrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Dream ✨ Stats",
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Icon(
                            _statsExpanded ? Icons.expand_less : Icons.expand_more,
                            color: Colors.white, // ✅ white icon
                          ),
                        ],
                      ),

                      // expanding section
                      AnimatedCrossFade(
                        duration: const Duration(milliseconds: 300),
                        crossFadeState: _statsExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: const SizedBox.shrink(),
                        secondChild: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: "Dreams Logged: ",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    TextSpan(
                                      text: '$_dreamCount',
                                      style: const TextStyle(
                                        color: Colors.yellow,
                                        fontWeight: FontWeight.bold,
                                        // fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: "Most Common Mood: ",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.normal,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                    TextSpan(
                                      text: _mostCommonTone,
                                      style: const TextStyle(
                                        color: Colors.yellow,
                                        fontWeight: FontWeight.bold,
                                        // fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              if (_toneCounts.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                const Text(
                                  "All Moods:",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ..._toneCounts.entries.map((entry) {
                                  return RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: "${entry.key}: ",
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontStyle: FontStyle.italic, // 👈 mood in italics
                                            fontSize: 14,
                                          ),
                                        ),
                                        TextSpan(
                                          text: "${entry.value}",
                                          style: const TextStyle(
                                            color: Colors.yellow,       // 👈 count in yellow
                                            fontWeight: FontWeight.bold, // 👈 bold count
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],

                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.edit_note),
                                  label: const Text("Add a New Dream"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: Colors.deepPurple.shade600,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const MainScaffold(initialIndex: 0),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            DreamJournalWidget(
              key: _journalKey,
              onDreamsLoaded: _loadStats,
            ),
          ],
        ),
      ),
    );
  }
}
