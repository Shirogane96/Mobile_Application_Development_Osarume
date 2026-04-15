import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';

class MoodProvider with ChangeNotifier {
  static const String boxName = 'mood_entries';
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
    final box = await Hive.openBox<MoodEntry>(boxName);
    _entries = box.values.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> addEntry(MoodEntry entry) async {
    final box = await Hive.openBox<MoodEntry>(boxName);
    await box.add(entry);
    _entries.insert(0, entry);
    notifyListeners();
  }

  Future<void> updateEntry(int index, String newEmoji, String newNote) async {
    final box = await Hive.openBox<MoodEntry>(boxName);
    final entry = _entries[index];

    // We need to find the actual key in Hive
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
  }

  Future<void> deleteEntry(int index) async {
    final box = await Hive.openBox<MoodEntry>(boxName);
    await box.deleteAt(index);
    _entries.removeAt(index);
    notifyListeners();
  }

  Future<void> deleteAllData() async {
    final box = await Hive.openBox<MoodEntry>(boxName);
    await box.clear();
    _entries.clear();
    notifyListeners();
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
