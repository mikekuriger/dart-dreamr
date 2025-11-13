// services/notification_messages.dart
import 'dart:math';

class NotificationMessages {

  /// Generic morning messages — actionable, encouraging.
  static const List<String> generic = [
    "Dreams are stories from within. Add yours to your journal today.",
    "Even a few lines can preserve the meaning of your dream.",
    "Capture the feeling, even if the story is unclear.",
    "Dream fragments still hold insight — write what remains.",
    "Last night’s dream has something to tell you.",
    "Each dream is a page in your personal story. Add today’s entry.",
    "A quick note now can unlock patterns later. Log your dream.",
    "Reflect on last night’s journey and capture its essence.",
    "A brief moment of reflection now keeps the dream alive.",
    "There’s wisdom in what you saw last night. Record it today.",
    "Add to your streak — one more dream, one more insight.",
    "Morning clarity fades fast. Log your dream before it does.",
    "Take a breath, recall, and write. Your dream journal awaits.",
    "Every dream adds depth to your story. Record today’s.",
    "Keep the habit alive — write what stood out in your dream.",
    "Your dream journal grows one entry at a time. Add this one.",
    "Dreams fade, but words remember. Jot yours down now.",
    "A single sentence keeps the story from disappearing.",
    "Build on your momentum. Add today’s dream to your collection.",
    "Open Dreamr and write what still lingers in your mind.",
    "The best time to remember is now — capture your dream.",
    "Record last night’s dream while it’s fresh.",
    "Morning insight awaits — add your dream before it fades.",
    "Something from last night still lingers. Capture it now.",
    "Dreams speak softly. Write before they whisper away.",
    "Your journal grows stronger each morning. Add your dream.",
    "Each entry is a window into you — open one today.",
    "Take 30 seconds to remember last night’s story.",
    "Write the first thing you recall — even a single image.",
    "Dreams connect nights to mornings. Record yours.",
    "Preserve your midnight thoughts before daylight blurs them.",
    "Dreams disappear quickly — jot down what you remember.",
    "Turn your memories into meaning. Add your dream.",
    "Your journal is waiting for a new story. Add one.",
    "One more dream brings new perspective. Record it now.",
    "Even the smallest detail matters. Write it down.",
    "Dreamr remembers when you do — open and record.",
    "Start your day grounded — log your dream first.",
    "Dreams fade, but your words don’t. Write a line or two.",
    "Your subconscious worked all night. Record its message.",
    "Keep the habit alive — record last night’s thoughts.",
    "Each dream adds color to your life. Add today’s shade.",
    "Morning reflection unlocks clarity — write your dream.",
    "A few sentences now can reveal weeks of meaning later.",
    "Your inner voice spoke last night. Capture its whisper.",
    "One moment, one dream — preserve it in your journal.",
    "Dreams are clues to your journey. Write yours now.",
    "Open Dreamr and continue your self-discovery.",
    "Write now, understand later — your dream deserves it.",
    "Don’t lose the thread — capture your dream story.",
    "Begin your morning ritual: reflect and record.",
    "Your dreams connect dots you can’t yet see. Add today’s.",
    "Add today’s dream before it drifts beyond reach.",
    "Even half-remembered dreams hold wisdom. Write yours.",
    "Keep your streak alive — another dream, another entry.",
    "Record your dream before your coffee cools.",
    "That feeling you woke with — write what caused it.",
    "Dreams are mind art. Capture yours in words.",
    "Turn last night’s images into insight. Write now.",
    "Write before the day writes over your dreams.",
    "Your dream journal starts with one tap. Open Dreamr.",
    "Another dream, another step in understanding you.",
    "Even foggy dreams deserve a place in your story.",
    "Morning stillness is perfect for remembering. Record now.",
    "Dreamr is ready when you are — add last night’s dream.",
    "A small reflection today builds deep awareness tomorrow.",
    "Your dreams matter — take a minute to write them down.",
    "Dreams teach through emotion. Note what you felt.",
    "Begin the day with insight. Add your dream entry.",
    "Don’t let this one vanish. Record your dream.",
    "A single line can spark recognition later. Write it.",
    "Dreamr remembers so you don’t have to. Record now.",
    "Capture what you saw between sleep and sunrise.",
    "Your mind painted a picture last night. Describe it.",
    "Dream recall sharpens with practice. Keep going.",
    "Make today meaningful — record your dream now.",
    "Your night story deserves daylight attention.",
    "Dreams are private messages from within. Write yours.",
    "Each entry adds to your self-portrait. Add today’s.",
    "Even fragments tell a story — log them in Dreamr.",
    "Revisit the night and see what it meant to you.",
    "Before your mind fills with noise, write your dream.",
    "Let your first action today be reflection.",
    "Start your day grounded in self-awareness — journal now.",
    "Dreams blur with time — write what’s left before it’s gone.",
    "Your inner self speaks nightly. Record its language.",
    "Morning muse: one dream, one discovery.",
    "Even half-awake thoughts belong in your journal.",
    "Today’s insight starts with last night’s dream.",
    "Dream recall builds mindfulness. Add yours now.",
    "One tap keeps your dream alive — open Dreamr.",
    "Remember, reflect, record — your daily ritual.",
    "Your next breakthrough might be hidden in last night’s dream.",
    "Start the day by listening to your subconscious — write now.",
    "Dreamr is your morning mirror — update it today.",
    "Even one sentence helps you connect the dots. Write it down.",
    "Dreams speak best at dawn — capture their message.",
    "Build your story one dream at a time — record now.",
    "Your journal is incomplete without last night’s chapter.",
    "Dreams shape the day ahead — record yours.",
    "Dreamr keeps the memory safe — add your entry.",
    "Morning light reveals meaning — write what remains.",
    "Turn rest into reflection — jot your dream now.",
    "Keep exploring your inner world — record your dream.",
    "Write it now, understand it later — Dreamr awaits.",
    "Dreams are rare gifts. Keep this one by writing it.",
    "Honor your night mind — record your dream today.",
    "Let your dream live on paper, not just memory.",
    "Wake. Reflect. Record. Your ritual begins.",
    "Before scrolling, remember — write your dream first.",
    "Dream patterns grow with consistency — add yours today.",
    "Don’t rush into the day — take 30 seconds for reflection.",
    "Dreams are the map; your journal is the compass. Write now.",
  ];

