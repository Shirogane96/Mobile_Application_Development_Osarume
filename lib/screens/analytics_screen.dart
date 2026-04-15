import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/mood_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        if (moodProvider.entries.isEmpty) {
          return const Center(child: Text('Not enough data for analytics yet.'));
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mood Trends',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: _buildPieChart(moodProvider),
              ),
              const SizedBox(height: 30),
              const Text(
                'Insights',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Tracking your mood daily helps you identify patterns. Keep it up!',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPieChart(MoodProvider provider) {
    final Map<String, int> counts = {};
    for (var entry in provider.entries) {
      counts[entry.emoji] = (counts[entry.emoji] ?? 0) + 1;
    }

    final List<PieChartSectionData> sections = counts.entries.map((e) {
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${e.key} ${e.value}',
        radius: 50,
        titleStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      );
    }).toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }
}
