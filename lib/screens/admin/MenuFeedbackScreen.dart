import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../models/User.dart';
import 'MenuDetailScreen.dart';
import '../../controllers/MenuFeedbackController.dart';
import 'MenuFeedbackTrendScreen.dart';

class MenuFeedbackScreen extends StatefulWidget {
  const MenuFeedbackScreen({super.key});

  @override
  State<MenuFeedbackScreen> createState() =>
      _MenuFeedbackScreenState();
}

class _MenuFeedbackScreenState
    extends State<MenuFeedbackScreen> {

  final MenuFeedbackController _controller =
  MenuFeedbackController();

  bool loading = true;

  int likeCount = 0;
  int dislikeCount = 0;
  int notRatedCount = 0;

  String filter = "all";

  List<Map<String, dynamic>> menus = [];

  @override
  void initState() {
    super.initState();
    loadMenus();
  }

  // Tải dữ liệu đánh giá thực đơn từ hệ thống
  Future<void> loadMenus() async {

    final data = await _controller.loadMenus();

    if (!mounted) {
      return;
    }

    setState(() {
      menus = data["menus"];
      likeCount = data["likeCount"];
      dislikeCount = data["dislikeCount"];
      notRatedCount = data["notRatedCount"];
      loading = false;
    });
  }

  // Tính tỉ lệ thực đơn được thích
  double get likeRate {

    int total = likeCount + dislikeCount;

    if (total == 0) return 0;

    return likeCount / total * 100;
  }

  @override
  Widget build(BuildContext context) {

    final filteredMenus = menus.where((m) {

      if (filter == "like") return m["liked"] == true;
      if (filter == "dislike") return m["liked"] == false;
      if (filter == "none") return m["liked"] == null;

      return true;

    }).toList();

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

              Row(
                children: [

                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => Navigator.pop(context),
                  ),

                  const Expanded(
                    child: Center(
                      child: Text(
                        "Đánh giá thực đơn AI",
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

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const MenuFeedbackTrendScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.show_chart),
                        label: const Text('Xem biểu đồ tuần / tháng'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF00A651),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: const BorderSide(color: Color(0xFF00A651)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tỉ lệ phù hợp tổng quan
              Text(
                "Tỉ lệ phù hợp ${likeRate.toStringAsFixed(1)}%",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              // Biểu đồ và chú thích
              buildPieChart(),

              const SizedBox(height: 10),

              buildLegend(),

              const SizedBox(height: 20),

              // Danh sách các thực đơn đã đánh giá
              Expanded(
                child: loading
                    ? const Center(
                    child: CircularProgressIndicator())
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredMenus.length,
                  itemBuilder: (context, index) {

                    final item = filteredMenus[index];
                    final user = item["user"] as User;
                    final foods =
                    item["foods"] as List<String>;

                    String foodText = foods.join(", ");

                    if (foodText.length > 50) {
                      foodText =
                          foodText.substring(0, 50) + "...";
                    }

                    return GestureDetector(

                      onTap: () {

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                MenuDetailScreen(
                                  user: user,
                                  menu: item["menu"],
                                ),
                          ),
                        );

                      },

                      child: Container(

                        margin:
                        const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius:
                          BorderRadius.circular(20),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6)
                          ],
                        ),

                        child: Row(
                          children: [

                            CircleAvatar(
                              radius: 28,
                              backgroundImage:
                              NetworkImage(user.avatar),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    user.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    foodText,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildPieChart() {

    int total =
        likeCount + dislikeCount + notRatedCount;

    double likePercent =
    total == 0 ? 0 : likeCount / total * 100;
    double dislikePercent =
    total == 0 ? 0 : dislikeCount / total * 100;
    double nonePercent =
    total == 0 ? 0 : notRatedCount / total * 100;

    final bool hasData = total > 0;

    return SizedBox(
      height: 250,
      child: Center(
        child: SizedBox(
          width: 240,
          height: 240,
          child: PieChart(
            PieChartData(
              sectionsSpace: 0,
              centerSpaceRadius: 0,
              sections: [
                PieChartSectionData(
                  value: likeCount.toDouble(),
                  color: const Color(0xFF6FD98A),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC8FACC), Color(0xFF4FB96E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  radius: 82,
                  title: hasData ? "${likePercent.toStringAsFixed(0)}%" : "",
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                PieChartSectionData(
                  value: dislikeCount.toDouble(),
                  color: const Color(0xFFE04545),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFB2B2), Color(0xFFC62828)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  radius: 82,
                  title: hasData ? "${dislikePercent.toStringAsFixed(0)}%" : "",
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                PieChartSectionData(
                  value: notRatedCount.toDouble(),
                  color: const Color(0xFFE8B83D),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFF2B8), Color(0xFFE0A800)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  radius: 82,
                  title: hasData ? "${nonePercent.toStringAsFixed(0)}%" : "",
                  titleStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 3,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hiển thị chú thích màu của biểu đồ
  Widget buildLegend() {

    return Row(
      children: [
        Expanded(child: legendPill(const Color(0xFF79D996), "Thích", "like")),
        const SizedBox(width: 8),
        Expanded(child: legendPill(const Color(0xFFE04545), "Không Thích", "dislike")),
        const SizedBox(width: 8),
        Expanded(child: legendPill(const Color(0xFFE8B83D), "Chưa đánh giá", "none")),
      ],
    );
  }

    // Tạo một mục chú thích có thể bấm để lọc dữ liệu
  Widget legendPill(
      Color color, String text, String type) {

    bool active = filter == type;

    return GestureDetector(

      onTap: () {
        setState(() {
          filter = type;
        });
      },

      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Colors.grey[200] : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.grey.shade400),
        ),

        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),

            const SizedBox(width: 8),

            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}