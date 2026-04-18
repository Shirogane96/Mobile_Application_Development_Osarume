import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';

class MoodProvider with ChangeNotifier {
  static const String boxName = 'mood_entries';
  final _supabase = Supabase.instance.client;
  List<MoodEntry> _entries = [];

  List<MoodEntry> get entries => _entries;

  final Map<String, Color> moodColors = {
    '😊': Colors.amber,
    '😐': Colors.blueGrey,
    '😔': Colors.blue,
    '😡': Colors.red,
    '😴': Colors.purple,
  };

  Future<void> loadEntries() async {
    // 1. Load from Local Hive first (for speed)
    final box = await Hive.openBox<MoodEntry>(boxName);
    _entries = box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();

    // 2. Fetch from Supabase if logged in
    final user = _supabase.auth.currentUser;
    if (user != null) {
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

        // Sync local with cloud
        await box.clear();
        await box.addAll(cloudEntries);
        _entries = cloudEntries;
        notifyListeners();
      } catch (e) {
        debugPrint('Error fetching from cloud: $e');
      }
    }
  }

  Future<void> addEntry(MoodEntry entry) async {
    // Save locally
    final box = await Hive.openBox<MoodEntry>(boxName);
    await box.add(entry);
    _entries.insert(0, entry);
    notifyListeners();

    // Save to Supabase
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase.from('mood_entries').insert({
          'user_id': user.id,
          'emoji': entry.emoji,
          'note': entry.note,
          'timestamp': entry.timestamp.toIso8601String(),
          'voice_note_path': entry.voiceNotePath,
        });
      } catch (e) {
        debugPrint('Error syncing to cloud: $e');
      }
    }
  }

  Future<void> updateEntry(int index, String newEmoji, String newNote) async {
    final entry = _entries[index];

    // Update locally
    final box = await Hive.openBox<MoodEntry>(boxName);
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

    // Update in Supabase
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase
            .from('mood_entries')
            .update({'emoji': newEmoji, 'note': newNote})
            .eq('user_id', user.id)
            .eq('timestamp', entry.timestamp.toIso8601String());
      } catch (e) {
        debugPrint('Error updating cloud: $e');
      }
    }
  }

  Future<void> deleteEntry(int index) async {
    final entry = _entries[index];

    // Delete locally
    final box = await Hive.openBox<MoodEntry>(boxName);
    await box.deleteAt(index);
    _entries.removeAt(index);
    notifyListeners();

    // Delete in Supabase
    final user = _supabase.auth.currentUser;
    if (user != null) {
      try {
        await _supabase
            .from('mood_entries')
            .delete()
            .eq('user_id', user.id)
            .eq('timestamp', entry.timestamp.toIso8601String());
      } catch (e) {
        debugPrint('Error deleting from cloud: $e');
      }
    }
  }

  Future<void> deleteAllData() async {
    final box = await Hive.openBox<MoodEntry>(boxName);
    await box.clear();
    _entries.clear();
    notifyListeners();

    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase.from('mood_entries').delete().eq('user_id', user.id);
    }
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
