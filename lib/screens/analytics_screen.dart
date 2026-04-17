import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/mood_provider.dart';

enum ChartType { pie, bar, radar }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  ChartType _selectedChart = ChartType.pie;

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        if (moodProvider.entries.isEmpty) {
          return const Center(child: Text('Not enough data for analytics yet.'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mood Analysis',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  DropdownButton<ChartType>(
                    value: _selectedChart,
                    onChanged: (ChartType? newValue) {
                      if (newValue != null) setState(() => _selectedChart = newValue);
                    },
                    items: const [
                      DropdownMenuItem(value: ChartType.pie, child: Text('Distribution (Pie)')),
                      DropdownMenuItem(value: ChartType.bar, child: Text('Frequency (Bar)')),
                      DropdownMenuItem(value: ChartType.radar, child: Text('Balance (Radar)')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                height: 400,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: _buildSelectedChart(moodProvider),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Data Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Export PDF'),
                    onPressed: () => moodProvider.exportToPdf(),
                  ),
                ],
              ),
              Card(
                color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Clear All Records', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  subtitle: const Text('This action cannot be undone.'),
                  onTap: () => _showDeleteDialog(context, moodProvider),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteDialog(BuildContext context, MoodProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text('Are you sure you want to permanently delete all your mood history?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteAllData();
              Navigator.pop(context);
            },
            child: const Text('Delete Everything', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedChart(MoodProvider provider) {
    switch (_selectedChart) {
      case ChartType.pie:
        return _buildPieChart(provider);
      case ChartType.bar:
        return _buildBarChart(provider);
      case ChartType.radar:
        return _buildRadarChart(provider);
    }
  }

  Widget _buildPieChart(MoodProvider provider) {
    final Map<String, int> counts = {};
    for (var entry in provider.entries) {
      counts[entry.emoji] = (counts[entry.emoji] ?? 0) + 1;
    }

    final List<PieChartSectionData> sections = counts.entries.map((e) {
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${e.key}',
        radius: 70,
        color: provider.moodColors[e.key] ?? Colors.grey,
        titleStyle: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      );
    }).toList();

    return PieChart(PieChartData(sections: sections, centerSpaceRadius: 40));
  }

  Widget _buildBarChart(MoodProvider provider) {
    final Map<String, int> counts = {};
    for (var entry in provider.entries) {
      counts[entry.emoji] = (counts[entry.emoji] ?? 0) + 1;
    }

    final List<BarChartGroupData> groups = [];
    int i = 0;
    counts.forEach((emoji, count) {
      groups.add(BarChartGroupData(
        x: i++,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: provider.moodColors[emoji] ?? Colors.grey,
            width: 25,
            borderRadius: BorderRadius.circular(4),
          )
        ],
      ));
    });

    return BarChart(
      BarChartData(
        barGroups: groups,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < counts.keys.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(counts.keys.elementAt(value.toInt()), style: const TextStyle(fontSize: 18)),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
      ),
    );
  }

  Widget _buildRadarChart(MoodProvider provider) {
    final Map<String, int> counts = {};
    provider.moodColors.keys.forEach((emoji) => counts[emoji] = 0);
    for (var entry in provider.entries) {
      counts[entry.emoji] = (counts[entry.emoji] ?? 0) + 1;
    }

    return RadarChart(
      RadarChartData(
        dataSets: [
          RadarDataSet(
            fillColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            borderColor: Theme.of(context).colorScheme.primary,
            entryRadius: 3,
            dataEntries: counts.values.map((count) => RadarEntry(value: count.toDouble())).toList(),
          ),
        ],
        radarBackgroundColor: Colors.transparent,
        getTitle: (index, angle) => RadarChartTitle(text: counts.keys.elementAt(index), angle: angle),
        tickCount: 3,
        ticksTextStyle: const TextStyle(color: Colors.grey, fontSize: 10),
      ),
    );
  }
}
