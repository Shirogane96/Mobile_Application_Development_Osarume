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
          selectedItemColor: const Color(0xFF5C6BC0), // Indigo
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'History'),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart_rounded), label: 'Trends'),
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

  Widget _buildAvatar(String? path, double radius) {
    final user = context.read<AuthProvider>().currentUser;
    final initial = user?.username.isNotEmpty == true ? user!.username[0].toUpperCase() : '?';

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: const Color(0xFFE8EAF6), // Soft Indigo background
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF5C6BC0).withOpacity(0.2), width: 2),
      ),
      child: ClipOval(
        child: path != null && path.isNotEmpty
            ? (path.startsWith('http') || kIsWeb
                ? Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => Center(child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5C6BC0)))))
                : Image.file(File(path), fit: BoxFit.cover, errorBuilder: (c, e, s) => Center(child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5C6BC0))))))
            : Center(child: Text(initial, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF5C6BC0), fontSize: 18))),
      ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_getGreeting(), style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  Text('Hello, ${user?.username ?? 'User'} 👋', 
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF5C6BC0))),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                child: _buildAvatar(user?.profileImagePath, 28),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Daily Insight Card - Now Perfectly Themed (Indigo/Pink Gradient feel)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF5C6BC0), Color(0xFF7986CB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [BoxShadow(color: const Color(0xFF5C6BC0).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: Color(0xFFFCE4EC), size: 20),
                    const SizedBox(width: 8),
                    Text('DAILY INSIGHT', style: TextStyle(color: Colors.white.withOpacity(0.9), letterSpacing: 1.2, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  moodProvider.getSmartInsight,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 25),

          Row(
            children: [
              Expanded(
                child: _buildSmallCard('Mood Streak', '$streak Days', Icons.local_fire_department, Colors.orange),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildSmallCard('Total Logs', '${moodProvider.entries.length}', Icons.assignment_rounded, const Color(0xFF5C6BC0)),
              ),
            ],
          ),
          const SizedBox(height: 30),

          const Text('How are you right now?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 20),

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
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(mood['emoji']!, style: const TextStyle(fontSize: 40)),
                      const SizedBox(height: 8),
                      Text(mood['label']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF5C6BC0))),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
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
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text('How are you feeling? $emoji', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5C6BC0))),
              const SizedBox(height: 24),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Add a note (optional)...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    iconSize: 50,
                    icon: Icon(_isRecording ? Icons.stop_circle_rounded : Icons.mic_rounded, 
                          color: _isRecording ? Colors.red : const Color(0xFF5C6BC0)),
                    onPressed: () async {
                      if (_isRecording) {
                        final path = await _audioRecorder.stop();
                        setModalState(() { _isRecording = false; _currentRecordingPath = path; });
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
                  if (_currentRecordingPath != null && !_isRecording) const Text('Voice captured! ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  if (_isRecording) const Text('Recording... 🎙️', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    final entry = MoodEntry(emoji: emoji, note: controller.text, timestamp: DateTime.now(), voiceNotePath: _currentRecordingPath);
                    context.read<MoodProvider>().addEntry(entry);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mood logged!'), behavior: SnackBarBehavior.floating));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5C6BC0), 
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0,
                  ),
                  child: const Text('Save Reflection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
