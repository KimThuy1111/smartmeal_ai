import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../component/Footer.dart';
import 'SearchFoodScreen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String name = "";
  String goal = "";
  int calories = 0;

  double protein = 0;
  double carbs = 0;
  double fat = 0;

  double eatenProtein = 0;
  double eatenCarbs = 0;
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
    loadUserData();
    loadTodayMeals();
  }

  // Load user
  void loadUserData() async {

    if (_auth.currentUser == null) return;

    String uid = _auth.currentUser!.uid;

    DocumentSnapshot doc =
    await _db.collection("users").doc(uid).get();

    if (!doc.exists) return;

    Map<String, dynamic> data =
    doc.data() as Map<String, dynamic>;

    setState(() {
      name = data["name"] ?? "";
      goal = data["goal"] ?? "";
    });
    if (data["nutrition"] != null) {

      // Nếu đã có nutrition

      final nutrition = data["nutrition"];

      setState(() {
        calories = nutrition["Calories"].round();
        protein = nutrition["Protein"]?.toDouble() ?? 0;
        carbs = nutrition["Carbs"]?.toDouble() ?? 0;
        fat = nutrition["Fat"]?.toDouble() ?? 0;
      });

      return;
    }
    //Chưa có gọi api
    final response = await http.post(
      Uri.parse("https://smartmeal-ai-wp3g.onrender.com/recommend"),
      // Uri.parse("http://10.0.2.2:8000/recommend"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "age": data["age"],
        "gender": data["gender"],
        "height": data["height"],
        "weight": data["weight"],
        "activity": data["activity"],
        "disease": data["diseases"]?.isNotEmpty == true
            ? data["diseases"][0]
            : "None",
        "breakfast_cal": 0,
        "lunch_cal": 0,
        "dinner_cal": 0,
      }),
    );

    if (response.statusCode != 200) return;

    final result = jsonDecode(response.body);
    final nutrition = result["nutrition"];

    setState(() {

      calories = nutrition["Calories"].round();

      protein = nutrition["Protein"]?.toDouble() ?? 0;
      carbs = nutrition["Carbs"]?.toDouble() ?? 0;
      fat = nutrition["Fat"]?.toDouble() ?? 0;
    });
    await _db.collection("users")
        .doc(uid)
        .update({
      "nutrition": nutrition
    });
  }
  // Load nhật kí ăn uống
  void loadTodayMeals() async {

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String today = DateTime.now().toString().substring(0,10);

    final snapshot = await FirebaseFirestore.instance
        .collection("food_diary")
        .where("userId", isEqualTo: user.uid)
        .where("date", isEqualTo: today)
        .get();

    breakfastFoods.clear();
    lunchFoods.clear();
    dinnerFoods.clear();

    breakfastCal = 0;
    lunchCal = 0;
    dinnerCal = 0;

    eatenProtein = 0;
    eatenCarbs = 0;
    eatenFat = 0;

    for (var doc in snapshot.docs) {

      String foodId = doc["foodId"];
      String meal = doc["meal"];

      final foodDoc = await FirebaseFirestore.instance
          .collection("food")
          .doc(foodId)
          .get();

      final food = foodDoc.data();
      if (food == null) continue;

      String foodName = food["name"] ?? "";

      double cal = (food["calories"] ?? 0).toDouble();
      double p = (food["protein"] ?? 0).toDouble();
      double c = (food["carbs"] ?? 0).toDouble();
      double f = (food["fat"] ?? 0).toDouble();

      eatenProtein += p;
      eatenCarbs += c;
      eatenFat += f;

      if (meal == "breakfast") {
        breakfastFoods.add(foodName);
        breakfastCal += cal;
      }
      else if (meal == "lunch") {
        lunchFoods.add(foodName);
        lunchCal += cal;
      }
      else if (meal == "dinner") {
        dinnerFoods.add(foodName);
        dinnerCal += cal;
      }
    }

    setState(() {});
  }

  // Ui
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
                    padding: const EdgeInsets.all(24),

                    child: Column(
                      children: [

                        const SizedBox(height: 40),

                        Text(
                          "Chào buổi sáng, $name!",
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 20),

                        buildNutritionCircle(),

                        const SizedBox(height: 30),

                        buildMealCard(
                          icon: Icons.breakfast_dining,
                          title: "Bữa sáng",
                          recommend: (calories * 0.3).round(),
                          eaten: breakfastCal,
                          foods: breakfastFoods,
                        ),

                        buildMealCard(
                          icon: Icons.wb_sunny,
                          title: "Bữa trưa",
                          recommend: (calories * 0.4).round(),
                          eaten: lunchCal,
                          foods: lunchFoods,
                        ),

                        buildMealCard(
                          icon: Icons.nightlight_round,
                          title: "Bữa tối",
                          recommend: (calories * 0.3).round(),
                          eaten: dinnerCal,
                          foods: dinnerFoods,
                        ),

                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),

                Footer(currentIndex: 0),
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
                  );
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

  Widget buildNutritionCircle() {

    double proteinGoal = calories * 0.15 / 4;
    double carbGoal = calories * 0.55 / 4;
    double fatGoal = calories * 0.30 / 9;

    return SizedBox(
      width: 360,
      height: 260,

      child: Stack(
        alignment: Alignment.center,

        children: [

          Container(
            width: 180,
            height: 180,

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
                  "$calories",
                  style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 4),

                const Text(
                  "Calories",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 2),

                Text(
                  "Goal: $goal",
                  style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey),
                ),
              ],
            ),
          ),

          Positioned(
            left: 0,
            top: 0,
            child: macroBar("Carbs", eatenCarbs, carbs),
          ),

          Positioned(
            right: 0,
            top: 30,
            child: macroBar("Protein", eatenProtein, protein),
          ),

          Positioned(
            left: 0,
            bottom: 30,
            child: macroBar("Fat", eatenFat, fat),
          ),

        ],
      ),
    );
  }

  Widget macroBar(
      String title,
      double value,
      double goal,
      {String unit = "g"}
      ) {

    double percent = goal == 0 ? 0 : value / goal;
    if (percent > 1) percent = 1;

    return SizedBox(
      width: 70,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13),
          ),

          const SizedBox(height: 4),

          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35), // tăng bóng cho dễ thấy
                  blurRadius: 8,
                  spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),

            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),

              child: Container(
                height: 12,
                width: double.infinity,
                color: Colors.grey[300],

                child: Stack(
                  children: [

                    FractionallySizedBox(
                      widthFactor: percent,

                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF79EEF2),
                              Color(0xFF78F09C),
                            ],
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            "${value.toStringAsFixed(0)}/${goal.toStringAsFixed(0)} $unit",
            style: const TextStyle(
                fontSize: 12,
                color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget buildMealCard({
    required IconData icon,
    required String title,
    required int recommend,
    required double eaten,
    required List<String> foods,
  }) {

    String subtitle;

    if (eaten == 0) {
      subtitle = "Khuyến nghị: $recommend kcal";
    } else {

      double remain = recommend - eaten;

      subtitle =
      "${eaten.toStringAsFixed(0)} kcal • "
          "${remain >= 0 ? "Còn lại" : "Vượt quá"} "
          "${remain.abs().toStringAsFixed(0)} kcal";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
          )
        ],
      ),

      child: Row(
        children: [

          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F8EF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF00C569)),
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),

                if (foods.isNotEmpty)
                  Text(
                    foods.join(", "),
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.grey),
                  ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey),
                ),
              ],
            ),
          ),

          IconButton(
            icon: const Icon(
              Icons.add_circle_outline,
              color: Color(0xFF00C569),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SearchFoodScreen(),
                ),
              ).then((_) => loadTodayMeals());
            },
          )
        ],
      ),
    );
  }
}