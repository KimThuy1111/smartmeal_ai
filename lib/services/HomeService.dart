import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class HomeService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Tải dữ liệu hồ sơ và nhu cầu dinh dưỡng của người dùng cho màn hình Home.
  Future<Map<String, dynamic>> loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {};
    }

    final uid = user.uid;

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      return {};
    }

    final data = doc.data()!;
    String name = data['name'] ?? '';
    String goal = data['goal'] ?? '';

    int calories = 0;
    double protein = 0;
    double carb = 0;
    double fat = 0;

    if (data['nutrition'] != null) {
      final nutrition = data['nutrition'];
      calories = nutrition['Calories'].round();
      protein = nutrition['Protein']?.toDouble() ?? 0;
      carb = nutrition['carb']?.toDouble() ?? 0;
      fat = nutrition['Fat']?.toDouble() ?? 0;
    } else {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/tdee'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'age': data['age'],
          'gender': data['gender'],
          'height': data['height'],
          'weight': data['weight'],
          'activity': data['activity'],
          'breakfast_cal': 0,
          'lunch_cal': 0,
          'dinner_cal': 0,
        }),
      );

      if (response.statusCode == 200) {
        final nutrition = jsonDecode(response.body);
        calories = nutrition['Calories'].round();
        protein = nutrition['Protein']?.toDouble() ?? 0;
        carb = nutrition['carb']?.toDouble() ?? 0;
        fat = nutrition['Fat']?.toDouble() ?? 0;

        await _db.collection('users').doc(uid).update({'nutrition': nutrition});
      }
    }

    return {
      'name': name,
      'goal': goal,
      'calories': calories,
      'protein': protein,
      'carb': carb,
      'fat': fat,
    };
  }

  /// Tải dữ liệu các bữa ăn trong ngày và tổng hợp chỉ số đã nạp.
  Future<Map<String, dynamic>> loadTodayMeals() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {};
    }

    final String today = DateTime.now().toString().substring(0, 10);

    final snapshot = await _db
        .collection('food_diary')
        .where('userId', isEqualTo: user.uid)
        .where('date', isEqualTo: today)
        .get();

    List<String> breakfastFoods = [];
    List<String> lunchFoods = [];
    List<String> dinnerFoods = [];

    double breakfastCal = 0;
    double lunchCal = 0;
    double dinnerCal = 0;

    double eatenProtein = 0;
    double eatencarb = 0;
    double eatenFat = 0;

    for (var doc in snapshot.docs) {
      final foodId = doc['foodId'];
      final meal = doc['meal'];

      final foodDoc = await _db.collection('food').doc(foodId).get();
      final food = foodDoc.data();

      if (food == null) {
        continue;
      }

      final String foodName = food['name'] ?? '';

      final double cal = (food['calories'] ?? 0).toDouble();
      final double p = (food['protein'] ?? 0).toDouble();
      final double c = (food['carb'] ?? 0).toDouble();
      final double f = (food['fat'] ?? 0).toDouble();

      eatenProtein += p;
      eatencarb += c;
      eatenFat += f;

      if (meal == 'breakfast') {
        breakfastFoods.add(foodName);
        breakfastCal += cal;
      } else if (meal == 'lunch') {
        lunchFoods.add(foodName);
        lunchCal += cal;
      } else if (meal == 'dinner') {
        dinnerFoods.add(foodName);
        dinnerCal += cal;
      }
    }

    return {
      'breakfastFoods': breakfastFoods,
      'lunchFoods': lunchFoods,
      'dinnerFoods': dinnerFoods,
      'breakfastCal': breakfastCal,
      'lunchCal': lunchCal,
      'dinnerCal': dinnerCal,
      'eatenProtein': eatenProtein,
      'eatencarb': eatencarb,
      'eatenFat': eatenFat,
    };
  }
}