  // --- Monthly deterministic shuffle (no repeats within a month) ---
  static int _gcd(int a, int b) => b == 0 ? a.abs() : _gcd(b, a % b);

  // Pick a step that’s coprime with N so we walk the list without repeats.
  static int _coprimeStep(int n, int seed) {
    // try odd steps derived from seed until coprime
    int s = (seed | 1) % n; // make it odd and within range
    if (s == 0) s = 1;
    while (_gcd(s, n) != 1) {
      s = (s + 2) % n;
      if (s == 0) s = 1;
    }
    return s;
  }

  // Deterministic index for this month/day using a full-cycle permutation.
  // Different month/year => different order; no repeats within a month.
  static int indexForMonthDay(DateTime localNow) {
    final n = generic.length;
    if (n == 0) return 0;

    final year = localNow.year;
    final month = localNow.month;      // 1..12
    final dayIdx = localNow.day - 1;   // 0-based day within month

    // Seed from year+month; vary both offset and step monthly
    final seed = year * 131 + month * 37;
    final offset = (seed * 73) % n;
    final step = _coprimeStep(n, seed * 97);

    // Walk permutation by day index
    return (offset + dayIdx * step) % n;
  }

  static String pickForToday(DateTime localNow) =>
      generic[indexForMonthDay(localNow)];

  // Optional: allow a manual offset to “shift” everything if you reorder list
  static String pickForTodayWithOffset(DateTime localNow, int offsetAdj) {
    final n = generic.length;
    if (n == 0) return "";
    final base = indexForMonthDay(localNow);
    return generic[(base + offsetAdj) % n];
  }

  // Keep if you still want simple helpers elsewhere
  static String pickByIndex(int idx) => generic.isEmpty ? "" : generic[idx % generic.length];
  static String pickRandom() => generic.isEmpty ? "" : generic[Random().nextInt(generic.length)];

  /// Personalized line based on usage signals.
  static String personalized({
    required String? displayName,
    required int? streakDays,
    required int? daysSinceLast,
  }) {
    final name = (displayName?.trim().isNotEmpty == true) ? displayName!.trim() : "there";

    // Hasn’t logged in a while
    if (daysSinceLast != null && daysSinceLast >= 7) {
      return "Hey $name, it’s been a while since your last dream entry. Even a few words can keep your reflection going.";
    }
    if (daysSinceLast != null && daysSinceLast >= 4) {
      return "Hey $name, it’s been $daysSinceLast days since your last entry. Write what you remember — even fragments matter.";
    }
    if (daysSinceLast != null && daysSinceLast >= 2) {
      return "Welcome back, $name. It’s been a few days — take a moment to record last night’s dream.";
    }

    // Active streaks
    if ((streakDays ?? 0) >= 10) {
      return "Incredible, $name — $streakDays days in a row! Keep your dream practice alive with today’s entry.";
    }
    if ((streakDays ?? 0) >= 5) {
      return "Nice work, $name — you’re on a $streakDays-day streak. Keep the momentum and log today’s dream.";
    }
    if ((streakDays ?? 0) >= 3) {
      return "You’re building a great habit, $name. Add another dream to your journal today.";
    }
    if ((streakDays ?? 0) == 2) {
      return "You’re on a roll, $name. A third day in a row can turn this into a lasting habit.";
    }

    // Default encouragement
    return "Good morning, $name. Take a moment to write down last night’s dream before the day begins.";
  }
}
