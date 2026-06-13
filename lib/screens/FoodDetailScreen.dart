import 'package:flutter/material.dart';
import '../widgets/BackgroundGradient.dart';
import '../models/Food.dart';
import '../controllers/FoodController.dart';
import '../controllers/FoodCategoryController.dart';


class FoodDetailScreen extends StatefulWidget {
  final String foodId;

  const FoodDetailScreen({
    super.key,
    required this.foodId,
  });

  @override
  State<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends State<FoodDetailScreen> {

  final FoodController _foodController = FoodController();
  // final FoodCategoryController _categoryController = FoodCategoryController();

  Food? food;
  String? categoryName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFood();
  }

  // Xem thông tin món ăn
  Future<void> loadFood() async {
    final result = await _foodController.getFoodById(widget.foodId);
    setState(() {
      food = result;
      isLoading = false;
    });
  }

  // Tạo danh sách các chỉ số dinh dưỡng bổ sung
  List<Widget> buildNutritionList() {
    if (food == null) return [];

    final nutrients = <Map<String, dynamic>>[
      {"title": "Canxi", "value": food!.calcium, "unit": "mg"},
      {"title": "Sắt", "value": food!.iron, "unit": "mg"},
      {"title": "Kẽm", "value": food!.zinc, "unit": "mg"},
      {"title": "Natri", "value": food!.sodium, "unit": "mg"},
      {"title": "Magie", "value": food!.magnesium, "unit": "mg"},
      {"title": "Vitamin A", "value": food!.vitaminA, "unit": "µg"},
      {"title": "Kali", "value": food!.potassium, "unit": "mg"},
      {"title": "MUFA + PUFA", "value": food!.mufaPufa, "unit": "mg"},
    ];

    return nutrients
        .where((n) => n["value"] != null && n["value"] > 0)
        .map((n) => nutriRow(
              n["title"],
              "${n["value"]} ${n["unit"]}",
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (food == null) {
      return const Scaffold(
        body: Center(child: Text("Không tìm thấy dữ liệu")),
      );
    }
    return Scaffold(
      body: BackgroundGradient(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.chevron_left, size: 24),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Chi tiết món ăn",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(16),
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[300],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: buildFoodImage(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food!.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (food!.englishName != null &&
                          food!.englishName!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            food!.englishName!,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                if (categoryName != null && categoryName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F7FA),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        categoryName!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF00796B),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // Hiển thị tổng calories
                Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: const Color(0xFFC5E8D8),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        food!.calories.toStringAsFixed(0),
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A7F57),
                        ),
                      ),
                      const Text(
                        "Tổng Calo",
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      macroBox("Chất đạm", "${food!.protein} g"),
                      const SizedBox(width: 10),
                      macroBox("Chất béo", "${food!.fat} g"),
                      const SizedBox(width: 10),
                      macroBox("Carb", "${food!.carb} g"),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Thông tin dinh dưỡng chi tiết",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Hiển thị không có dữ liệu dinh dưỡng
                if (buildNutritionList().isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Không có dữ liệu dinh dưỡng",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                // 6. Hiển thị thông tin dinh dưỡng chi tiết
                else
                  ...buildNutritionList(),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Hiển thị ô chỉ số dinh dưỡng ngắn bên dưới calories
  Widget macroBox(String title, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              "$title\n$value",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  // Hiển thị một dòng thông tin dinh dưỡng chi tiết
  Widget nutriRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),
            Text(value, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }

  // Hiển thị hình ảnh món ăn hoặc ảnh mặc định khi không có ảnh
  Widget buildFoodImage() {
    if (food!.image == null || food!.image!.trim().isEmpty) {
      return Image.asset(
        "assets/images/default_food.png",
        fit: BoxFit.cover,
      );
    }
    return Image.network(
      food!.image!,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          "assets/images/default_food.png",
          fit: BoxFit.cover,
        );
      },
    );
  }
}