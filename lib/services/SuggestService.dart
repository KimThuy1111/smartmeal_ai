import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/SuggestedMenu.dart';
import 'BaseService.dart';

class SuggestService extends BaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get today => DateTime.now().toString().substring(0, 10);

  //Lấy danh sách STT các món đã ăn trong 3 ngày (chỉ active)
  Future<List<int>> loadRecentFoodHistory() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    final DateTime threeDaysAgo = DateTime.now().subtract(
      const Duration(days: 3),
    );

    final snapshot =
        await _db
            .collection('food_diary')
            .where('userId', isEqualTo: user.uid)
            .where('status', isEqualTo: 1)
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

  // Lấy calories theo từng bữa hôm nay
  Future<Map<String, double>> loadTodayCalories() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {};
    }

    double breakfast = 0;
    double lunch = 0;
    double dinner = 0;

    final snapshot =
        await _db
            .collection('food_diary')
            .where('userId', isEqualTo: user.uid)
            .where('date', isEqualTo: today)
            .where('status', isEqualTo: 1)
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

    return {'breakfast': breakfast, 'lunch': lunch, 'dinner': dinner};
  }

  // Gửi yêu cầu đến API endpoint /recommend
  Future<Map<String, dynamic>> fetchMenuAPI({required Map userData, required double breakfast, required double lunch, required double dinner, required List<int> recentFoods, required List<int> excludedFoods}) async {
    try {
      final response = await http.post(
        Uri.parse('https://smartmeal-ai-production.up.railway.app/recommend'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'age': userData['age'],
          'gender': userData['gender'],
          'height': userData['height'],
          'weight': userData['weight'],
          'activity': userData['activity'],
          'goal': userData['goal'],
          'nutrition': userData['nutrition'],
          'breakfast_cal': breakfast,
          'lunch_cal': lunch,
          'dinner_cal': dinner,
          'recent_foods': recentFoods,
          'excluded_foods': excludedFoods,
        }),
      );

      if (response.statusCode != 200) {
        print('API Error: ${response.statusCode} - ${response.body}');
        return {};
      }

      return jsonDecode(response.body);
    } catch (e) {
      print('Error in fetchMenuAPI: $e');
      return {};
    }
  }

  // Lấy danh sách STT các món đã gợi ý hôm nay (chỉ active)
  Future<List<int>> getTodaySuggestedFoodStt() async {
    final user = _auth.currentUser;
    if (user == null) {
      return [];
    }

    // Query đơn giản: chỉ userId và date, filter status trong code
    final snapshot =
        await _db
            .collection('suggested_menus')
            .where('userId', isEqualTo: user.uid)
            .where('date', isEqualTo: today)
            .get();

    // Filter status=1 trong code
    final activeDocs =
        snapshot.docs.where((doc) => doc['status'] == 1).toList();

    final List<int> result = [];

    for (final doc in activeDocs) {
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

  // Lưu thực đơn gợi ý với status = 1
  Future<String?> saveMenu(Map<String, List<Map<String, dynamic>>> menu) async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final Map<String, List<String>> foodIds = {};
    menu.forEach((meal, foods) {
      foodIds[meal] = foods.map((f) => f['id'].toString()).toList();
    });

    final suggestedMenu = SuggestedMenu(
      userId: user.uid,
      date: today,
      menu: foodIds,
      liked: null,
    );

    final dataToSave = suggestedMenu.toMap();
    dataToSave['status'] = 1;
    dataToSave['createdAt'] = FieldValue.serverTimestamp();
    dataToSave['updatedAt'] = null;

    final docRef = await _db.collection('suggested_menus').add(dataToSave);

    return docRef.id;
  }

  // Cập nhật đánh giá thực đơn
  Future<void> rateMenu({required String menuId, required bool liked}) async {
    await _db.collection('suggested_menus').doc(menuId).update({
      'liked': liked,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addFoodToDiary({
    required String foodId,
    required String meal,
    required String date,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User chưa đăng nhập');
    }

    await _db.collection('food_diary').add({
      'userId': user.uid,

      'foodId': foodId,

      'meal': meal,

      'date': date,

      'status': 1,

      'createdAt': FieldValue.serverTimestamp(),

      'updatedAt': null,
    });
  }

  // Lấy tổng calories hôm nay và calories mục tiêu
  Future<Map<String, dynamic>> loadTodaySummary() async {
    final user = _auth.currentUser;

    if (user == null) {
      return {"targetCalories": 0.0, "totalCalories": 0.0};
    }

    double targetCalories = 0;
    double totalCalories = 0;

    try {
      final userSnapshot = await _db
        .collection('users')
        .where('userId', isEqualTo: user.uid)
        .get();

      if (userSnapshot.docs.isNotEmpty) {
        final activeDocs =
            userSnapshot.docs.where((doc) => doc['status'] == 1).toList();

        if (activeDocs.isNotEmpty) {
          activeDocs.sort((a, b) {
            final createdAtA = a['createdAt'] as Timestamp?;

            final createdAtB = b['createdAt'] as Timestamp?;

            if (createdAtA == null || createdAtB == null) {
              return 0;
            }

            return createdAtB.compareTo(createdAtA);
          });

          final userData = activeDocs.first.data();

          if (userData['nutrition'] != null) {
            targetCalories =
                (userData['nutrition']['Calories'] ?? 0).toDouble();
          }
        }
      }
    } catch (_) {}

    final diarySnapshot =
        await _db
            .collection('food_diary')
            .where('userId', isEqualTo: user.uid)
            .where('date', isEqualTo: today)
            .where('status', isEqualTo: 1)
            .get();

    for (final doc in diarySnapshot.docs) {
      final foodDoc = await _db.collection('food').doc(doc['foodId']).get();

      if (!foodDoc.exists) continue;

      totalCalories += (foodDoc.data()?['calories'] ?? 0).toDouble();
    }

    return {"targetCalories": targetCalories, "totalCalories": totalCalories};
  }

  // Tải thực đơn đã lưu trong Firestore
  Future<Map<String, dynamic>?> loadMenuFromFirestore(String date) async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final snapshot = await _db
      .collection('suggested_menus')
      .where('userId', isEqualTo: user.uid)
      .where('date', isEqualTo: date)
      .get();

    final activeDocs = snapshot.docs.where((doc) => doc['status'] == 1).toList();

    if (activeDocs.isEmpty) {
      return null;
    }

    activeDocs.sort((a, b) {
      final createdAtA = a['createdAt'] as Timestamp?;

      final createdAtB = b['createdAt'] as Timestamp?;

      if (createdAtA == null || createdAtB == null) {
        return 0;
      }

      return createdAtB.compareTo(createdAtA);
    });

    final doc = activeDocs.first;

    final suggested = SuggestedMenu.fromMap(doc.data());

    final Map<String, List<Map<String, dynamic>>> loadedMenu = {
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
    };

    for (final meal in suggested.menu.keys) {
      final futures =
          suggested.menu[meal]!.map((id) {
            return _db.collection('food').doc(id).get();
          }).toList();

      final docs = await Future.wait(futures);

      for (final d in docs) {
        if (!d.exists) continue;

        final data = d.data()!;

        data['id'] = d.id;

        loadedMenu[meal]!.add(data);
      }
    }

    return {"menu": loadedMenu, "liked": suggested.liked, "docId": doc.id};
  }

  // Convert STT AI trả về thành Food
  Future<Map<String, List<Map<String, dynamic>>>> buildFullMenu(Map<String, dynamic> aiMenu) async {
    final Map<String, List<Map<String, dynamic>>> fullMenu = {};

    for (final meal in ['Breakfast', 'Lunch', 'Dinner']) {
      final List items = aiMenu[meal] ?? [];

      final List<Map<String, dynamic>> foods = [];

      for (final item in items) {
        final snapshot =
            await _db
                .collection('food')
                .where('stt', isEqualTo: item['stt'])
                .limit(1)
                .get();

        if (snapshot.docs.isEmpty) {
          continue;
        }

        final doc = snapshot.docs.first;

        final data = doc.data();

        data['id'] = doc.id;

        foods.add(data);
      }

      fullMenu[meal] = foods;
    }

    return fullMenu;
  }
}
