import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'models/mood_entry.dart';
import 'models/user_model.dart';
import 'providers/mood_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://fomizubnzkmndgmpzres.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZvbWl6dWJuemttbmRnbXB6cmVzIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzY0NjgxMTgsImV4cCI6MjA5MjA0NDExOH0.0BsbCqMV9DzSVkE_ItB4tm3HIHz4U7Om5bbvgxbrmbc',
  );
  
  await Hive.initFlutter();
  Hive.registerAdapter(MoodEntryAdapter());
  Hive.registerAdapter(UserModelAdapter());
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => MoodProvider()),
      ],
      child: const MoodTrackApp(),
    ),
  );
}

class MoodTrackApp extends StatelessWidget {
  const MoodTrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'EmojiTrack',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.themeData,
          home: Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isAuthenticated) {
                // Ensure data is loaded for the new user
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  context.read<MoodProvider>().loadEntries();
                });
                return const HomeScreen();
              } else {
                return const LoginScreen();
              }
            },
          ),
        );
      },
    );
  }
}

class MoodEntryAdapter extends TypeAdapter<MoodEntry> {
  @override
  final int typeId = 0;

  @override
  MoodEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MoodEntry(
      emoji: fields[0] as String,
      note: fields[1] as String,
      timestamp: fields[2] as DateTime,
      voiceNotePath: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, MoodEntry obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.emoji)
      ..writeByte(1)
      ..write(obj.note)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.voiceNotePath);
  }
}

class UserModelAdapter extends TypeAdapter<UserModel> {
  @override
  final int typeId = 1;

  @override
  UserModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserModel(
      username: fields[0] as String,
      email: fields[1] as String,
      password: fields[2] as String,
      profileImagePath: fields[3] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, UserModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.username)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.password)
      ..writeByte(3)
      ..write(obj.profileImagePath);
  }
}
