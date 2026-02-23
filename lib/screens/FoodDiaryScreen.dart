import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
  double fabX = 300;
  double fabY = 520;

  String today = DateTime.now().toString().substring(0, 10);

  @override
  void initState() {
    super.initState();
    loadDiary();
  }

  Future<void> loadDiary() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F6),

      body: Stack(
        children: [

          // Background + Content
          Container(
            color: const Color(0xFFF3F7F6),
            child: SafeArea(
              child: SingleChildScrollView(
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
                            color: const Color(0xFFC7EEDB),
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
            ),
          ),

          // 🔹 DRAGGABLE FAB
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
          textAlign: TextAlign.left,
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
        subtitle: Text("${item.calories.toStringAsFixed(0)} cal"),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FoodDetailScreen(
                foodId: item.foodId,
              ),
            ),
          );
        },
      ),
    );
  }
}