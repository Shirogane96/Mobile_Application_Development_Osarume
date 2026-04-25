import 'dart:math';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';

class MoodProvider with ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<MoodEntry> _entries = [];
  List<MoodEntry> get entries => _entries;

  final Map<String, List<String>> _insightVariations = {
    '😊': [
      "You've been mostly happy recently! Keep doing what you're doing. Try to note down what triggered these good vibes.",
      "The sun is shining on you! Your mood has been consistently positive lately. Spread that joy!",
      "Happiness looks good on you. Reflect on what made this time special to keep the momentum going.",
    ],
    '😐': [
      "You're feeling neutral quite often. Maybe it's time for a small change or a new hobby to spice things up?",
      "Consistency is good, but don't forget to seek out moments that excite you. A small adventure might help.",
      "It's been a calm period. Balance is important, but make sure you're still finding time for things you love.",
    ],
    '😔': [
      "You've been feeling down lately. Remember to reach out to a friend or take some time for self-care.",
      "It's okay not to be okay. Take things one step at a time and prioritize your mental rest today.",
      "You've logged some sadness recently. Be kind to yourself; even small acts of joy can make a difference.",
    ],
    '😡': [
      "You've logged anger multiple times. Try a 5-minute breathing exercise when you feel the tension rising.",
      "Frustration can be heavy. Consider journaling specifically about what's bothering you to let it out.",
      "Tension seems high. A short walk or physical exercise can be a great way to release stress.",
    ],
    '😴': [
      "You've been feeling tired frequently. Are you getting enough sleep? A consistent sleep schedule can really help.",
      "Your energy levels seem low. Don't forget to recharge and maybe take a break from screens tonight.",
      "Rest is productive too! If you're feeling exhausted, listen to your body and get some extra shut-eye.",
    ],
  };

  // Streak logic
  int get currentStreak {
    if (_entries.isEmpty) return 0;

    final sortedEntries = List<MoodEntry>.from(_entries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    int streak = 0;
    DateTime today = DateTime.now();
    DateTime lastDate = DateTime(today.year, today.month, today.day);

    bool foundToday = false;
    for (var entry in sortedEntries) {
      DateTime entryDate = DateTime(entry.timestamp.year, entry.timestamp.month, entry.timestamp.day);

      if (entryDate == lastDate) {
        if (!foundToday) {
          streak++;
          foundToday = true;
        }
      } else if (entryDate == lastDate.subtract(const Duration(days: 1))) {
        streak++;
        lastDate = entryDate;
      } else if (entryDate.isBefore(lastDate.subtract(const Duration(days: 1)))) {
        break;
      }
    }
    return streak;
  }

  // Smart Insights Logic - Fixed to be 100% reactive to most frequent mood
  String get getSmartInsight {
    if (_entries.isEmpty) return "Start logging your mood to see insights!";
    
    final Map<String, int> counts = {};
    for (var e in _entries) {
      counts[e.emoji] = (counts[e.emoji] ?? 0) + 1;
    }

    if (counts.isEmpty) return "Tracking your moods is the first step to understanding your wellbeing!";

    // Find the most frequent mood
    String topMood = _entries.first.emoji;
    int maxCount = -1;

    counts.forEach((emoji, count) {
      if (count > maxCount) {
        maxCount = count;
        topMood = emoji;
      }
    });

    final variations = _insightVariations[topMood] ?? ["Tracking your moods is the first step to understanding your wellbeing!"];

    // Use a hash of the date and top mood to ensure variety but consistency within the same day
    final dateKey = DateTime.now().day + DateTime.now().month + topMood.hashCode;
    final random = Random(dateKey);
    return variations[random.nextInt(variations.length)];
  }

  String get _boxName {
    final userId = _supabase.auth.currentUser?.id ?? 'guest';
    return 'mood_entries_$userId';
  }

  final Map<String, Color> moodColors = {
    '😊': Colors.amber,
    '😐': Colors.blueGrey,
    '😔': Colors.blue,
    '😡': Colors.red,
    '😴': Colors.purple,
  };

  void clearData() {
    _entries = [];
    notifyListeners();
  }

  Future<void> loadEntries() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _entries = [];
      notifyListeners();
      return;
    }

    final box = await Hive.openBox<MoodEntry>(_boxName);
    _entries = box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();

    try {
      final response = await _supabase
          .from('mood_entries')
          .select()
          .eq('user_id', user.id)
          .order('timestamp', ascending: false);

      final cloudEntries = (response as List).map((data) => MoodEntry(
        emoji: data['emoji'],
        note: data['note'] ?? '',
        timestamp: DateTime.parse(data['timestamp']),
        voiceNotePath: data['voice_note_path'],
      )).toList();

      await box.clear();
      await box.addAll(cloudEntries);
      _entries = cloudEntries;
      notifyListeners();
    } catch (e) {
      debugPrint('Sync Error: $e');
    }
  }

  Future<void> addEntry(MoodEntry entry) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final box = await Hive.openBox<MoodEntry>(_boxName);
    await box.add(entry);
    _entries.insert(0, entry);
    notifyListeners();

    try {
      await _supabase.from('mood_entries').insert({
        'user_id': user.id,
        'emoji': entry.emoji,
        'note': entry.note,
        'timestamp': entry.timestamp.toIso8601String(),
        'voice_note_path': entry.voiceNotePath,
      });
    } catch (e) {
      debugPrint('Cloud Save Error: $e');
    }
  }

  Future<void> updateEntry(int index, String newEmoji, String newNote) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final entry = _entries[index];
    final box = await Hive.openBox<MoodEntry>(_boxName);
    final hiveKey = box.keyAt(box.values.toList().indexOf(entry));

    final updatedEntry = MoodEntry(
      emoji: newEmoji,
      note: newNote,
      timestamp: entry.timestamp,
      voiceNotePath: entry.voiceNotePath,
    );

    await box.put(hiveKey, updatedEntry);
    _entries[index] = updatedEntry;
    notifyListeners();

    try {
      await _supabase
          .from('mood_entries')
          .update({'emoji': newEmoji, 'note': newNote})
          .eq('user_id', user.id)
          .eq('timestamp', entry.timestamp.toIso8601String());
    } catch (e) {
      debugPrint('Cloud Update Error: $e');
    }
  }

  Future<void> deleteEntry(int index) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final entry = _entries[index];
    final box = await Hive.openBox<MoodEntry>(_boxName);
    await box.deleteAt(index);
    _entries.removeAt(index);
    notifyListeners();

    try {
      await _supabase
          .from('mood_entries')
          .delete()
          .eq('user_id', user.id)
          .eq('timestamp', entry.timestamp.toIso8601String());
    } catch (e) {
      debugPrint('Cloud Delete Error: $e');
    }
  }

  Future<void> deleteAllData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final box = await Hive.openBox<MoodEntry>(_boxName);
    await box.clear();
    _entries = [];
    notifyListeners();

    await _supabase.from('mood_entries').delete().eq('user_id', user.id);
  }

  Future<void> exportToPdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('EmojiTrack Mood History')),
          pw.TableHelper.fromTextArray(
            headers: ['Date', 'Mood', 'Note'],
            data: _entries.map((e) => [
              DateFormat('yyyy-MM-dd HH:mm').format(e.timestamp),
              e.emoji,
              e.note,
            ]).toList(),
          ),
        ],
      ),
    );
    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
