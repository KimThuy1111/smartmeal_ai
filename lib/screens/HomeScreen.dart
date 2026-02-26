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

    final response = await http.post(
      Uri.parse("https://smartmeal-ai-wp3g.onrender.com/recommend"),
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
      name = data["name"] ?? "";
      goal = data["goal"] ?? "";
      calories = nutrition["Calories"].round();
    });
  }

  // UI
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


}
