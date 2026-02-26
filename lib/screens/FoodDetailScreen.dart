import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/Food.dart';

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
  Food? food;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFood();
  }
  Future<void> loadFood() async {
    final doc = await FirebaseFirestore.instance
        .collection("food")
        .doc(widget.foodId)
        .get();

    if (!doc.exists) {
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      food = Food.fromMap(doc.data()!, doc.id);
      isLoading = false;
    });
  }
  //Hàm lấy thông tin dinh dưỡng
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
  //UI
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
      backgroundColor: const Color(0xFFF3F7F6),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [

              // HEADER
              Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, size: 24),
                    ),
                    const Expanded(
                      child: Center(
                        child: Text(
                          "Chi tiết món ăn",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
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
                  child: food!.image != null
                      ? Image.network(
                    food!.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                    const Icon(Icons.fastfood, size: 60),
                  )
                      : const Icon(Icons.fastfood, size: 60),
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
                    if (food!.englishName != null && food!.englishName!.isNotEmpty)
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

              const SizedBox(height: 20),

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
                    macroBox("Carb", "${food!.carbs} g"),
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

              if (buildNutritionList().isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Không có dữ liệu dinh dưỡng",
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              else
                ...buildNutritionList(),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

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
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}