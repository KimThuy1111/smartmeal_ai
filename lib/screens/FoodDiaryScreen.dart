import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../component/Footer.dart';
import '../models/FoodDiary.dart';
import 'FoodDetailScreen.dart';
import 'SearchFoodScreen.dart';

class FoodDiaryScreen extends StatefulWidget {
  const FoodDiaryScreen({super.key});

  @override
  State<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {

  List<FoodDiary> breakfast = [];
  List<FoodDiary> lunch = [];
  List<FoodDiary> dinner = [];

  double totalCalories = 0;
  double targetCalories = 0; // 🔥 TDEE từ FastAPI

  double fabX = 300;
  double fabY = 480;

  String today = DateTime.now().toString().substring(0, 10);

  @override
  void initState() {
    super.initState();
    loadDiary();
  }

  Future<void> loadDiary() async {

    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 🔥 Lấy user data
    final userDoc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    final userData = userDoc.data();
    if (userData == null) return;

    // 🔥 Gọi API lấy TDEE
    final response = await http.post(
      Uri.parse("https://smartmeal-ai-wp3g.onrender.com/tdee"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "age": userData["age"],
        "gender": userData["gender"],
        "height": userData["height"],
        "weight": userData["weight"],
        "activity": userData["activity"],
        "disease": userData["diseases"]?.isNotEmpty == true
            ? userData["diseases"][0]
            : "None",
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      targetCalories = (data["Calories"] ?? 0).toDouble();
    }

    // 🔥 Load diary
    final snapshot = await FirebaseFirestore.instance
        .collection("food_diary")
        .where("userId", isEqualTo: uid)
        .where("date", isEqualTo: today)
        .get();

    breakfast.clear();
    lunch.clear();
    dinner.clear();
    totalCalories = 0;

    for (var doc in snapshot.docs) {

      final foodId = doc["foodId"];
      final meal = doc["meal"];

      final foodDoc = await FirebaseFirestore.instance
          .collection("food")
          .doc(foodId)
          .get();

      final data = foodDoc.data();
      if (data == null) continue;

      final item = FoodDiary(
        foodId: foodId,
        meal: meal,
        date: today,
        name: data["name"],
        image: data["image"],
        calories: (data["calories"] ?? 0).toDouble(),
      );

      totalCalories += item.calories;

      switch (meal) {
        case "breakfast":
          breakfast.add(item);
          break;
        case "lunch":
          lunch.add(item);
          break;
        case "dinner":
          dinner.add(item);
          break;
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    bool isOver = totalCalories > targetCalories && targetCalories > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F6),

      bottomNavigationBar: const Footer(currentIndex: 1),

      body: SafeArea(
        child: Stack(
          children: [

            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  const Center(
                    child: Text(
                      "Nhật ký ăn uống",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(
                    child: Container(
                      width: 165,
                      height: 165,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF2FDF7),
                        border: Border.all(
                          color: isOver
                              ? Colors.red
                              : const Color(0xFFC7EEDB),
                          width: 3,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            totalCalories.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text("kcal consumed"),
                          const SizedBox(height: 6),
                          Text(
                            "Target: ${targetCalories.toStringAsFixed(0)}",
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey),
                          )
                        ],
                      ),
                    ),
                  ),

                  buildMealSection("Bữa sáng", breakfast),
                  buildMealSection("Bữa trưa", lunch),
                  buildMealSection("Bữa tối", dinner),

                  const SizedBox(height: 120),
                ],
              ),
            ),

            Positioned(
              left: fabX,
              top: fabY,
              child: GestureDetector(
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
                    ).then((_) => loadDiary());
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
      ),
    );
  }

  Widget buildMealSection(String title, List<FoodDiary> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...list.map((e) => buildFoodItem(e)).toList(),
      ],
    );
  }

  Widget buildFoodItem(FoodDiary item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: item.image != null && item.image!.isNotEmpty
            ? Image.network(
          item.image!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
          const Icon(Icons.fastfood),
        )
            : const Icon(Icons.fastfood),
        title: Text(item.name),
        subtitle:
        Text("${item.calories.toStringAsFixed(0)} cal"),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  FoodDetailScreen(foodId: item.foodId),
            ),
          );
        },
      ),
    );
  }
}