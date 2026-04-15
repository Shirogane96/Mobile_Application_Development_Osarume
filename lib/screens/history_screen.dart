import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../providers/mood_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int? _playingIndex;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playVoiceNote(String path, int index) async {
    try {
      if (_playingIndex == index) {
        await _audioPlayer.stop();
        setState(() => _playingIndex = null);
      } else {
        await _audioPlayer.play(DeviceFileSource(path));
        setState(() => _playingIndex = index);

        _audioPlayer.onPlayerComplete.listen((event) {
          if (mounted) setState(() => _playingIndex = null);
        });
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        final entries = moodProvider.entries;

        if (entries.isEmpty) {
          return const Center(
            child: Text('No mood entries yet. Start logging!'),
          );
        }

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            final entry = entries[index];
            final hasVoice = entry.voiceNotePath != null && entry.voiceNotePath!.isNotEmpty;

            return ListTile(
              leading: Text(entry.emoji, style: const TextStyle(fontSize: 30)),
              title: Text(entry.note.isEmpty ? 'No note' : entry.note),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('MMM dd, yyyy - hh:mm a').format(entry.timestamp)),
                  if (hasVoice)
                    TextButton.icon(
                      icon: Icon(_playingIndex == index ? Icons.stop : Icons.play_arrow),
                      label: Text(_playingIndex == index ? 'Stop Recording' : 'Play Voice Note'),
                      onPressed: () => _playVoiceNote(entry.voiceNotePath!, index),
                    ),
                ],
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => moodProvider.deleteEntry(index),
              ),
            );
          },
        );
      },
    );
  }
}
