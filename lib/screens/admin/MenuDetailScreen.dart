import 'package:flutter/material.dart';
import '../../models/User.dart';
import '../FoodDetailScreen.dart';
import '../../widgets/FoodItemCard.dart';
import '../../controllers/FoodController.dart';

class MenuDetailScreen extends StatefulWidget {

  final User user;
  final Map<String, List<String>> menu;

  const MenuDetailScreen({
    super.key,
    required this.user,
    required this.menu,
  });

  @override
  State<MenuDetailScreen> createState() =>
      _MenuDetailScreenState();
}

class _MenuDetailScreenState
    extends State<MenuDetailScreen> {

  final FoodController _controller = FoodController();

  Map<String, List<Map<String, dynamic>>> foods = {};

  @override
  void initState() {
    super.initState();
    loadFoods();
  }

  // Tải danh sách món ăn theo thực đơn đã chọn
  Future<void> loadFoods() async {
    final result = await _controller.getFoodsByMenu(widget.menu);

    setState(() {
      foods = result;
    });
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: Text(widget.user.name),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          buildMeal("Bữa sáng", foods["Breakfast"] ?? []),
          buildMeal("Bữa trưa", foods["Lunch"] ?? []),
          buildMeal("Bữa tối", foods["Dinner"] ?? []),

        ],
      ),
    );
  }

  // Hiển thị danh sách món ăn của từng bữa
  Widget buildMeal(String title, List<Map<String, dynamic>> foods) {

    if (foods.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 10),

        ...foods.map((food) {

          return FoodItemCard(

            id: food["id"],
            name: food["name"],
            image: food["image"],
            calories: food["calories"].toDouble(),

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      FoodDetailScreen(
                          foodId: food["id"]),
                ),
              );
            },

            trailing: const SizedBox(),

          );

        }).toList()

      ],
    );
  }
}