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

  void _showEditDialog(BuildContext context, MoodProvider provider, int index) {
    final entry = provider.entries[index];
    final noteController = TextEditingController(text: entry.note);
    String selectedEmoji = entry.emoji;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 10,
                children: provider.moodColors.keys.map((emoji) {
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedEmoji = emoji),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: selectedEmoji == emoji ? Colors.teal : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(labelText: 'Note', border: OutlineInputBorder()),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                provider.updateEntry(index, selectedEmoji, noteController.text);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        final entries = moodProvider.entries;

        if (entries.isEmpty) {
          return const Center(child: Text('No mood entries yet.'));
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
                      label: Text(_playingIndex == index ? 'Stop' : 'Play Voice Note'),
                      onPressed: () => _playVoiceNote(entry.voiceNotePath!, index),
                    ),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _showEditDialog(context, moodProvider, index),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => moodProvider.deleteEntry(index),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
