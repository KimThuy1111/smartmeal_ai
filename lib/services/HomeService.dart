import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class HomeService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Lấy JWT access token từ backend dựa trên Firebase user hiện tại.
  Future<String?> _getAccessToken() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    try {
      final tokenResponse = await http.post(
        Uri.parse('http://10.0.2.2:8000/token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebase_uid': user.uid,
          'email': user.email,
        }),
      );

      if (tokenResponse.statusCode == 200) {
        final data = jsonDecode(tokenResponse.body) as Map<String, dynamic>;
        return data['access_token'] as String?;
      }
    } catch (_) {
      return null;
    }

    return null;
  }

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

    // 1. Hệ thống lấy thông tin người dùng từ Firestore.
    final data = doc.data()!;
    String name = data['name'] ?? '';
    String goal = data['goal'] ?? '';

    int calories = 0;
    double protein = 0;
    double carb = 0;
    double fat = 0;

    // 2a. Người dùng đã có thông tin dinh dưỡng trong Firestore.Hệ thống sẽ lấy dữ liệu trực tiếp từ Firestore mà không cần tính toán lại.
    if (data['nutrition'] != null) {
      final nutrition = data['nutrition'];
      calories = nutrition['Calories'].round();
      protein = nutrition['Protein']?.toDouble() ?? 0;
      carb = nutrition['carb']?.toDouble() ?? 0;
      fat = nutrition['Fat']?.toDouble() ?? 0;
    } else {
      final accessToken = await _getAccessToken();

      // 2. Hệ thống gửi request đến API cùng với các thông tin của người dùng.
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/tdee'),
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'age': data['age'],
          'gender': data['gender'],
          'height': data['height'],
          'weight': data['weight'],
          'activity': data['activity'],
          'goal': data['goal'] ?? 'Duy trì cân nặng',
          'breakfast_cal': 0,
          'lunch_cal': 0,
          'dinner_cal': 0,
        }),
      );

      // 8. API trả kết quả về cho hệ thống.
      if (response.statusCode == 200) {
        // 3. API nhận request và tính toán các chỉ số dinh dưỡng.
        final nutrition = jsonDecode(response.body);
        calories = nutrition['Calories'].round();
        protein = nutrition['Protein']?.toDouble() ?? 0;
        carb = nutrition['carb']?.toDouble() ?? 0;
        fat = nutrition['Fat']?.toDouble() ?? 0;

        // 6. Hệ thống lưu kết quả vào Firestore.
        await _db.collection('users').doc(uid).update({'nutrition': nutrition});
      } else {
        // 3a. API không phản hồi. Hệ thống sẽ hiển thị dữ liệu rỗng.
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