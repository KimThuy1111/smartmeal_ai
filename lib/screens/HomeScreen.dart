import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'FoodDiaryScreen.dart';
import 'SearchFoodScreen.dart';

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

  String breakfast = "";
  String lunch = "";
  String dinner = "";
  double fabX = 300;
  double fabY = 520;

  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  // Lấy thông tin user từ firestore
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
      calories = calculateTDEE(data);

      breakfast = data["breakfast"] ?? "";
      lunch = data["lunch"] ?? "";
      dinner = data["dinner"] ?? "";
    });
  }

  // Tính TDEE
  int calculateTDEE(Map<String, dynamic> user) {
    double weight = user["weight"];
    double height = user["height"];
    int age = user["age"];
    String gender = user["gender"];
    String activity = user["activity"];

    double bmr;

    if (gender.toLowerCase() == "nam") {
      bmr = 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      bmr = 10 * weight + 6.25 * height - 5 * age - 161;
    }

    double factor = getActivityFactor(activity);

    return (bmr * factor).round();
  }

  double getActivityFactor(String activity) {
    switch (activity.toLowerCase()) {
      case "ít vận động":
        return 1.2;
      case "vận động nhẹ":
        return 1.55;
      case "vận động mạnh":
        return 1.725;
      default:
        return 1.2;
    }
  }

  // UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          // 🔹 BODY CŨ CỦA BẠN
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

                        // Calories Circle
                        Container(
                          width: 250,
                          height: 250,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFF2FDF7),
                            border: Border.all(
                                color: const Color(0xFFC7EEDB),
                                width: 3),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [

                              Text(
                                "$calories",
                                style: const TextStyle(
                                    fontSize: 42,
                                    fontWeight: FontWeight.bold),
                              ),

                              const SizedBox(height: 8),

                              const Text(
                                "Calo đã tiêu thụ",
                                style: TextStyle(color: Colors.grey),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                "Mục tiêu: $goal",
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        const Text(
                          "Nhật ký hôm nay",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 12),

                        Text(breakfast),
                        Text(lunch),
                        Text(dinner),

                        const SizedBox(height: 60),
                      ],
                    ),
                  ),
                ),

                // FOOTER NAV
                buildBottomNav(),
              ],
            ),
          ),

          // 🔹 FAB DRAGGABLE
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

  // Footer
  Widget buildBottomNav() {
    return Container(
      height: 70,
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          buildNavItem(Icons.home, "Trang chủ", 0),
          buildNavItem(Icons.book, "Nhật ký", 1),
          buildNavItem(Icons.search, "Gợi ý", 2),
          buildNavItem(Icons.person, "Hồ sơ", 3),
        ],
      ),
    );
  }

  Widget buildNavItem(IconData icon, String text, int index) {
    bool isSelected = selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIndex = index;
        });

        switch (index) {
          case 0:
            break;

          case 1:
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const FoodDiaryScreen(),
              ),
            );
            break;

          case 2:
            break;

          case 3:
            break;
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected
                ? const Color(0xFF00C569)
                : Colors.grey,
          ),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? const Color(0xFF00C569)
                  : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
