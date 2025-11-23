import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../core/dio_client.dart';
import '../auth/providers.dart';

// Provider for statistics data
final statisticsServiceProvider = Provider((ref) {
  return StatisticsService(ref.read(dioClientProvider));
});

final weeklyStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return ref.watch(statisticsServiceProvider).getWeeklyStats();
});

class StatisticsService {
  final DioClient _client;
  StatisticsService(this._client);

  Future<Map<String, dynamic>> getWeeklyStats() async {
    try {
      final res = await _client.get('/statistics/weekly');
      return Map<String, dynamic>.from(res.data);
    } catch (e) {
      throw Exception('Failed to get weekly stats: $e');
    }
  }

  Future<List<dynamic>> getDailyStats(DateTime from, DateTime to) async {
    try {
      final res = await _client.get('/statistics/daily', queryParameters: {
        'from': from.toIso8601String().split('T')[0],
        'to': to.toIso8601String().split('T')[0],
      });
      return res.data as List;
    } catch (e) {
      throw Exception('Failed to get daily stats: $e');
    }
  }
}

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  String _selectedMetric = 'calories';
  // ignore: prefer_final_fields
  int _streakCurrent = 10;
  // ignore: prefer_final_fields
  int _streakLongest = 14;
  // ignore: prefer_final_fields
  int _daysAboveGoal = 6;
  // ignore: prefer_final_fields
  int _daysBelowGoal = 8;

  @override
  Widget build(BuildContext context) {
    final weeklyStats = ref.watch(weeklyStatsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('THỐNG KÊ'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: () {
            ref.invalidate(weeklyStatsProvider);
          }),
        ],
      ),
      body: weeklyStats.when(
        data: (stats) => _buildContent(stats),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Lỗi: $e')),
      ),
    );
  }

  Widget _buildContent(Map<String, dynamic> stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Metric Selector
          _buildMetricSelector(),
          const SizedBox(height: 20),

          // Chart
          _buildChart(stats),
          const SizedBox(height: 24),

          // Stats Summary
          _buildStatsSummary(stats),
          const SizedBox(height: 24),

          // Streak Info
          _buildStreakInfo(),
        ],
      ),
    );
  }

  Widget _buildMetricSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildMetricButton(
            'Calories',
            'calories',
            Icons.local_fire_department,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricButton(
            'Nước',
            'water',
            Icons.water_drop,
            AppColors.waterBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricButton(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedMetric == value;
    return InkWell(
      onTap: () => setState(() => _selectedMetric = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          // ignore: deprecated_member_use
          color: isSelected ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(Map<String, dynamic> stats) {
    final dailyData = stats['dailyBreakdown'] as List? ?? [];
    
    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < dailyData.length) {
                    final date = dailyData[value.toInt()]['date'] as String;
                    final day = date.split('-').last;
                    return Text(day, style: const TextStyle(fontSize: 12));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 40),
            ),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: _getChartSpots(dailyData),
              isCurved: true,
              color: _selectedMetric == 'calories'
                  ? Colors.orange
                  : AppColors.waterBlue,
              barWidth: 3,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: (_selectedMetric == 'calories'
                        ? Colors.orange
                        : AppColors.waterBlue)
                    // ignore: deprecated_member_use
                    .withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _getChartSpots(List dailyData) {
    final spots = <FlSpot>[];
    for (int i = 0; i < dailyData.length; i++) {
      final data = dailyData[i];
      final value = _selectedMetric == 'calories'
          ? (data['caloriesIn'] as num? ?? 0).toDouble()
          : (data['waterMl'] as num? ?? 0).toDouble() / 100; // Scale down water
      spots.add(FlSpot(i.toDouble(), value));
    }
    return spots;
  }

  Widget _buildStatsSummary(Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tổng quan tuần này',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Trung bình/ngày',
                '${stats['avgCaloriesInPerDay'] ?? 0}',
                'kcal',
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Đã tiêu',
                '${stats['avgCaloriesOutPerDay'] ?? 0}',
                'kcal/ngày',
                AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Nước TB/ngày',
                '${stats['avgWaterPerDay'] ?? 0}',
                'ml',
                AppColors.waterBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Tổng calo',
                '${stats['totalCaloriesIn'] ?? 0}',
                'kcal',
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, String unit, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thành tích',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStreakItem('🔥', 'Streak hiện tại', _streakCurrent),
                  _buildStreakItem('🏆', 'Streak dài nhất', _streakLongest),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStreakItem('✅', 'Vượt mục tiêu', _daysAboveGoal),
                  _buildStreakItem('📊', 'Dưới mục tiêu', _daysBelowGoal),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakItem(String emoji, String label, int value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ],
    );
  }
}