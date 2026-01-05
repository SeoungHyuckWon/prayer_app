import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:prayer_app/models/gratitude.dart';
import 'package:prayer_app/models/prayer.dart';
import 'package:prayer_app/services/firestore_service.dart';
import 'dart:math';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _barAnimationController;
  late Animation<double> _barAnimation;

  @override
  void initState() {
    super.initState();
    _barAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _barAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _barAnimationController, curve: Curves.easeOut),
    );
    _barAnimationController.forward();
  }

  @override
  void dispose() {
    _barAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        backgroundColor: Colors.teal[100],
      ),
      body: StreamBuilder<List<Prayer>>(
        stream: FirestoreService().getPrayersStream(),
        builder: (context, prayerSnapshot) {
          return StreamBuilder<List<Gratitude>>(
            stream: FirestoreService().getGratitudesStream(),
            builder: (context, gratitudeSnapshot) {
              if (prayerSnapshot.connectionState == ConnectionState.waiting ||
                  gratitudeSnapshot.connectionState ==
                      ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final prayers = prayerSnapshot.data ?? [];
              final gratitudes = gratitudeSnapshot.data ?? [];

              if (prayers.isEmpty && gratitudes.isEmpty) {
                return const Center(child: Text('데이터가 없습니다.'));
              }

              final prayerCounts = _getCounts(prayers);
              final gratitudeCounts = _getCounts(gratitudes);

              final maxPrayerCount = prayerCounts.values.fold(0, max);
              final maxGratitudeCount = gratitudeCounts.values.fold(0, max);

              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        '한 주간 나의 감사',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),
                      _buildStreakWidget(gratitudeCounts, '감사'),
                      const SizedBox(height: 30),
                      _buildBarChart(context, gratitudeCounts,
                          maxGratitudeCount.toDouble(), '감사'),
                      const SizedBox(height: 30),
                      const Text(
                        '한 주간 나의 기도',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30),
                      _buildStreakWidget(prayerCounts, '기도'),
                      const SizedBox(height: 30),
                      _buildBarChart(context, prayerCounts,
                          maxPrayerCount.toDouble(), '기도'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Map<int, int> _getCounts(List<dynamic> items) {
    final now = DateTime.now();
    final counts = <int, int>{};
    // Initialize counts for 7 days (0 for Monday, 6 for Sunday)
    for (var i = 0; i < 7; i++) {
      counts[i] = 0;
    }

    for (var item in items) {
      final itemDate = item.createdAt;
      // Consider only items from the last 7 days
      if (itemDate.isAfter(now.subtract(const Duration(days: 7)))) {
        // Get weekday (1 for Monday, 7 for Sunday), convert to 0-indexed (0 for Monday, 6 for Sunday)
        final weekdayIndex = itemDate.weekday - 1;
        if (weekdayIndex >= 0 && weekdayIndex < 7) {
          // Ensure it's within bounds
          counts[weekdayIndex] = (counts[weekdayIndex] ?? 0) + 1;
        }
      }
    }
    return counts;
  }

  int _getConsecutiveDays(Map<int, int> counts) {
    final todayIndex = DateTime.now().weekday - 1; // 0=Monday, 6=Sunday
    int consecutive = 0;
    // Check from today backwards
    for (int i = todayIndex; i >= 0; i--) {
      if (counts[i]! > 0) {
        consecutive++;
      } else {
        break;
      }
    }
    // If we reached Monday and still consecutive, check Sunday to today
    if (consecutive == todayIndex + 1) {
      for (int i = 6; i > todayIndex; i--) {
        if (counts[i]! > 0) {
          consecutive++;
        } else {
          break;
        }
      }
    }
    return consecutive;
  }

  Widget _buildBarChart(
      BuildContext context, Map<int, int> counts, double maxY, String name) {
    // Check if all counts are zero
    if (counts.values.every((count) => count == 0)) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Text(
            '최근 $name 기록이 없습니다.',
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _barAnimation,
      builder: (context, child) {
        return Center(
            child: SizedBox(
          height: 300,
          width: MediaQuery.of(context).size.width * 0.8, // Reduce width to 80%
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment
                  .center, // Changed from spaceAround to center
              groupsSpace: 30, // Increase space between bar groups
              maxY: (maxY == 0
                  ? 5
                  : maxY + (maxY * 0.2)), // Add 20% padding to max Y
              barTouchData: BarTouchData(
                enabled: false,
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const dayNames = [
                        '월',
                        '화',
                        '수',
                        '목',
                        '금',
                        '토',
                        '일'
                      ]; // Starting from Monday (index 0)
                      // Adjust value to be 0-indexed for days, assuming Sunday is last
                      final int dayIndex = value.toInt();
                      if (dayIndex >= 0 && dayIndex < dayNames.length) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          space: 4,
                          child: Text(dayNames[dayIndex],
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 10)),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 28,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 20,
                    getTitlesWidget: (value, meta) {
                      if (value != 0 &&
                          value %
                                  ((maxY / 5).ceil() == 0
                                      ? 1
                                      : (maxY / 5).ceil()) ==
                              0) {
                        return Text(value.toInt().toString(),
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 10));
                      }
                      return const Text('');
                    },
                  ),
                ),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: false,
              ),
              borderData: FlBorderData(
                show: false,
              ),
              barGroups: _createSingleBarGroups(counts, _barAnimation.value),
            ),
            swapAnimationDuration: const Duration(milliseconds: 1500),
          ),
        ));
      },
    );
  }

  List<BarChartGroupData> _createSingleBarGroups(
      Map<int, int> counts, double animationValue) {
    final pastelColors = [
      Colors.pink[200]!,
      Colors.blue[200]!,
      Colors.green[200]!,
      Colors.yellow[200]!,
      Colors.purple[200]!,
      Colors.orange[200]!,
      Colors.teal[200]!,
    ];
    return List.generate(7, (index) {
      // `index` here directly corresponds to the weekdayIndex from _getCounts (0=Mon, ..., 6=Sun)
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
              toY: (counts[index]?.toDouble() ?? 0) *
                  animationValue, // Animate from 0 to actual value
              color: pastelColors[index],
              width: 12, // Slightly increased bar width
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              )),
        ],
      );
    });
  }

  Widget _buildStreakWidget(Map<int, int> counts, String name) {
    final consecutive = _getConsecutiveDays(counts);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            consecutive == 0
                ? '😢'
                : consecutive >= 4
                    ? '🥰'
                    : '😊',
            style: const TextStyle(fontSize: 90),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              consecutive == 0
                  ? '최근 $name 기록이 없어요.'
                  : '$consecutive 일 연속 $name 제목 \n작성 중이에요!',
              style: TextStyle(fontSize: 22, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
}
