import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../component/Footer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'FoodDetailScreen.dart';

class SuggestMealScreen extends StatefulWidget {
  const SuggestMealScreen({super.key});

  @override
  State<SuggestMealScreen> createState() => _SuggestMealScreenState();
}

class _SuggestMealScreenState extends State<SuggestMealScreen> {

  Map<String, dynamic>? menu;
  Map<String, dynamic>? nutrition;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchMenu();
  }

  Future<void> fetchMenu() async {
    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      final userData = userDoc.data();
      if (userData == null) return;

      final response = await http.post(
        Uri.parse("http://10.0.2.2:8000/recommend"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "age": userData["age"],
          "gender": userData["gender"],
          "height": userData["height"],
          "weight": userData["weight"],
          "activity": userData["activity"],
          "disease": userData["diseases"]?.isNotEmpty == true
              ? userData["diseases"][0]
              : "None"
        }),
      );

      if (response.statusCode != 200) {
        print("API ERROR: ${response.body}");
        return;
      }

      final data = jsonDecode(response.body);
      nutrition = data["nutrition"];

      final aiMenu = data["menu"];

      Map<String, List<Map<String, dynamic>>> fullMenu = {};

      for (String meal in ["Breakfast", "Lunch", "Dinner"]) {

        List items = aiMenu[meal] ?? [];
        List<Map<String, dynamic>> foods = [];

        for (var item in items) {

          final snapshot = await FirebaseFirestore.instance
              .collection("food")
              .where("stt", isEqualTo: item["stt"])
              .limit(1)
              .get();

          if (snapshot.docs.isNotEmpty) {
            final doc = snapshot.docs.first;
            final foodData = doc.data();

            // 🔥 QUAN TRỌNG: thêm id Firestore
            foodData["id"] = doc.id;

            foods.add(foodData);
          }
        }

        fullMenu[meal] = foods;
      }

      setState(() {
        menu = fullMenu;
      });

    } catch (e) {
      print("ERROR: $e");
    }

    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F6),
      bottomNavigationBar: const Footer(currentIndex: 2),

      body: SafeArea(
        child: Column(
          children: [

            // HEADER
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "Gợi ý thực đơn",
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.sync),
                    onPressed: fetchMenu,
                  )
                ],
              ),
            ),

            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : menu == null
                  ? const Center(child: Text("Không có dữ liệu"))
                  : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [

                    Text(
                      "Dựa trên mục tiêu ${nutrition?["Calories"] ?? 0} Calo/ngày",
                      style: const TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 20),

                    buildMealSection("Bữa Sáng", menu!["Breakfast"]),
                    buildMealSection("Bữa Trưa", menu!["Lunch"]),
                    buildMealSection("Bữa Tối", menu!["Dinner"]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMealSection(String title, List<dynamic> foods) {

    if (foods == null || foods.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const SizedBox(height: 20),

        Text(
          title,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 10),

        ...foods.map((food) {

          final String name =
          (food["name_vi"] ?? food["name"] ?? "Không tên").toString();

          final String image =
          (food["image"] ?? "").toString();

          final String calories =
          (food["calories"] ?? 0).toString();

          final String? foodId =
          food["id"]?.toString();

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              onTap: foodId == null ? null : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FoodDetailScreen(
                      foodId: foodId,
                    ),
                  ),
                );
              },
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: image.isNotEmpty
                      ? Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        Image.asset(
                          "assets/images/default_food.png",
                          fit: BoxFit.cover,
                        ),
                  )
                      : Image.asset(
                    "assets/images/default_food.png",
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              title: Text(
                name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text("$calories cal"),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.green),
                onPressed: foodId == null
                    ? null
                    : () => showMealPickerDialog(food),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  Future<void> addFoodToDiary(
      Map<String, dynamic> food,
      String meal,
      ) async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final foodId = food["id"];
    if (foodId == null) return;

    await FirebaseFirestore.instance.collection("food_diary").add({
      "userId": user.uid,
      "foodId": foodId,
      "meal": meal,
      "date": DateTime.now().toString().substring(0, 10),
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(
        content: Text("Thêm vào nhật ký thành công")));
  }

  void showMealPickerDialog(Map<String, dynamic> food) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Chọn buổi ăn"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            mealButton("Bữa sáng", "breakfast", food),
            mealButton("Bữa trưa", "lunch", food),
            mealButton("Bữa tối", "dinner", food),
          ],
        ),
      ),
    );
  }

  Widget mealButton(
      String title,
      String value,
      Map<String, dynamic> food,
      ) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        addFoodToDiary(food, value);
      },
    );
  }
}