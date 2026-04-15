import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/mood_entry.dart';

class MoodProvider with ChangeNotifier {
  static const String boxName = 'mood_entries';
  List<MoodEntry> _entries = [];

  List<MoodEntry> get entries => _entries;

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

  Future<void> deleteEntry(int index) async {
    final box = await Hive.openBox<MoodEntry>(boxName);
    await box.deleteAt(index);
    _entries.removeAt(index);
    notifyListeners();
  }
}
