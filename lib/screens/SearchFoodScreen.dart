import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/Food.dart';
import '../repository/FoodRepository.dart';
import '../utils/notifier.dart';
import 'FoodDetailScreen.dart';

class SearchFoodScreen extends StatefulWidget {
  const SearchFoodScreen({super.key});

  @override
  State<SearchFoodScreen> createState() => _SearchFoodScreenState();
}

class _SearchFoodScreenState extends State<SearchFoodScreen> {

  final FoodRepository repo = FoodRepository();
  final TextEditingController controller = TextEditingController();

  List<Food> foods = [];
  bool isLoading = true;

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    loadTopFoods();
  }

  @override
  void dispose() {
    controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  // Hàm load các món ăn phổ biến
  Future<void> loadTopFoods() async {
    setState(() => isLoading = true);

    final result = await repo.getTopFoods(10);

    setState(() {
      foods = result;
      isLoading = false;
    });
  }
  // Hàm tìm kiếm món ăn
  void searchFood(String keyword) {

    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () async {

      final value = keyword.trim();

      if (value.isEmpty) {
        loadTopFoods();
        return;
      }

      setState(() => isLoading = true);

      final result = await repo.searchFood(value);

      setState(() {
        foods = result;
        isLoading = false;
      });
    });
  }

  // Hàm thêm món ăn vào nhật kí
  Future<void> addFoodToDiary(Food food, String meal) async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Chưa đăng nhập")));
      return;
    }

    await FirebaseFirestore.instance.collection("food_diary").add({
      "userId": user.uid,
      "foodId": food.id,
      "meal": meal,
      "date": DateTime.now().toString().substring(0, 10),
      "createdAt": FieldValue.serverTimestamp(),
    });

    Notifier.showNotify(context, "Thêm vào nhật ký thành công");

  }

  // Dialog chọn bữa ăn
  void showMealPickerDialog(Food food) {
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

  // Nút chọn bữa ăn
  Widget mealButton(String title, String value, Food food) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        addFoodToDiary(food, value);
      },
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4FFE4),
      body: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.chevron_left, size: 24),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    "Tra cứu món ăn",
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

          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              onChanged: searchFood,
              decoration: InputDecoration(
                hintText: "Tìm kiếm món ăn...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Kết quả tìm kiếm",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(height: 10),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : foods.isEmpty
                ? const Center(
              child: Text(
                "Không tìm thấy món ăn",
                style: TextStyle(color: Colors.grey),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: foods.length,
              itemBuilder: (context, index) {
                return buildFoodItem(foods[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
  // Hiển thị 1 món ăn
  Widget buildFoodItem(Food food) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FoodDetailScreen(
                foodId: food.id,
              ),
            ),
          );
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 60,
            height: 60,
            child: (food.image != null && food.image!.isNotEmpty)
                ? Image.network(
              food.image!,
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
          food.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text("${food.calories.toStringAsFixed(0)} cal"),
        trailing: IconButton(
          icon: const Icon(Icons.add_circle, color: Colors.green),
          onPressed: () => showMealPickerDialog(food),
        ),
      ),
    );
  }
}