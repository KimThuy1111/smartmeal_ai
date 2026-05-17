import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class HomeService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Lấy JWT access token từ backend dựa trên Firebase user hiện tại
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

  // Tải dữ liệu hồ sơ và nhu cầu dinh dưỡng hàng ngày
  Future<Map<String, dynamic>> loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {};
    }

    final uid = user.uid;

    // 1 Lấy thông tin người dùng từ Firestore
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) {
      // 2b Nếu thông tin chưa có, yêu cầu người dùng cập nhật hồ sơ
      return {};
    }

    // 2 Kiểm tra thông tin người dùng có đầy đủ và hợp lệ không
    final data = doc.data()!;
    String name = data['name'] ?? '';
    String goal = data['goal'] ?? '';

    int calories = 0;
    double protein = 0;
    double carb = 0;
    double fat = 0;

    // 2a Nếu người dùng đã có thông tin dinh dưỡng hợp lệ, lấy từ cache
    if (data['nutrition'] != null) {
      final nutrition = data['nutrition'];
      calories = nutrition['Calories'].round();
      protein = nutrition['Protein']?.toDouble() ?? 0;
      carb = nutrition['carb']?.toDouble() ?? 0;
      fat = nutrition['Fat']?.toDouble() ?? 0;
    } else {
      // Nếu chưa có, gọi API tính TDEE
      final accessToken = await _getAccessToken();

      try {
        // 3 Gửi yêu cầu tính TDEE đến backend
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

        if (response.statusCode == 200) {
          // 4 Nhận kết quả tính toán (Calories, Protein, Carb, Fat)
          final nutrition = jsonDecode(response.body);
          calories = nutrition['Calories'].round();
          protein = nutrition['Protein']?.toDouble() ?? 0;
          carb = nutrition['carb']?.toDouble() ?? 0;
          fat = nutrition['Fat']?.toDouble() ?? 0;
  
          try {
            // 5 Lưu kết quả vào Firestore
            await _db.collection('users').doc(uid).update({'nutrition': nutrition});
          } catch (e) {
            // 5a Nếu lưu thất bại, vẫn hiển thị kết quả hiện có
          }
        } else if (response.statusCode == 400 || response.statusCode == 422) {
          // 3a Lỗi dữ liệu, yêu cầu kiểm tra lại
        } else {
          // 3b-3c Lỗi kết nối hoặc backend không phản hồi
        }
      } catch (e) {
        // 3c Lỗi kết nối, yêu cầu thử lại
      }
    }

    // 6 Trả về dữ liệu hiển thị trên Home
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

    // 7.1 Lấy danh sách món ăn hôm nay từ food_diary
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

    // Duyệt qua từng bước ăn trong food_diary
    for (var doc in snapshot.docs) {
      final foodId = doc['foodId'];
      final meal = doc['meal'];

      // Lấy thông tin món ăn từ collection food
      final foodDoc = await _db.collection('food').doc(foodId).get();
      final food = foodDoc.data();

      if (food == null) {
        continue;
      }

      final String foodName = food['name'] ?? '';

      // Lấy chỉ số dinh dưỡng
      final double cal = (food['calories'] ?? 0).toDouble();
      final double p = (food['protein'] ?? 0).toDouble();
      final double c = (food['carb'] ?? 0).toDouble();
      final double f = (food['fat'] ?? 0).toDouble();

      // Tính tổng chỉ số dinh dưỡng đã nạp
      eatenProtein += p;
      eatencarb += c;
      eatenFat += f;

      // 7.2 Phân loại các bữa ăn (breakfast/lunch/dinner)
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