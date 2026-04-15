import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../models/mood_entry.dart';
import '../providers/mood_provider.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MoodSelectorBody(),
    const HistoryScreen(),
    const AnalyticsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EmojiTrack'),
        centerTitle: true,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.add_reaction), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Trends'),
        ],
      ),
    );
  }
}

class MoodSelectorBody extends StatefulWidget {
  const MoodSelectorBody({super.key});

  @override
  State<MoodSelectorBody> createState() => _MoodSelectorBodyState();
}

class _MoodSelectorBodyState extends State<MoodSelectorBody> {
  final List<Map<String, String>> moods = const [
    {'emoji': '😊', 'label': 'Happy'},
    {'emoji': '😐', 'label': 'Neutral'},
    {'emoji': '😔', 'label': 'Sad'},
    {'emoji': '😡', 'label': 'Angry'},
    {'emoji': '😴', 'label': 'Tired'},
  ];

  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentRecordingPath;
  bool _isRecording = false;

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = p.join(directory.path, 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a');
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        
        setState(() {
          _isRecording = true;
          _currentRecordingPath = path;
        });
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _currentRecordingPath = path;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  void _showNoteDialog(BuildContext context, String emoji) {
    final controller = TextEditingController();
    _currentRecordingPath = null;
    _isRecording = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('How are you feeling? $emoji', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Add a note (optional)...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 40,
                    icon: Icon(_isRecording ? Icons.stop_circle : Icons.mic, 
                          color: _isRecording ? Colors.red : Colors.teal),
                    onPressed: () async {
                      if (_isRecording) {
                        await _stopRecording();
                      } else {
                        await _startRecording();
                      }
                      setModalState(() {});
                    },
                  ),
                  if (_currentRecordingPath != null && !_isRecording)
                    const Text('Voice note captured! ✅'),
                  if (_isRecording)
                    const Text('Recording... 🎙️'),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  final entry = MoodEntry(
                    emoji: emoji,
                    note: controller.text,
                    timestamp: DateTime.now(),
                    voiceNotePath: _currentRecordingPath,
                  );
                  context.read<MoodProvider>().addEntry(entry);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mood logged!')),
                  );
                },
                child: const Text('Save Mood'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('How are you right now?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 40),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: moods.map((mood) {
              return GestureDetector(
                onTap: () => _showNoteDialog(context, mood['emoji']!),
                child: Column(
                  children: [
                    Text(mood['emoji']!, style: const TextStyle(fontSize: 50)),
                    Text(mood['label']!),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
