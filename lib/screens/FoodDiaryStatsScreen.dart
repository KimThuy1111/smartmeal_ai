import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../controllers/FoodDiaryController.dart';
import '../widgets/BackgroundGradient.dart';

class FoodDiaryStatsScreen extends StatefulWidget {
  final DateTime initialDate;

  const FoodDiaryStatsScreen({super.key, required this.initialDate});

  @override
  State<FoodDiaryStatsScreen> createState() => _FoodDiaryStatsScreenState();
}

class _FoodDiaryStatsScreenState extends State<FoodDiaryStatsScreen> {
  final FoodDiaryController _controller = FoodDiaryController();

  bool statsLoading = true;
  String? statsError;
  String selectedMode = 'week';
  late DateTime startDate;
  late DateTime endDate;
  Map<String, dynamic> periodStats = {};

  @override
  void initState() {
    super.initState();
    /// Mặc định mở lên sẽ là tuần hiện tại
    final now = widget.initialDate;

    /// Lấy thứ 2
    startDate = now.subtract(
      Duration(days: now.weekday - 1),
    );

    /// Lấy chủ nhật
    endDate = startDate.add(
      const Duration(days: 6),
    );
    _loadPeriodStats();
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );

    if (picked != null) {
      setState(() {
        startDate = picked.start;

        endDate = picked.end;
      });

      _loadPeriodStats();
    }
  }

  Future<void> _loadPeriodStats() async {
    setState(() {
      statsLoading = true;
      statsError = null;
    });

    try {
      final result = await _controller
          .loadPeriodStats(
            startDate: startDate,
            endDate: endDate,
            period: selectedMode,
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;

      setState(() {
        periodStats = result;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        // Dừng trạng thái tải khi Firestore lỗi hoặc mất mạng để màn hình không quay mãi.
        statsError = 'Không tải được thống kê, vui lòng kiểm tra kết nối mạng.';
      });
    } finally {
      if (mounted) {
        setState(() {
          statsLoading = false;
        });
      }
    }
  }

  void _changePeriod(String period) {
    if (selectedMode == period) return;
    setState(() {
      selectedMode = period;
    });
    _loadPeriodStats();
  }

  List<Map<String, dynamic>> get _dailyStats {
    final list = periodStats['dailyStats'];
    if (list is List) {
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  }

  double get _periodTargetCalories {
    final value = periodStats['targetCalories'];
    if (value is num) return value.toDouble();
    return 0;
  }

  double get _periodTotalCalories {
    final value = periodStats['totalCalories'];
    if (value is num) return value.toDouble();
    return 0;
  }

  double get _periodAverageCalories {
    final value = periodStats['averageCalories'];
    if (value is num) return value.toDouble();
    return 0;
  }

  int get _periodDaysWithData {
    final value = periodStats['daysWithData'];
    if (value is num) return value.toInt();
    return 0;
  }

  int get _periodOverDays {
    final value = periodStats['overDays'];
    if (value is num) return value.toInt();
    return 0;
  }

  String get _periodRangeText {
    final start = periodStats['startDate'];
    final end = periodStats['endDate'];
    if (start is DateTime && end is DateTime) {
      return '${_formatDate(start)} - ${_formatDate(end)}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundGradient(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left, size: 28),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          'Thống kê calo',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.calendar_month),
                      onPressed: _pickDateRange,
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ngày tham chiếu',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatDate(startDate)} - ${_formatDate(endDate)}',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_periodRangeText.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          _periodRangeText,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF4F7E64),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatsHeader(),
                const SizedBox(height: 12),
                _buildStatsSummary(),
                const SizedBox(height: 12),
                _buildStatsChart(),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [

          Expanded(
            child: _periodChip(
              label: 'Tuần',
              active: selectedMode == 'week',
              onTap: () {

                final now = DateTime.now();

                setState(() {

                  selectedMode = 'week';

                  startDate = now.subtract(
                    Duration(days: now.weekday - 1),
                  );

                  endDate = startDate.add(
                    const Duration(days: 6),
                  );
                });

                _loadPeriodStats();
              },
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _periodChip(
              label: 'Tháng',
              active: selectedMode == 'month',
              onTap: () {

                final now = DateTime.now();

                setState(() {

                  selectedMode = 'month';

                  startDate =
                      DateTime(now.year, now.month, 1);

                  endDate =
                      DateTime(now.year, now.month + 1, 0);
                });

                _loadPeriodStats();
              },
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: _periodChip(
              label: 'Chọn ngày',
              active: selectedMode == 'range',
              onTap: () async {

                setState(() {
                  selectedMode = 'range';
                });

                await _pickDateRange();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _periodChip({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          gradient:
              active
                  ? const LinearGradient(
                    colors: [Color(0xFF00C569), Color(0xFF6BE394)],
                  )
                  : null,
          color: active ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? Colors.transparent : const Color(0xFF00C569),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : const Color(0xFF00C569),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildStatsChart() {
    if (statsLoading) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (statsError != null) {
      return _buildStatsError();
    }

    final stats = _dailyStats;
    if (stats.isEmpty) {
      return Container(
        height: 250,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Text('Không có dữ liệu thống kê'),
      );
    }

    final maxValue = stats.fold<double>(_periodTargetCalories, (max, item) {
      final calories = (item['calories'] as num).toDouble();
      return calories > max ? calories : max;
    });
    final chartMaxY = (maxValue <= 0 ? 100.0 : maxValue * 1.2).ceilToDouble();

    return Container(
      height: 260,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                selectedMode == 'month'
                    ? 'Thống kê tháng ${startDate.month}'
                    : selectedMode == 'week'
                    ? 'Thống kê tuần'
                    : 'Thống kê khoảng ngày',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _legendDot(const Color(0xFF00C569), 'Đạt'),
              const SizedBox(width: 10),
              _legendDot(Colors.red, 'Vượt'),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: BarChart(
              BarChartData(
                maxY: chartMaxY,
                minY: 0,
                alignment: BarChartAlignment.spaceAround,
                extraLinesData: ExtraLinesData(
                  horizontalLines:
                      _periodTargetCalories > 0
                          ? [
                            HorizontalLine(
                              y: _periodTargetCalories,
                              color: const Color(0xFF1E88E5),
                              strokeWidth: 1.4,
                              dashArray: [6, 4],
                            ),
                          ]
                          : [],
                ),
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final item = stats[group.x.toInt()];
                      return BarTooltipItem(
                        '${item['label']}\n${rod.toY.toStringAsFixed(0)} kcal',
                        const TextStyle(color: Colors.white),
                      );
                    },
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMaxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.withValues(alpha: 0.18),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 38,
                      interval: chartMaxY / 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10, height: 1.3,),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= stats.length) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            stats[index]['label'].toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.12),
                  ),
                ),
                barGroups: List.generate(stats.length, (index) {
                  final calories = (stats[index]['calories'] as num).toDouble();
                  final isOver = stats[index]['isOver'] == true;

                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: calories,
                        width: 14,
                        borderRadius: BorderRadius.circular(6),
                        color: isOver ? Colors.red : const Color(0xFF00C569),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsError() {
    return Container(
      height: 250,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, color: Colors.red, size: 38),
          const SizedBox(height: 10),
          Text(
            statsError!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _loadPeriodStats,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildStatsSummary() {
    if (statsLoading || statsError != null) {
      return const SizedBox.shrink();
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.7,
      children: [
        _summaryCard(
          title: 'Tổng calo',
          value: _periodTotalCalories.toStringAsFixed(0),
          subtitle: 'kcal',
          accentColor: const Color(0xFF00A86B),
        ),
        _summaryCard(
          title: 'Trung bình/ngày',
          value: _periodAverageCalories.toStringAsFixed(0),
          subtitle: 'kcal',
          accentColor: const Color(0xFF1E88E5),
        ),
        _summaryCard(
          title: 'Ngày có dữ liệu',
          value: _periodDaysWithData.toString(),
          subtitle: 'ngày',
          accentColor: const Color(0xFF6D4C41),
        ),
        _summaryCard(
          title: 'Ngày vượt mức',
          value: _periodOverDays.toString(),
          subtitle: 'ngày',
          accentColor: const Color(0xFFD32F2F),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.white, Color(0xFFF3FFF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        border: Border.all(color: const Color(0xFFE2F4E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 4,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  height: 1,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  subtitle,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
