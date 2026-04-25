import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../models/mood_entry.dart';
import '../providers/mood_provider.dart';
import '../providers/auth_provider.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';
import 'profile_screen.dart';

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
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _screens[_currentIndex]),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          elevation: 0,
          onTap: (index) => setState(() => _currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.add_reaction), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Trends'),
          ],
        ),
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  Widget _buildAvatar(String? path, double radius, double fontSize) {
    final user = context.read<AuthProvider>().currentUser;
    final initial = user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : '?';

    if (path == null || path.isEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: fontSize,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    ImageProvider imageProvider;
    if (path.startsWith('http')) {
      imageProvider = NetworkImage(path);
    } else if (kIsWeb) {
      imageProvider = NetworkImage(path);
    } else {
      imageProvider = FileImage(File(path));
    }

    return CircleAvatar(
      key: ValueKey(path),
      radius: radius,
      backgroundColor: Colors.transparent,
      backgroundImage: imageProvider,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final moodProvider = context.watch<MoodProvider>();
    final streak = moodProvider.currentStreak;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getGreeting(), style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  Text('Hello, ${user?.username ?? 'User'} 👋', 
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                child: _buildAvatar(user?.profileImagePath, 30, 20),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Daily Insight Card - Now themed
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8), size: 20),
                    const SizedBox(width: 8),
                    Text('DAILY INSIGHT', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8), letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  moodProvider.getSmartInsight,
                  style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 18, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          // Grid Section
          Row(
            children: [
              Expanded(
                child: _buildSmallCard(
                  'Mood Streak', 
                  '$streak Days', 
                  Icons.local_fire_department, 
                  Colors.orange
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSmallCard(
                  'Total Logs', 
                  '${moodProvider.entries.length}', 
                  Icons.assignment_outlined, 
                  Colors.blue
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),

          const Text('How are you right now?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Emojis as Rounded Boxes
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 0.9,
            ),
            itemCount: moods.length,
            itemBuilder: (context, index) {
              final mood = moods[index];
              return InkWell(
                onTap: () => _showNoteDialog(context, mood['emoji']!),
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(mood['emoji']!, style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(mood['label']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSmallCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 14, color: Colors.grey)),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext context, String emoji) {
    final controller = TextEditingController();
    _currentRecordingPath = null;
    _isRecording = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('How are you feeling? $emoji', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
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
                          color: _isRecording ? Colors.red : Theme.of(context).colorScheme.primary),
                    onPressed: () async {
                      if (_isRecording) {
                        final path = await _audioRecorder.stop();
                        setModalState(() {
                          _isRecording = false;
                          _currentRecordingPath = path;
                        });
                      } else {
                        if (await _audioRecorder.hasPermission()) {
                          final directory = await getApplicationDocumentsDirectory();
                          final path = p.join(directory.path, 'recording_${DateTime.now().millisecondsSinceEpoch}.m4a');
                          await _audioRecorder.start(const RecordConfig(), path: path);
                          setModalState(() => _isRecording = true);
                        }
                      }
                    },
                  ),
                  if (_currentRecordingPath != null && !_isRecording) const Text('Voice captured! ✅'),
                  if (_isRecording) const Text('Recording... 🎙️'),
                ],
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    final entry = MoodEntry(emoji: emoji, note: controller.text, timestamp: DateTime.now(), voiceNotePath: _currentRecordingPath);
                    context.read<MoodProvider>().addEntry(entry);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mood logged!')));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary, 
                    foregroundColor: Theme.of(context).colorScheme.onPrimary, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                  ),
                  child: const Text('Save Reflection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
