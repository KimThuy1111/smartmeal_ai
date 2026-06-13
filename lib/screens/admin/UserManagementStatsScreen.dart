import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/User.dart';
import '../../controllers/UserController.dart';

class UserManagementStatsScreen extends StatefulWidget {
  const UserManagementStatsScreen({super.key});

  @override
  State<UserManagementStatsScreen> createState() =>
      _UserManagementStatsScreenState();
}

class _UserManagementStatsScreenState
    extends State<UserManagementStatsScreen> {

  final UserController _controller = UserController();

  // Dữ liệu thống kê cho biểu đồ
  Map<String, int> stats = {};

  // Loại thống kê: week, month, year, day
  String type = "day";

  // Tháng và năm được chọn
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  // Ngày bắt đầu và kết thúc cho thống kê theo ngày
  DateTime selectedStartDate = DateTime.now();
  DateTime selectedEndDate = DateTime.now();

  // Tổng số lượng người dùng đăng ký trong khoảng thời gian
  int totalNewUsers = 0;

  // Biểu thị trạng thái loading
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _setDefaultWeekRange();
    _loadStats();
  }

  // Thiết lập mặc định khoảng thời gian từ thứ 2 đến chủ nhật của tuần hiện tại
  void _setDefaultWeekRange() {
    final now = DateTime.now();
    // Tính thứ 2 của tuần (weekday: 1 = Mon, 7 = Sun)
    final mondayOffset = now.weekday - 1;
    selectedStartDate = now.subtract(Duration(days: mondayOffset));
    // Tính chủ nhật của tuần hiện tại
    final sundayOffset = 7 - now.weekday;
    selectedEndDate = now.add(Duration(days: sundayOffset));
  }

  // Tải thống kê từ controller
  Future<void> _loadStats() async {
    try {
      setState(() {
        stats = {};
        totalNewUsers = 0;
      });

      late Map<String, dynamic> data;

      if (type == "day") {
        // Lấy thống kê theo ngày
        data = await _controller.getUserStatsByDay(
          startDate: selectedStartDate,
          endDate: selectedEndDate,
        );
      } else {
        // Lấy thống kê theo tuần/tháng/năm
        data = await _controller.getUserStats(
          type: type,
          month: selectedMonth,
          year: selectedYear,
        );
      }

      // Tính tổng số lượng người dùng mới
      int total = 0;
      final counts = Map<String, int>.from(data["counts"]);
      for (final count in counts.values) {
        total += count;
      }

      setState(() {
        stats = counts;
        totalNewUsers = total;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  // Chuyển chuỗi có tiền tố thành số nguyên để sắp xếp
  int _safeParse(String value, String prefix) {
    try {
      return int.parse(value.replaceAll(prefix, ""));
    } catch (e) {
      return 0;
    }
  }

  // Tìm giá trị max của dữ liệu
  int _getMaxValue(List<MapEntry<String, int>> entries) {
    int max = 0;
    for (var e in entries) {
      if (e.value > max) max = e.value;
    }
    return max;
  }

  // Sắp xếp dữ liệu theo thứ tự thời gian
  void _sortStatEntries(List<MapEntry<String, int>> entries) {
    entries.sort((a, b) {
      if (type == "week") {
        // Trích xuất số tuần từ key (Tuần 1\n(1-7) -> 1)
        final aWeek = int.tryParse(a.key.replaceAll(RegExp(r'[^\d]'), '').substring(0, 1)) ?? 0;
        final bWeek = int.tryParse(b.key.replaceAll(RegExp(r'[^\d]'), '').substring(0, 1)) ?? 0;
        return aWeek.compareTo(bWeek);
      }

      if (type == "month") {
        return _safeParse(a.key, "Tháng ")
            .compareTo(_safeParse(b.key, "Tháng "));
      }

      if (type == "day") {
        // Sắp xếp ngày theo định dạng dd/mm
        final aParts = a.key.split('/').map(int.parse).toList();
        final bParts = b.key.split('/').map(int.parse).toList();
        if (aParts[1] != bParts[1]) {
          return aParts[1].compareTo(bParts[1]);
        }
        return aParts[0].compareTo(bParts[0]);
      }

      return 0;
    });
  }

  // Mở date picker để chọn ngày bắt đầu
  Future<void> _selectStartDate(BuildContext context) async {

    FocusScope.of(context).unfocus();

    await Future.delayed(
      const Duration(milliseconds: 100),
    );

    if (!mounted) return;

    final picked = await showDateRangePicker(
      context: context,

      firstDate: DateTime(2020),

      lastDate: DateTime.now(),

      initialDateRange: DateTimeRange(

        start: selectedStartDate,

        end: selectedEndDate.isAfter(DateTime.now())
            ? DateTime.now()
            : selectedEndDate,
      ),

      builder: (context, child) {

        return Theme(

          data: Theme.of(context).copyWith(

            colorScheme: const ColorScheme.light(

              // màu header
              primary: Color(0xFF7E57C2),

              // màu text trên selected date
              onPrimary: Colors.white,

              // nền dialog
              surface: Colors.white,

              // màu text thường
              onSurface: Colors.black,
            ),

            datePickerTheme: DatePickerThemeData(

              backgroundColor: Colors.white,

              rangeSelectionBackgroundColor:
              const Color(0xFFD3C6EC),

              rangeSelectionOverlayColor:
              WidgetStateProperty.all(
                const Color(0xFF8661C6),
              ),

              dayForegroundColor:
              WidgetStateProperty.resolveWith((states) {

                if (states.contains(WidgetState.selected)) {
                  return Colors.white;
                }

                return Colors.black;
              }),

              dayBackgroundColor:
              WidgetStateProperty.resolveWith((states) {

                if (states.contains(WidgetState.selected)) {
                  return const Color(0xFF7E57C2);
                }

                return null;
              }),
            ),

            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),

          child: child!,
        );
      },
    );

    if (picked != null) {

      setState(() {

        selectedStartDate = picked.start;

        selectedEndDate = picked.end;
      });

      _loadStats();
    }
  }

  // Mở date picker để chọn ngày kết thúc
  Future<void> _selectEndDate(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: selectedStartDate, end: selectedEndDate),
    );

    if (picked != null) {
      setState(() {
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
      });
      _loadStats();
    }
  }

  // Tạo nút lọc dữ liệu
  Widget _filterButton(String text, String value) {
    bool isActive = type == value;

    return GestureDetector(
      onTap: () {
        setState(() => type = value);
        if (value == "day") {
          _setDefaultWeekRange();
        }
        _loadStats();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.green,
          ),
        ),
      ),
    );
  }

  // Xây dựng biểu đồ cột thống kê người dùng
  Widget _buildChart() {
    if (stats.isEmpty) {
      return const Center(child: Text("Không có dữ liệu"));
    }

    List<MapEntry<String, int>> entries = stats.entries.toList();
    _sortStatEntries(entries);

    final maxValue = _getMaxValue(entries).toDouble();
    final chartMaxY = (maxValue <= 0 ? 10.0 : maxValue * 1.2).ceilToDouble();
    
    // Tính interval để chỉ hiển thị các số nguyên (0, 1, 2, ...)
    double interval = 1.0;
    if (chartMaxY > 10) {
      interval = (chartMaxY / 5).ceilToDouble();
    }

    List<BarChartGroupData> bars = [];

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];

      bars.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entry.value.toDouble(),
              width: 16,
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF00C569),
                  Color(0xFF78F09C),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            )
          ],
        ),
      );
    }

    return BarChart(
      BarChartData(
        maxY: chartMaxY,
        minY: 0,
        alignment: BarChartAlignment.spaceAround,

        // Nội dung hiển thị khi chạm vào cột
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              String key = entries[group.x.toInt()].key;

              return BarTooltipItem(
                "$key\n${rod.toY.toInt()} users",
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: interval,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.18),
              strokeWidth: 1,
            );
          },
        ),

        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= entries.length) return const SizedBox();

                // Lấy phần đầu của key trước dấu \n
                String keyText = entries[index].key.split('\n')[0];

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    keyText,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),

          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 38,
              interval: interval,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, height: 1.3),
                );
              },
            ),
          ),

          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),

          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),

        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.green.withOpacity(0.2),
          ),
        ),

        barGroups: bars,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Thanh tiêu đề
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.chevron_left, size: 28),
                      ),

                      const Expanded(
                        child: Center(
                          child: Text(
                            "Thống kê người dùng",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(width: 28),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Bộ lọc theo tuần, tháng, năm, ngày
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _filterButton("Ngày", "day"),
                    _filterButton("Tuần", "week"),
                    _filterButton("Tháng", "month"),
                    _filterButton("Năm", "year"),
                  ],
                ),

                const SizedBox(height: 10),

                // Chọn tháng/năm hoặc chọn khoảng ngày
                if (type != "day")
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<int>(
                        value: selectedMonth,
                        items: List.generate(12, (i) => i + 1)
                            .map((m) => DropdownMenuItem(
                              value: m,
                              child: Text("T$m"),
                            ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => selectedMonth = v!);
                          _loadStats();
                        },
                      ),

                      const SizedBox(width: 20),

                      DropdownButton<int>(
                        value: selectedYear,
                        items: List.generate(5, (i) => 2022 + i)
                            .map((y) => DropdownMenuItem(
                              value: y,
                              child: Text("$y"),
                            ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => selectedYear = v!);
                          _loadStats();
                        },
                      ),
                    ],
                  )
                else
                  GestureDetector(
                    onTap: () {
                      _selectStartDate(context);
                    },
                    child: Container(
                      width: double.infinity,

                      margin: const EdgeInsets.only(
                        bottom: 10,
                      ),

                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),

                        borderRadius: BorderRadius.circular(22),

                        border: Border.all(
                          color: const Color(0xFF00C569),
                          width: 1.2,
                        ),

                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 5,
                          ),
                        ],
                      ),

                      child: Row(
                        children: [

                          const Icon(
                            Icons.calendar_month,
                            color: Color(0xFF00C569),
                            size: 22,
                          ),

                          const SizedBox(width: 10),

                          Expanded(
                            child: Text(
                              '${selectedStartDate.day}/${selectedStartDate.month}/${selectedStartDate.year}'
                                  ' - '
                                  '${selectedEndDate.day}/${selectedEndDate.month}/${selectedEndDate.year}',

                              style: const TextStyle(
                                color: Color(0xFF00A86B),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Tổng số người dùng đăng ký mới
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 6),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Tổng đăng ký mới:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF00C569),
                              Color(0xFF78F09C),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$totalNewUsers users',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Biểu đồ thống kê
                Container(
                  width: double.infinity,
                  height: 260,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                  ),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildChart(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
