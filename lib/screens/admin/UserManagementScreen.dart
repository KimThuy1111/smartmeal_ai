import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/User.dart';
import '../../widgets/UserItemCard.dart';
import '../UserDetailScreen.dart';
import '../../controllers/UserController.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState
    extends State<UserManagementScreen> {

  final UserController _controller = UserController();

  List<User> users = [];
  bool loading = true;

  Map<String, int> stats = {};
  Map<String, String> ranges = {};

  String type = "week";

  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    loadUsers();
    loadStats();
  }

  /// Tải danh sách người dùng theo bộ lọc hiện tại
  Future<void> loadUsers() async {
    users = await _controller.getUsersByTime(
      type: type,
      month: selectedMonth,
      year: selectedYear,
    );

    setState(() {
      loading = false;
    });
  }

  /// Tải số liệu thống kê để vẽ biểu đồ
  Future<void> loadStats() async {
    setState(() {
      stats = {};
      ranges = {};
    });

    final data = await _controller.getUserStats(
      type: type,
      month: selectedMonth,
      year: selectedYear,
    );

    setState(() {
      stats = Map<String, int>.from(data["counts"]);
      ranges = Map<String, String>.from(data["ranges"]);
    });
  }

  /// Chuyển chuỗi có tiền tố thành số nguyên để sắp xếp
  int safeParse(String value, String prefix) {
    try {
      return int.parse(value.replaceAll(prefix, ""));
    } catch (e) {
      return 0;
    }
  }

  /// Tính giới hạn trục Y cho biểu đồ
  double getMaxY(List<MapEntry<String, int>> entries) {
    int max = 0;
    for (var e in entries) {
      if (e.value > max) max = e.value;
    }
    return (max + 2).toDouble();
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
          child: Column(
            children: [

              const SizedBox(height: 10),

              /// Thanh tiêu đề
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left, size: 28),
                    ),

                    const Expanded(
                      child: Center(
                        child: Text(
                          "Quản lý người dùng",
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    const SizedBox(width: 28),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// Chọn tháng và năm
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
                      loadStats();
                      loadUsers();

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
                      loadStats();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 10),

              /// Bộ lọc theo tuần, tháng, năm
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  filterBtn("Tuần", "week"),
                  filterBtn("Tháng", "month"),
                  filterBtn("Năm", "year"),

                ],
              ),

              const SizedBox(height: 10),

              /// Biểu đồ thống kê
              SizedBox(
                height: 180,
                child: buildChart(),
              ),

              const SizedBox(height: 10),

              /// Danh sách người dùng
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: users.length,
                  itemBuilder: (context, index) {

                    final user = users[index];

                    return UserItemCard(
                      avatar: user.avatar,
                      name: user.name,
                      email: user.email,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserDetailScreen(user: user),
                          ),
                        ).then((_) => loadUsers());
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Tạo nút lọc dữ liệu
  Widget filterBtn(String text, String value) {
    bool active = type == value;

    return GestureDetector(
      onTap: () {
        setState(() => type = value);
        loadStats();
        loadUsers();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: active ? Colors.white : Colors.green),
        ),
      ),
    );
  }

  /// Xây dựng biểu đồ cột thống kê người dùng
  Widget buildChart() {
    if (stats.isEmpty) {
      return const Center(child: Text("Không có dữ liệu"));
    }

    List<MapEntry<String, int>> entries = stats.entries.toList();

    /// Sắp xếp dữ liệu theo thứ tự thời gian
    entries.sort((a, b) {

      if (type == "week") {
        return safeParse(a.key, "Tuần ")
            .compareTo(safeParse(b.key, "Tuần "));
      }

      if (type == "month") {
        return safeParse(a.key, "Tháng ")
            .compareTo(safeParse(b.key, "Tháng "));
      }

      if (type == "year") {
        return safeParse(a.key, "Năm ")
            .compareTo(safeParse(b.key, "Năm "));
      }

      return 0;
    });

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
        maxY: getMaxY(entries),
        minY: 0,

        /// Nội dung hiển thị khi chạm vào cột
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {

              String key = entries[group.x.toInt()].key;
              String range = ranges[key] ?? "";

              return BarTooltipItem(
                "$key\n($range)\n${rod.toY.toInt()} users",
                const TextStyle(color: Colors.white),
              );
            },
          ),
        ),

        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),

        titlesData: FlTitlesData(

          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {

                int index = value.toInt();
                if (index >= entries.length) return const SizedBox();

                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    entries[index].key,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),

          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
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
}