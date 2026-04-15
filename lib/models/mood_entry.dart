import 'package:hive/hive.dart';

@HiveType(typeId: 0)
class MoodEntry extends HiveObject {
  @HiveField(0)
  final String emoji;

  @HiveField(1)
  final String note;

  @HiveField(2)
  final DateTime timestamp;

  @HiveField(3)
  final String? voiceNotePath;

  MoodEntry({
    required this.emoji,
    required this.note,
    required this.timestamp,
    this.voiceNotePath,
  });
}
