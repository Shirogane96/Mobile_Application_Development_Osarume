import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:emojitrack/main.dart';
import 'package:emojitrack/providers/mood_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    // We wrap it in a Provider because MoodTrackApp uses Consumer/Provider internally.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => MoodProvider()),
        ],
        child: const MoodTrackApp(),
      ),
    );

    // Verify that the title is present.
    expect(find.text('EmojiTrack'), findsOneWidget);
    
    // Verify that the initial "How are you right now?" prompt is visible
    expect(find.text('How are you right now?'), findsOneWidget);
  });
}
