// screens/dream_journal_screen.dart
import 'package:dreamr/widgets/main_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:dreamr/widgets/dream_journal_widget.dart';
import 'package:dreamr/constants.dart';
import 'package:dreamr/services/api_service.dart';


class DreamJournalScreen extends StatefulWidget {
  final ValueNotifier<int> refreshTrigger;
  const DreamJournalScreen({super.key, required this.refreshTrigger});

  @override
  State<DreamJournalScreen> createState() => _DreamJournalScreenState();
}

class _DreamJournalScreenState extends State<DreamJournalScreen> {
  bool _statsExpanded = false;
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


  // state fields
  int _dreamCount = 0;
  String _mostCommonTone = '';
  // int _longestWordCount = 0;

  int? _textRemainingWeek;
  int? _imageRemainingLifetime;
  DateTime? _nextReset;
  bool _quotaLoading = false;
  String? _quotaError;
  bool? _isPro; // null = loading


  @override
  void initState() {
    super.initState();

    // Initial load after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // _loadStats();
      // await _loadQuota();
      _refreshStats();
    });

    // ✅ Listen for bottom nav tab refresh
    widget.refreshTrigger.addListener(_refreshJournal);

    // Refresh journal if a new dream was added
    dreamDataChanged.addListener(() {
      if (dreamDataChanged.value == true) {
        _refreshJournal();
        _refreshStats();
        // _loadStats();
        // await _loadQuota();
        dreamDataChanged.value = false;
      }
    });
  }

  final GlobalKey<DreamJournalWidgetState> _journalKey = GlobalKey();

  void _refreshJournal() {
    _journalKey.currentState?.refresh();

    // 👇 collapse stats box whenever this screen is triggered to refresh
    setState(() {
      _statsExpanded = false;
    });
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

  Future<void> _loadQuota() async {
    setState(() {
      _quotaLoading = true;
      _quotaError = null;
    });

    try {
      final status = await ApiService.getSubscriptionStatus();

      setState(() {
        _isPro = status.isActive;
        _textRemainingWeek = status.textRemainingWeek;            // null for paid
        _imageRemainingLifetime = status.imageRemainingLifetime;  // null for paid
        _nextReset = status.nextReset;                            // null for paid
        _quotaLoading = false;
      });
    } catch (e) {
      setState(() {
        _quotaLoading = false;
        _quotaError = 'Failed to load quota';
      });
    }
  }

  Future<void> _refreshStats() async {
    _loadStats();          // local aggregates
    await _loadQuota();    // network
  }

  
  // Generate a consistent color for each mood
  Color _getMoodColor(String mood) {
    // App's predefined moods with their colors
    // Using text colors for dark backgrounds to ensure visibility
    final Map<String, Color> predefinedMoods = {
      'peaceful / gentle': Colors.blue.shade100,
      'epic / heroic': Colors.orange.shade100,
      'whimsical / surreal': Colors.purple.shade100,
      'nightmarish / dark': Colors.orange.shade200, // Using text color since background is dark
      'romantic / nostalgic': Colors.pink.shade100,
      'ancient / mythic': Colors.brown.shade100,
      'futuristic / uncanny': Colors.teal.shade100,
      'elegant / ornate': Colors.indigo.shade100,
    };
    
    // Normalize the mood string for comparison
    final normalizedMood = mood.toLowerCase().trim();
    
    // Check for exact matches first
    if (predefinedMoods.containsKey(normalizedMood)) {
      return predefinedMoods[normalizedMood]!;
    }
    
    // Check for partial matches (e.g., if mood contains "peaceful" or "gentle")
    for (final entry in predefinedMoods.entries) {
      final keywords = entry.key.split('/').map((k) => k.trim().toLowerCase());
      if (keywords.any((keyword) => normalizedMood.contains(keyword))) {
        return entry.value;
      }
    }
    
    // Otherwise generate a color based on the mood string
    // Use a simple hash function to ensure the same mood always gets the same color
    int hash = 0;
    for (int i = 0; i < mood.length; i++) {
      hash = mood.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Use the hash to generate a hue value between 0 and 360
    final hue = (hash % 360).abs().toDouble();
    
    // Create a color with the hue and fixed saturation/brightness
    // Using HSV color model for more vibrant colors
    return HSVColor.fromAHSV(1.0, hue, 0.7, 0.9).toColor();
  }
  
  // Build sorted mood bars
  List<Widget> _buildSortedMoodBars() {
    if (_toneCounts.isEmpty) {
      return [const Text('No dream data available', style: TextStyle(color: Colors.white70))];
    }
    
    // Sort entries by count (descending)
    final sortedEntries = _toneCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Create a list of mood bar widgets
    return sortedEntries.map((entry) {
      // Calculate percentage for the progress bar
      final percentage = _dreamCount > 0 
          ? entry.value / _dreamCount 
          : 0.0;
      
      // Generate a color based on the mood name
      final color = _getMoodColor(entry.key);
      
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            // Color indicator
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            // Mood name
            Text(
              entry.key,
              style: const TextStyle(
                color: Colors.white70,
                fontStyle: FontStyle.italic,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 8),
            // Progress bar
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Count only (no percentage)
            Text(
              "${entry.value}",
              style: const TextStyle(
                color: Colors.yellow,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }).toList();
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
        // _loadStats();
        // await _loadQuota();
        _refreshStats();
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
                    color: const Color.fromARGB(255, 0, 0, 0).withValues(alpha: 0.45),
                    // color: AppColors.purple850,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color.fromARGB(255, 170, 153, 1),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // header row with title and arrow
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                           RichText(
                                text: TextSpan(
                                  children: [
                                    if (_isPro == null) ...[
                                      const TextSpan(text: " ", style: TextStyle(color: Colors.white)),
                                    ] else if (_isPro!) ...[
                                      const TextSpan(
                                        text: "✨ Dreams Logged: ",
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
                                      ),
                                      TextSpan(
                                        text: '$_dreamCount',
                                        style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                                      ),
                                    ] else ...[
                                      TextSpan(
                                        text: "✨ Dream Credits: ",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
                                      ),
                                      TextSpan(
                                        text: "${_textRemainingWeek ?? 0}",
                                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(
                                        text: "  🔮 Image Credits: ",
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.normal),
                                      ),
                                      TextSpan(
                                        text: "${_imageRemainingLifetime ?? 0}",
                                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ],
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
                  // Show this for free accounts only (hide for pro)      
                              if (_isPro == false) ...[   
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
                              ],
                              RichText(
                                text: TextSpan(
                                  children: [
                                    const TextSpan(
                                      text: "Most Common Dream: ",
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
                                // const Text(
                                //   "All Moods:",
                                //   style: TextStyle(
                                //     color: Colors.white,
                                //     fontWeight: FontWeight.bold,
                                //   ),
                                // ),
                                Row(
                                  children: [
                                    const Expanded(child: Divider(thickness: 1, color: Colors.white24)),
                                    const SizedBox(width: 8),
                                    const Text('✨', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    const Expanded(child: Divider(thickness: 1, color: Colors.white24)),
                                  ],
                                ),
                                // const Divider(
                                //   height: 24,                  // vertical space
                                //   thickness: 1,
                                //   color: Colors.white24,       // subtle on dark bg
                                // ),
                                // const SizedBox(height: 8),
                                
                                // Progress bars for each mood - more compact layout and sorted by count
                                ..._buildSortedMoodBars(),
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
              // onDreamsLoaded: _loadStats,
              onDreamsLoaded: _refreshStats,
            ),
          ],
        ),
      ),
    );
  }
}