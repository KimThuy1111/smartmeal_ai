import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import 'BaseService.dart';

class HomeService extends BaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Tải dữ liệu hồ sơ và nhu cầu dinh dưỡng (chỉ active)
  Future<Map<String, dynamic>> loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {};
    }

    final uid = user.uid;

    // Lấy document mới nhất có userId = uid, status = 1
    // Query đơn giản: chỉ userId, không cần composite index
    DocumentSnapshot? userDoc;
    try {
      final snapshot = await _db
          .collection('users')
          .where('userId', isEqualTo: uid)
          .get();

      // Filter status=1 và sort trong code
      final activeDocs = snapshot.docs
          .where((doc) => doc['status'] == 1)
          .toList();
      
      if (activeDocs.isNotEmpty) {
        // Sort by createdAt descending
        activeDocs.sort((a, b) {
          final createdAtA = a['createdAt'] as Timestamp?;
          final createdAtB = b['createdAt'] as Timestamp?;
          if (createdAtA == null || createdAtB == null) return 0;
          return createdAtB.compareTo(createdAtA);
        });
        userDoc = activeDocs.first;
      }
    } catch (e) {
      print('Error querying userId: $e');
      // Fallback: query document cũ nếu không có userId field
      userDoc = await _db.collection('users').doc(uid).get();
    }

    if (userDoc == null || !userDoc.exists) {
      return {};
    }

    final data = userDoc.data() as Map<String, dynamic>?;
    if (data?['status'] != 1) {
      return {};
    }

    String name = data?['name'] ?? '';
    String goal = data?['goal'] ?? '';

    int calories = 0;
    double protein = 0;
    double carb = 0;
    double fat = 0;

    // Nếu đã có thông tin dinh dưỡng
    if (data?['nutrition'] != null) {
      final nutrition = data!['nutrition'];
      final caloriesValue = nutrition['Calories'];
      final proteinValue = nutrition['Protein'];
      final carbValue = nutrition['carb'];
      final fatValue = nutrition['Fat'];
      
      calories = (caloriesValue is int) ? caloriesValue : (caloriesValue as num?)?.round() ?? 0;
      protein = (proteinValue is double) ? proteinValue : (proteinValue as num?)?.toDouble() ?? 0;
      carb = (carbValue is double) ? carbValue : (carbValue as num?)?.toDouble() ?? 0;
      fat = (fatValue is double) ? fatValue : (fatValue as num?)?.toDouble() ?? 0;
    } else {
      try {
        // Gửi yêu cầu tính TDEE
        final response = await http.post(
          Uri.parse('https://smartmeal-ai-production.up.railway.app/tdee'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'age': data?['age'],
            'gender': data?['gender'],
            'height': data?['height'],
            'weight': data?['weight'],
            'activity': data?['activity'],
            'goal': data?['goal'] ?? 'Duy trì cân nặng',
            'breakfast_cal': 0,
            'lunch_cal': 0,
            'dinner_cal': 0,
          }),
        );

        if (response.statusCode == 200) {
          final nutrition = jsonDecode(response.body);
          final caloriesValue = nutrition['Calories'];
          final proteinValue = nutrition['Protein'];
          final carbValue = nutrition['carb'];
          final fatValue = nutrition['Fat'];
          
          calories = (caloriesValue is int) ? caloriesValue : (caloriesValue as num?)?.round() ?? 0;
          protein = (proteinValue is double) ? proteinValue : (proteinValue as num?)?.toDouble() ?? 0;
          carb = (carbValue is double) ? carbValue : (carbValue as num?)?.toDouble() ?? 0;
          fat = (fatValue is double) ? fatValue : (fatValue as num?)?.toDouble() ?? 0;
  
          try {
            // Update nutrition vào document mới nhất
            await _db.collection('users').doc(userDoc.id).update({'nutrition': nutrition});
          } catch (e) {
            print('Error updating nutrition: $e');
            // Vẫn hiển thị dù lưu thất bại
          }
        }
      } catch (e) {
        // Lỗi kết nối
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

  /// Tính lại TDEE khi người dùng cập nhật thông tin cá nhân
  /// Lưu nutrition vào document mới nhất có status = 1
  Future<Map<String, dynamic>> recalculateTDEE({
    required int age,
    required String gender,
    required double height,
    required double weight,
    required String activity,
    required String goal,
  }) async {
    try {
      // Gửi yêu cầu tính TDEE
      final response = await http.post(
        Uri.parse('https://smartmeal-ai-production.up.railway.app/tdee'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'age': age,
          'gender': gender,
          'height': height,
          'weight': weight,
          'activity': activity,
          'goal': goal,
          'breakfast_cal': 0,
          'lunch_cal': 0,
          'dinner_cal': 0,
        }),
      );

      if (response.statusCode == 200) {
        final nutrition = jsonDecode(response.body);
        
        // Lưu thông tin dinh dưỡng vào document mới nhất
        final user = _auth.currentUser;
        if (user != null) {
          try {
            // Query đơn giản: chỉ userId, không cần composite index
            final snapshot = await _db
                .collection('users')
                .where('userId', isEqualTo: user.uid)
                .get();

            String? docId;
            if (snapshot.docs.isNotEmpty) {
              // Filter status=1 và sort trong code
              final activeDocs = snapshot.docs
                  .where((doc) => doc['status'] == 1)
                  .toList();
              
              if (activeDocs.isNotEmpty) {
                activeDocs.sort((a, b) {
                  final createdAtA = a['createdAt'] as Timestamp?;
                  final createdAtB = b['createdAt'] as Timestamp?;
                  if (createdAtA == null || createdAtB == null) return 0;
                  return createdAtB.compareTo(createdAtA);
                });
                docId = activeDocs.first.id;
              }
            }

            if (docId != null) {
              await _db.collection('users').doc(docId).update({
                'nutrition': nutrition
              });
            }
          } catch (e) {
            print('Error saving nutrition: $e');
            // Vẫn trả về dù lưu thất bại
          }
        }
        
        final caloriesValue = nutrition['Calories'];
        final proteinValue = nutrition['Protein'];
        final carbValue = nutrition['carb'];
        final fatValue = nutrition['Fat'];
        
        return {
          'success': true,
          'nutrition': nutrition,
          'calories': (caloriesValue is int) ? caloriesValue : (caloriesValue as num?)?.round() ?? 0,
          'protein': (proteinValue is double) ? proteinValue : (proteinValue as num?)?.toDouble() ?? 0,
          'carb': (carbValue is double) ? carbValue : (carbValue as num?)?.toDouble() ?? 0,
          'fat': (fatValue is double) ? fatValue : (fatValue as num?)?.toDouble() ?? 0,
        };
      } else {
        return {
          'success': false,
          'error': 'Tính TDEE thất bại',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Lỗi kết nối: $e',
      };
    }
  }

  /// Tải danh sách bữa ăn hôm nay (chỉ active)
  Future<Map<String, dynamic>> loadTodayMeals() async {
    final user = _auth.currentUser;
    if (user == null) {
      return {};
    }

    final String today = DateTime.now().toString().substring(0, 10);

    // Query chỉ lấy status = 1
    final snapshot = await _db
        .collection('food_diary')
        .where('userId', isEqualTo: user.uid)
        .where('date', isEqualTo: today)
        .where('status', isEqualTo: 1)
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

      // Phân loại bữa ăn
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
