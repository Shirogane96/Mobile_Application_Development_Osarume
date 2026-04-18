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

  // Use a user-specific box name for privacy
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

    // 1. Load from User-Specific Local Hive first
    final box = await Hive.openBox<MoodEntry>(_boxName);
    _entries = box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();

    // 2. Fetch from Supabase and sync
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

      // Sync local box with cloud data
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

    // Save locally to user box
    final box = await Hive.openBox<MoodEntry>(_boxName);
    await box.add(entry);
    _entries.insert(0, entry);
    notifyListeners();

    // Save to Supabase
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
