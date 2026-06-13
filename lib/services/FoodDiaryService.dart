import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/FoodDiary.dart';
import 'BaseService.dart';

class FoodDiaryService extends BaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Chuyển ngày sang chuỗi định dạng yyyy-mm-dd để truy vấn nhật ký.
  String getDateString(DateTime date) {
    return date.toString().substring(0, 10);
  }

  // Tải nhật ký ăn uống theo ngày và tính tổng calories (chỉ active)
  Future<Map<String, dynamic>> loadDiary(DateTime selectedDate) async {
    final uid = _auth.currentUser!.uid;
    double targetCalories = 0;
    double totalCalories = 0;
    List<FoodDiary> breakfast = [];
    List<FoodDiary> lunch = [];
    List<FoodDiary> dinner = [];
    final userDoc = await _db.collection('users').doc(uid).get();

    final userData = userDoc.data();
    if (userData != null && userData['nutrition'] != null) {
      final nutrition = userData['nutrition'];
      targetCalories = (nutrition['Calories'] ?? 0).toDouble();
    }
    // Query chỉ lấy status = 1
    final snapshot = await _db
        .collection('food_diary')
        .where('userId', isEqualTo: uid)
        .where('date', isEqualTo: getDateString(selectedDate))
        .where('status', isEqualTo: 1)
        .get();

    for (var doc in snapshot.docs) {
      final foodId = doc['foodId'];
      final meal = doc['meal'];
      final foodDoc = await _db.collection('food').doc(foodId).get();
      final data = foodDoc.data();

      // Chỉ thêm vào nếu food tồn tại, status = 1 (active), và có dữ liệu
      if (data == null || data['status'] != 1) {
        continue;
      }
      final item = FoodDiary(
        foodId: foodId,
        meal: meal,
        date: getDateString(selectedDate),
        name: data['name'],
        image: data['image'],
        calories: (data['calories'] ?? 0).toDouble(),
      );
      totalCalories += item.calories;
      switch (meal) {
        case 'breakfast':
          breakfast.add(item);
          break;
        case 'lunch':
          lunch.add(item);
          break;
        case 'dinner':
          dinner.add(item);
          break;
      }
    }
    return {
      'breakfast': breakfast,
      'lunch': lunch,
      'dinner': dinner,
      'totalCalories': totalCalories,
      'targetCalories': targetCalories,
    };
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<double> _getTargetCalories(String uid) async {
    double targetCalories = 0;

    final userDoc = await _db.collection('users').doc(uid).get();
    final userData = userDoc.data();

    if (userData != null && userData['nutrition'] != null) {
      final nutrition = userData['nutrition'];
      targetCalories = (nutrition['Calories'] ?? 0).toDouble();
    }

    return targetCalories;
  }

  // Thống kê calories theo khoảng ngày
  Future<Map<String, dynamic>> loadPeriodStats({required DateTime startDate, required DateTime endDate, required String period}) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User chưa đăng nhập');
    }

    final uid = user.uid;
    final targetCalories = await _getTargetCalories(uid);
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);

    final snapshot = await _db
        .collection('food_diary')
        .where('userId', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: _formatDate(start))
        .where('date', isLessThanOrEqualTo: _formatDate(end))
        .where('status', isEqualTo: 1)
        .get();

    final caloriesByDate = await _calculateCaloriesByDate(snapshot);

    final allDays = _generateDateRange(start, end);

    final dailyStats = period == 'month'
        ? _buildMonthStats(allDays, caloriesByDate, targetCalories)
        : _buildDailyStats(allDays, caloriesByDate, targetCalories, period);

    final summary = _calculateSummary(dailyStats);

    return {
      'dailyStats': dailyStats,
      'targetCalories': targetCalories,
      ...summary,
      'startDate': start,
      'endDate': end,
    };
  }

  // Hàm tính calories theo từng ngày
  Future<Map<String, double>> _calculateCaloriesByDate(QuerySnapshot snapshot) async {
    final Map<String, double> caloriesByDate = {};
    final Map<String, double> foodCaloriesCache = {};

    for (final doc in snapshot.docs) {
      final String date = doc['date'].toString();
      final String foodId = doc['foodId'];
      double calories = 0;

      if (!foodCaloriesCache.containsKey(foodId)) {
        final foodDoc = await _db
            .collection('food')
            .doc(foodId)
            .get();
        final foodData = foodDoc.data();
        if (foodData != null && foodData['status'] == 1) {

          calories = (foodData['calories'] ?? 0).toDouble();
        }

        foodCaloriesCache[foodId] = calories;
      } else {
        calories = foodCaloriesCache[foodId]!;
      }

      caloriesByDate[date] = (caloriesByDate[date] ?? 0) + calories;
    }

    return caloriesByDate;
  }

  // Hàm tạo danh sách ngày
  List<DateTime> _generateDateRange(DateTime start, DateTime end) {

    final List<DateTime> days = [];

    DateTime cursor = start;

    while (!cursor.isAfter(end)) {

    
    days.add(cursor);

    cursor = cursor.add(const Duration(days: 1));

    }

    return days;
  }

  // Hàm thống kê theo tháng
  List<Map<String, dynamic>> _buildMonthStats(List<DateTime> allDays, Map<String, double> caloriesByDate, double targetCalories) {
    final Map<int, List<DateTime>> weekMap = {};

    for (final day in allDays) {
      final weekIndex = ((day.day - 1) ~/ 7) + 1;
      weekMap.putIfAbsent(weekIndex, () => []);
      weekMap[weekIndex]!.add(day);
    }

    return weekMap.entries.map((entry) {
      final weekDays = entry.value;
      double totalWeekCalories = 0;
      bool isOver = false;
      for (final day in weekDays) {
        final key = _formatDate(day);
        final calories = caloriesByDate[key] ?? 0;
        totalWeekCalories += calories;
        if (targetCalories > 0 && calories > targetCalories) {
          isOver = true;
        }
      }

      final firstDay = weekDays.first.day;
      final lastDay = weekDays.last.day;

      return {
        'label': 'Tuần ${entry.key}\n($firstDay-$lastDay)',

        'calories': totalWeekCalories,

        'hasData': totalWeekCalories > 0,

        'isOver': isOver,
      };
    }).toList();
  }

  // Hàm thống kê theo tuần hoặc khoảng ngày
  List<Map<String, dynamic>> _buildDailyStats(List<DateTime> allDays, Map<String, double> caloriesByDate, double targetCalories, String period) {
    return allDays.map((day) {
      final key = _formatDate(day);
      final calories = caloriesByDate[key] ?? 0;
      final hasData = calories > 0;
      final isOver = targetCalories > 0 && calories > targetCalories;

      return {
      'date': day,
      'label': period == 'week'
      ? ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][day.weekday - 1]
      : '${day.day}/${day.month}',
      'calories': calories,
      'hasData': hasData,
      'isOver': isOver,
      };
    }).toList();
  }

  // Hàm tổng hợp thống kê
  Map<String, dynamic> _calculateSummary(List<Map<String, dynamic>> dailyStats) {
    final totalCalories = dailyStats.fold<double>(0, (sum, item) => sum + item['calories']);
    final daysWithData = dailyStats.where((e) => e['hasData'] == true).length;
    final averageCalories = daysWithData == 0 ? 0 : totalCalories / daysWithData;
    final overDays = dailyStats.where((e) => e['isOver'] == true).length;
    final normalDays = dailyStats.where((e) => e['hasData'] == true && e['isOver'] == false).length;
    final emptyDays = dailyStats.where((e) => e['hasData'] == false).length;

    return {
      'totalCalories': totalCalories,
      'averageCalories': averageCalories,
      'daysWithData': daysWithData,
      'overDays': overDays,
      'normalDays': normalDays,
      'emptyDays': emptyDays,
    };
  }


  // Cập nhật bữa ăn
  Future<bool> updateFoodMeal({required String foodId, required String dateString, required String newMeal}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final snapshot = await _db
          .collection('food_diary')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: dateString)
          .where('foodId', isEqualTo: foodId)
          .where('status', isEqualTo: 1)
          .get();

      if (snapshot.docs.isEmpty) return false;

      final oldDocId = snapshot.docs.first.id;
      final oldData = snapshot.docs.first.data();

      // Soft delete cũ
      await _db.collection('food_diary').doc(oldDocId).update({
        'status': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Tạo document mới
      await _db.collection('food_diary').add({
        ...oldData,
        'meal': newMeal,
        'status': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      });

      return true;
    } catch (e) {
      print('Lỗi cập nhật bữa ăn: $e');
      return false;
    }
  }

  // Cho phép thay đổi ngày ăn của một mon ăn trong nhật ký
  Future<bool> updateFoodDate({required String foodId, required String oldDateString, required String newDateString}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      // Kiểm tra nếu ngày mới trùng với ngày cũ
      if (oldDateString == newDateString) return false;
      // Tìm document cũ theo foodId, userId và ngày cũ
      final snapshot = await _db
          .collection('food_diary')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: oldDateString)
          .where('foodId', isEqualTo: foodId)
          .where('status', isEqualTo: 1)
          .get();
      if (snapshot.docs.isEmpty) return false;
      final oldDocId = snapshot.docs.first.id;
      final oldData = snapshot.docs.first.data();

      // xóa document cũ
      await _db.collection('food_diary').doc(oldDocId).update({
        'status': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Tạo document mới với ngày mới
      await _db.collection('food_diary').add({
        ...oldData,
        'date': newDateString, // Cập nhật ngày mới
        'status': 1,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': null,
      });

      return true;
    } catch (e) {
      print('Lỗi cập nhật ngày ăn: $e');
      return false;
    }
  }

  // Xóa món ăn khỏi nhật ký
  Future<bool> deleteFoodFromDiary({required String foodId, required String dateString}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      final snapshot = await _db
          .collection('food_diary')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: dateString)
          .where('foodId', isEqualTo: foodId)
          .where('status', isEqualTo: 1)
          .get();

      if (snapshot.docs.isEmpty) return false;
      final docId = snapshot.docs.first.id;

      await _db.collection('food_diary').doc(docId).update({
        'status': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Lỗi xóa món ăn: $e');
      return false;
    }
  }
}
