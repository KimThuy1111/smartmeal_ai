import 'package:flutter/material.dart';

import '../controllers/HomeController.dart';
import '../widgets/Footer.dart';
import 'SearchFoodScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController _controller = HomeController();

  String name = '';
  String goal = '';
  int calories = 0;

  double protein = 0;
  double carb = 0;
  double fat = 0;

  double eatenProtein = 0;
  double eatencarb = 0;
  double eatenFat = 0;

  List<String> breakfastFoods = [];
  List<String> lunchFoods = [];
  List<String> dinnerFoods = [];

  double breakfastCal = 0;
  double lunchCal = 0;
  double dinnerCal = 0;

  double fabX = 300;
  double fabY = 520;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Tải dữ liệu trang chủ từ controller và cập nhật UI.
  Future<void> _loadData() async {
    final data = await _controller.loadHomeData();

    setState(() {
      name = data['name'];
      goal = data['goal'];
      calories = data['calories'];

      protein = data['protein'];
      carb = data['carb'];
      fat = data['fat'];

      breakfastFoods = List<String>.from(data['breakfastFoods']);
      lunchFoods = List<String>.from(data['lunchFoods']);
      dinnerFoods = List<String>.from(data['dinnerFoods']);

      breakfastCal = data['breakfastCal'];
      lunchCal = data['lunchCal'];
      dinnerCal = data['dinnerCal'];

      eatenProtein = data['eatenProtein'];
      eatencarb = data['eatencarb'];
      eatenFat = data['eatenFat'];
    });

    // 10. Dữ liệu dinh dưỡng sẽ được hiển thị trên trang chủ.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE4FFE4), Colors.white],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    child: Column(
                      children: [
                        // Header section with user info
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                          child: RichText(
                            text: TextSpan(
                              children: [
                                const TextSpan(
                                  text: 'Chào buổi sáng, ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF888888),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                TextSpan(
                                  text: name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF333333),
                                  ),
                                ),
                                const TextSpan(
                                  text: ' 👋',
                                  style: TextStyle(
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: _buildNutritionCircle(),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 5,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF00C569),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    'Tiến độ hôm nay',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF333333),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _buildMealCard(
                                icon: Icons.breakfast_dining,
                                title: 'Bữa sáng',
                                recommend: (calories * 0.3).round(),
                                eaten: breakfastCal,
                                foods: breakfastFoods,
                              ),
                              _buildMealCard(
                                icon: Icons.wb_sunny,
                                title: 'Bữa trưa',
                                recommend: (calories * 0.4).round(),
                                eaten: lunchCal,
                                foods: lunchFoods,
                              ),
                              _buildMealCard(
                                icon: Icons.nightlight_round,
                                title: 'Bữa tối',
                                recommend: (calories * 0.3).round(),
                                eaten: dinnerCal,
                                foods: dinnerFoods,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
                const Footer(currentIndex: 0),
              ],
            ),
          ),
          Positioned(
            left: fabX,
            top: fabY,
            child: GestureDetector(
              // Cho phép kéo thả vị trí nút thêm món ăn trên màn hình.
              onPanUpdate: (details) {
                setState(() {
                  fabX += details.delta.dx;
                  fabY += details.delta.dy;
                });
              },
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SearchFoodScreen(),
                    ),
                  ).then((_) => _loadData());
                },
                child: const Icon(
                  Icons.add_circle,
                  color: Color(0xFF00C569),
                  size: 50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 8. Vòng tròn calo cập nhật theo lượng calo đã tiêu thụ
  // Hiển thị vòng tròn calories tổng và các thanh tiến trình dinh dưỡng.
  Widget _buildNutritionCircle() {
    // Xác định màu sắc của vòng tròn dựa trên lượng calo tiêu thụ
    Color circleColor = const Color(0xFF00C569); // Xanh - trong mục tiêu
    String calorieStatus = 'Trong mục tiêu';
    
    // 8a. Vòng tròn calo chuyển sang màu đỏ
    if (calories > 0 && goal.isNotEmpty) {
      int goalValue = int.tryParse(goal.split(' ')[0]) ?? 0;
      if (calories > goalValue) {
        circleColor = const Color(0xFFFF6B6B); // Đỏ - vượt quá mục tiêu
        calorieStatus = 'Vượt quá mục tiêu';
      }
    }
    
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                circleColor.withValues(alpha: 0.1),
                circleColor.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: circleColor,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: circleColor.withValues(alpha: 0.12),
                blurRadius: 16,
                spreadRadius: 3,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                calories.toString(),
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: circleColor,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Calories',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF666666),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: circleColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Mục tiêu: $goal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: circleColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: _macroBar('Carb', eatencarb, carb)),
            const SizedBox(width: 20),
            Expanded(child: _macroBar('Protein', eatenProtein, protein)),
            const SizedBox(width: 20),
            Expanded(child: _macroBar('Fat', eatenFat, fat)),
          ],
        ),
      ],
    );
  }

  // Tạo thanh tiến trình cho một chỉ số macro và giới hạn phần trăm tối đa 100%.
  Widget _macroBar(String title, double value, double goal, {String unit = 'g'}) {
    double percent = goal == 0 ? 0 : value / goal;
    if (percent > 1) {
      percent = 1;
    }

    Color barColor = value <= goal
        ? const Color(0xFF00C569)
        : const Color(0xFFFF6B6B);

    return SizedBox(
      width: 70,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                height: 14,
                width: double.infinity,
                color: const Color(0xFFEEEEEE),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: percent,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: value <= goal
                                ? [const Color(0xFF79EEF2), const Color(0xFF78F09C)]
                                : [const Color(0xFFFF8A80), const Color(0xFFFF6B6B)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${value.toStringAsFixed(0)}/${goal.toStringAsFixed(0)}$unit',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  // Hiển thị thẻ thông tin của từng bữa ăn kèm calories đã ăn và còn lại/vượt.
  Widget _buildMealCard({
    required IconData icon,
    required String title,
    required int recommend,
    required double eaten,
    required List<String> foods,
  }) {
    String subtitle;
    bool isOver = eaten > recommend;
    double percent = recommend == 0 ? 0 : eaten / recommend;
    if (percent > 1) percent = 1;

    if (eaten == 0) {
      subtitle = 'Khuyến nghị: $recommend kcal';
    } else {
      final double remain = recommend - eaten;
      subtitle =
          '${eaten.toStringAsFixed(0)} / $recommend kcal • '
          '${remain >= 0 ? 'Còn lại' : 'Vượt'} '
          '${remain.abs().toStringAsFixed(0)} kcal';
    }

    const Gradient iconGradient = LinearGradient(
      colors: [Color(0xFF79EEF2), Color(0xFF78F09C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF7FCF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFDFF3E6),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3FA26A).withValues(alpha: 0.08),
            blurRadius: 14,
            spreadRadius: -2,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ShaderMask(
                shaderCallback: (bounds) => iconGradient.createShader(bounds),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF252525),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (foods.isNotEmpty)
                      Text(
                        foods.join(', '),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF707070),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (foods.isEmpty)
                      const Text(
                        'Chưa có dữ liệu',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFFB0B0B0),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF8B8B8B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () {
                    // 1. Người dùng mở giao diện tra cứu món ăn
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SearchFoodScreen(),
                      ),
                    ).then((_) => _loadData());
                  },
                  child: Ink(
                    width: 34,
                    height: 34,
                  ),
                ),
              ),
            ],
          ),
          if (eaten > 0) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOver
                      ? const Color(0xFFFFCDD2)
                      : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${eaten.toStringAsFixed(0)} kcal',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isOver
                        ? const Color(0xFFC62828)
                        : const Color(0xFF2E7D32),
                  ),
                ),
              ),
            ),
          ],
          if (eaten > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 6,
                width: double.infinity,
                color: const Color(0xFFEEEEEE),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: percent,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isOver
                                ? [const Color(0xFFFF8A80), const Color(0xFFFF6B6B)]
                                : [const Color(0xFF79EEF2), const Color(0xFF78F09C)],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}