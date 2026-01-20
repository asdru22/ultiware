import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:countries_world_map/countries_world_map.dart';
import 'package:countries_world_map/data/maps/world_map.dart';
import '../data/clothing_repository.dart';
import '../data/clothing_item.dart';
import 'package:country_picker/country_picker.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ClothingRepository>(
      builder: (context, repo, child) {
        final items = repo.items.where((item) => !item.isTraded).toList();
        if (items.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Statistics')),
            body: const Center(
                child: Text("No items available for statistics.")),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Statistics')),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildSectionTitle('Total Items: ${items.length}'),
                const SizedBox(height: 24),

                _buildSectionTitle('Brand Distribution'),
                _buildPieChart(
                    items, (item) => item.brand?.displayName ?? 'Unknown'),
                const SizedBox(height: 24),

                _buildSectionTitle('Type Distribution'),
                _buildPieChart(
                    items, (item) => item.type?.displayName ?? 'Unknown'),
                const SizedBox(height: 24),

                _buildSectionTitle('Size Distribution'),
                _buildBarChart(items, (item) =>
                item.size?.name.toUpperCase() ??
                    'Unknown'),
                const SizedBox(height: 24),

                _buildSectionTitle('Source Distribution'),
                _buildPieChart(
                    items, (item) => item.source?.displayName ?? 'Unknown'),
                const SizedBox(height: 24),

                _buildSectionTitle('Condition Distribution'),
                _buildPieChart(
                    items, (item) => item.condition?.displayName ?? 'Unknown'),
                const SizedBox(height: 24),

                _buildSectionTitle('Year Distribution'),
                _buildYearBarChart(items),
                const SizedBox(height: 24),

                _buildSectionTitle('Country Distribution'),
                const SizedBox(height: 16),
                _buildWorldMap(items),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme
          .of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPieChart(List<ClothingItem> items,
      String Function(ClothingItem) keyExtractor) {
    final Map<String, int> counts = {};
    for (var item in items) {
      final key = keyExtractor(item);
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final List<PieChartSectionData> sections = [];
    final keys = counts.keys.toList();
    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple,
      Colors.teal, Colors.amber, Colors.indigo, Colors.brown, Colors.pink
    ];

    for (int i = 0; i < keys.length; i++) {
      final key = keys[i];
      final count = counts[key]!;
      final percentage = (count / items.length * 100).toStringAsFixed(1);

      sections.add(
        PieChartSectionData(
          color: colors[i % colors.length],
          value: count.toDouble(),
          title: '$key\n$percentage%',
          radius: 100,
          titleStyle: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: PieChart(
        PieChartData(
          sections: sections,
          sectionsSpace: 2,
          centerSpaceRadius: 40,
        ),
      ),
    );
  }

  Widget _buildBarChart(List<ClothingItem> items,
      String Function(ClothingItem) keyExtractor) {
    final Map<String, int> counts = {};
    for (var item in items) {
      final key = keyExtractor(item);
      counts[key] = (counts[key] ?? 0) + 1;
    }

    final keys = counts.keys.toList()
      ..sort();

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < 0 || value.toInt() >= keys.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      keys[value.toInt()],
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: true),
          barGroups: keys
              .asMap()
              .entries
              .map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(
                    toY: counts[entry.value]!.toDouble(),
                    color: Colors.indigo,
                    width: 16,
                    borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildYearBarChart(List<ClothingItem> items) {
    final Map<int, int> counts = {};
    for (var item in items) {
      if (item.productionYear != null) {
        counts[item.productionYear!] = (counts[item.productionYear!] ?? 0) + 1;
      }
    }

    if (counts.isEmpty) return const Text("No year data available.");

    final sortedYears = counts.keys.toList()
      ..sort();
    final minYear = sortedYears.first;
    final maxYear = sortedYears.last;

    return AspectRatio(
      aspectRatio: 1.5,
      child: BarChart(
        BarChartData(
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final year = value.toInt();
                  if (counts.containsKey(year)) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(year.toString(),
                          style: const TextStyle(fontSize: 10)),
                    );
                  }
                  return const SizedBox.shrink();
                },
                interval: 1,
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: counts.entries.map((entry) {
            return BarChartGroupData(
              x: entry.key,
              barRods: [
                BarChartRodData(toY: entry.value.toDouble(),
                    color: Colors.orange,
                    width: 16),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }


  Widget _buildWorldMap(List<ClothingItem> items) {
    final Map<String, int> countryCounts = {};
    for (var item in items) {
      if (item.countryOfOrigin != null) {
        countryCounts[item.countryOfOrigin!] =
            (countryCounts[item.countryOfOrigin!] ?? 0) + 1;
      }
    }

    final List<Country> allCountries = CountryService().getAll();
    final Map<String, String> nameToCode = {
      for (var country in allCountries) country.name: country.countryCode
          .toLowerCase()
    };

    return SizedBox(
      height: 300,
      width: double.infinity,
      child: SimpleMap(
        instructions: SMapWorld.instructions,

        defaultColor: Colors.grey[300],

        colors: countryCounts.keys.fold<Map<String, Color>>(
            {}, (map, countryName) {
          final code = nameToCode[countryName];
          if (code != null) {
            final count = countryCounts[countryName]!;
            Color color;
            if (count >= 10) {
              color = Colors.blue[900]!;
            } else if (count >= 5) {
              color = Colors.blue[700]!;
            } else if (count >= 2) {
              color = Colors.blue[500]!;
            } else {
              color = Colors.blue[300]!;
            }
            map[code] = color;
          }
          return map;
        }),
      ),
    );
  }
}