import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../controllers/MenuFeedbackController.dart';

class MenuFeedbackTrendScreen extends StatefulWidget {
  const MenuFeedbackTrendScreen({super.key});

  @override
  State<MenuFeedbackTrendScreen> createState() => _MenuFeedbackTrendScreenState();
}

class _MenuFeedbackTrendScreenState extends State<MenuFeedbackTrendScreen> {
  final MenuFeedbackController _controller = MenuFeedbackController();

  bool loading = true;
  String period = 'week';
  int selectedIndex = 0;
  Map<String, dynamic>? stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => loading = true);

    final data = await _controller.loadTrendStats(
      period: period,
      selectedIndex: selectedIndex,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      stats = data;
      loading = false;
    });
  }

  void _changePeriod(String value) {
    if (period == value) {
      return;
    }

    setState(() {
      period = value;
      selectedIndex = 0;
    });
    _loadStats();
  }

  void _selectIndex(int value) {
    if (selectedIndex == value) {
      return;
    }

    setState(() {
      selectedIndex = value;
    });
    _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    final labels = (stats?['labels'] as List<dynamic>?)?.cast<String>() ?? [];
    final likes = (stats?['likes'] as List<dynamic>?)?.cast<int>() ?? [];
    final dislikes = (stats?['dislikes'] as List<dynamic>?)?.cast<int>() ?? [];
    final options = (stats?['options'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [];

    final currentLikeRate = (stats?['currentLikeRate'] ?? 0).toDouble();
    final previousLikeRate = (stats?['previousLikeRate'] ?? 0).toDouble();
    final improvement = (stats?['improvement'] ?? 0).toDouble();
    final currentLikeCount = stats?['currentLikeCount'] ?? 0;
    final currentDislikeCount = stats?['currentDislikeCount'] ?? 0;
    final range = stats?['range'] ?? '';
    final title = stats?['title'] ?? 'Thống kê gợi ý thực đơn';
    final safeIndex = options.isEmpty ? 0 : selectedIndex.clamp(0, options.length - 1).toInt();
    final selectedOption = options.isEmpty ? null : options[safeIndex];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE4FFE4), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Thống kê gợi ý thực đơn',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: _periodButton(
                                    label: 'Tuần',
                                    active: period == 'week',
                                    onTap: () => _changePeriod('week'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _periodButton(
                                    label: 'Tháng',
                                    active: period == 'month',
                                    onTap: () => _changePeriod('month'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _periodButton(
                                    label: 'Năm',
                                    active: period == 'year',
                                    onTap: () => _changePeriod('year'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.white),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    range,
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 13,
                                    ),
                                  ),
                                  if (selectedOption != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      selectedOption['label'] ?? '',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF00A651),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _summaryCard(
                                    title: 'Tỉ lệ thích',
                                    value: '${currentLikeRate.toStringAsFixed(1)}%',
                                    subtitle: 'Kỳ trước ${previousLikeRate.toStringAsFixed(1)}%',
                                    icon: Icons.thumb_up,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _summaryCard(
                                    title: 'Cải thiện',
                                    value: '${improvement >= 0 ? '+' : ''}${improvement.toStringAsFixed(1)}%',
                                    subtitle: 'So với kỳ trước',
                                    icon: Icons.trending_up,
                                    color: improvement >= 0 ? Colors.green : Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _countCard(
                                    label: 'Thích',
                                    value: currentLikeCount.toString(),
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _countCard(
                                    label: 'Không thích',
                                    value: currentDislikeCount.toString(),
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (period != 'week' && options.isNotEmpty)
                              SizedBox(
                                height: 52,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: options.length,
                                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final item = options[index];
                                    final active = index == selectedIndex;
                                    return GestureDetector(
                                      onTap: () => _selectIndex(index),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: active ? const Color(0xFF00A651) : Colors.white,
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: active ? const Color(0xFF00A651) : Colors.grey.shade300,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.04),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              item['label'] ?? '',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                color: active ? Colors.white : Colors.grey[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            if (period != 'week' && options.isNotEmpty) const SizedBox(height: 8),
                            if (period != 'week' && options.isNotEmpty)
                              Text(
                                options.isNotEmpty && selectedIndex < options.length
                                    ? (options[selectedIndex]['range'] ?? '')
                                    : '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 8,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Biểu đồ đường thống kê',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  SizedBox(
                                    height: 240,
                                    child: labels.isEmpty || likes.isEmpty || dislikes.isEmpty
                                        ? const Center(
                                            child: Text('Chưa có đủ dữ liệu để vẽ biểu đồ'),
                                          )
                                        : LineChart(
                                            _buildChartData(labels, likes, dislikes),
                                          ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      _legendItem(Colors.green, 'Thích'),
                                      const SizedBox(width: 16),
                                      _legendItem(Colors.red, 'Không thích'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _periodButton({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: const Color(0xFFBDBDBD)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: active ? const Color(0xFF00A651) : Colors.grey[700],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _countCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(label),
      ],
    );
  }

  LineChartData _buildChartData(List<String> labels, List<int> likes, List<int> dislikes) {
    final maxValue = [
      ...likes.map((e) => e.toDouble()),
      ...dislikes.map((e) => e.toDouble()),
    ].fold<double>(0, (prev, element) => element > prev ? element : prev);

    return LineChartData(
      minY: 0,
      maxY: (maxValue + 1).clamp(2, 100).toDouble(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 1,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withValues(alpha: 0.15),
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value % 1 != 0) {
                return const SizedBox.shrink();
              }
              return Text(
                value.toInt().toString(),
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 34,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= labels.length) {
                return const SizedBox.shrink();
              }

              if (labels.length > 10 && index % 2 != 0) {
                return const SizedBox.shrink();
              }

              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  labels[index],
                  style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: List.generate(likes.length, (index) => FlSpot(index.toDouble(), likes[index].toDouble())),
          isCurved: true,
          color: Colors.green,
          barWidth: 1.8,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withValues(alpha: 0.08),
          ),
        ),
        LineChartBarData(
          spots: List.generate(dislikes.length, (index) => FlSpot(index.toDouble(), dislikes[index].toDouble())),
          isCurved: true,
          color: Colors.red,
          barWidth: 1.8,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.red.withValues(alpha: 0.08),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipRoundedRadius: 12,
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final series = spot.barIndex == 0 ? 'Thích' : 'Không thích';
              return LineTooltipItem(
                '$series\n${spot.y.toInt()}',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              );
            }).toList();
          },
        ),
      ),
    );
  }
}
