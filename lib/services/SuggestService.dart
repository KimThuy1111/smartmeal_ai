import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/SuggestedMenu.dart';

class SuggestService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get today => DateTime.now().toString().substring(0, 10);

  /// 2.1 Lấy danh sách STT các món đã ăn trong 3 ngày qua
  /// Tải lịch sử món ăn 3 ngày gần nhất để tránh gợi ý lặp.
  Future<List<int>> loadRecentFoodHistory() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    final DateTime threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));

    final snapshot = await _db
        .collection('food_diary')
        .where('userId', isEqualTo: user.uid)
        .get();

    final List<int> result = [];

    for (final doc in snapshot.docs) {
      final DateTime d = DateTime.parse(doc['date']);
      if (d.isBefore(threeDaysAgo)) {
        continue;
      }

      final foodDoc = await _db.collection('food').doc(doc['foodId']).get();
      if (!foodDoc.exists) {
        continue;
      }

      final stt = foodDoc.data()?['stt'];
      if (stt != null) {
        result.add(stt);
      }
    }

    return result;
  }

  /// 2.3 Lấy calories, lịch sử món đã ăn theo từng bữa
  /// Tính tổng calories đã ăn trong ngày theo từng bữa.
  Future<Map<String, double>> loadTodayCalories() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {};
    }

    double breakfast = 0;
    double lunch = 0;
    double dinner = 0;

    final snapshot = await _db
        .collection('food_diary')
        .where('userId', isEqualTo: user.uid)
        .where('date', isEqualTo: today)
        .get();

    for (final doc in snapshot.docs) {
      final foodDoc = await _db.collection('food').doc(doc['foodId']).get();
      if (!foodDoc.exists) {
        continue;
      }

      final cal = (foodDoc.data()?['calories'] ?? 0).toDouble();

      if (doc['meal'] == 'breakfast') breakfast += cal;
      if (doc['meal'] == 'lunch') lunch += cal;
      if (doc['meal'] == 'dinner') dinner += cal;
    }

    return {
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
    };
  }

  /// 4.2 Gửi yêu cầu đến API endpoint /recommend
  /// Gọi API gợi ý thực đơn dựa trên hồ sơ người dùng và dữ liệu ăn uống gần đây.
  Future<Map<String, dynamic>> fetchMenuAPI({
    required Map userData,
    required double breakfast,
    required double lunch,
    required double dinner,
    required List<int> recentFoods,
    required List<int> excludedFoods,
  }) async {
    try {
      // Gửi yêu cầu POST đến endpoint API
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/recommend'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          // Thông tin người dùng
          'age': userData['age'],
          'gender': userData['gender'],
          'height': userData['height'],
          'weight': userData['weight'],
          'activity': userData['activity'],
          'goal': userData['goal'],
          // Calories đã tiêu thụ từng bữa
          'breakfast_cal': breakfast,
          'lunch_cal': lunch,
          'dinner_cal': dinner,
          // Danh sách loại trừ
          'recent_foods': recentFoods,
          'excluded_foods': excludedFoods,
        }),
      );

      // Kiểm tra lỗi kết nối
      if (response.statusCode != 200) {
        print('API Error: ${response.statusCode} - ${response.body}');
        return {};
      }

      // Trả về thực đơn từ API
      return jsonDecode(response.body);
    } catch (e) {
      print('Error in fetchMenuAPI: $e');
      return {};
    }
  }


  /// Lấy danh sách STT các món đã được gợi ý hôm nay để tránh trùng lặp
  Future<List<int>> getTodaySuggestedFoodStt() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    final snapshot = await _db
        .collection('suggested_menus')
        .where('userId', isEqualTo: user.uid)
        .where('date', isEqualTo: today)
        .get();

    final List<int> result = [];

    for (final doc in snapshot.docs) {
      final menu = doc['menu'];

      for (final meal in menu.keys) {
        for (final id in menu[meal]) {
          final foodDoc = await _db.collection('food').doc(id).get();

          if (foodDoc.exists) {
            final stt = foodDoc.data()?['stt'];
            if (stt != null) {
              result.add(stt);
            }
          }
        }
      }
    }

    return result;
  }

  /// 7. Lưu thực đơn gợi ý trong ngày và trả về id của document vừa tạo.
  Future<String?> saveMenu(Map<String, List<Map<String, dynamic>>> menu) async {
    // 7.1 Lấy user hiện tại
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    // 7.2 Chuyển đổi danh sách món ăn sang dạng id
    final Map<String, List<String>> foodIds = {};
    menu.forEach((meal, foods) {
      foodIds[meal] = foods.map((f) => f['id'].toString()).toList();
    });


    // 7.3 Tạo instance SuggestedMenu để lưu trữ
    final suggestedMenu = SuggestedMenu(
      userId: user.uid,
      date: today,
      menu: foodIds,
      liked: null,
    );

    // 7.4 Lưu dữ liệu instance SuggestedMenu vào Firestore, thêm createdAt
    final dataToSave = suggestedMenu.toMap();
    dataToSave['createdAt'] = DateTime.now();
    final docRef = await _db.collection('suggested_menus').add(dataToSave);

    // 7.5 Trả về id document vừa tạo
    return docRef.id;
  }
}