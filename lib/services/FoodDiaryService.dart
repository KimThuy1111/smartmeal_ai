import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/FoodDiary.dart';

class FoodDiaryService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Chuyển ngày sang chuỗi định dạng yyyy-mm-dd để truy vấn nhật ký.
  String getDateString(DateTime date) {
    return date.toString().substring(0, 10);
  }

  // Tải nhật ký ăn uống theo ngày và tính tổng calories đã nạp.
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

    final snapshot = await _db
        .collection('food_diary')
        .where('userId', isEqualTo: uid)
        .where('date', isEqualTo: getDateString(selectedDate))
        .get();

    for (var doc in snapshot.docs) {
      final foodId = doc['foodId'];
      final meal = doc['meal'];

      final foodDoc = await _db.collection('food').doc(foodId).get();
      final data = foodDoc.data();

      if (data == null) {
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

  /// Thống kê calories theo khoảng ngày
  Future<Map<String, dynamic>> loadPeriodStats({
    required DateTime startDate,
    required DateTime endDate,
    required String period,
  }) async {

    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User chưa đăng nhập');
    }

    final uid = user.uid;

    // Calories mục tiêu mỗi ngày
    final targetCalories = await _getTargetCalories(uid);

    // Chuẩn hóa ngày
    final start = _dateOnly(startDate);
    final end = _dateOnly(endDate);

    /// Query đúng khoảng ngày thay vì lấy toàn bộ
    final snapshot = await _db
        .collection('food_diary')
        .where('userId', isEqualTo: uid)
        .where('date', isGreaterThanOrEqualTo: _formatDate(start))
        .where('date', isLessThanOrEqualTo: _formatDate(end))
        .get();

    /// calories theo từng ngày
    final Map<String, double> caloriesByDate = {};

    /// cache calories món ăn tránh query nhiều lần
    final Map<String, double> foodCaloriesCache = {};

    for (final doc in snapshot.docs) {

      final String date = doc['date'].toString();
      final foodId = doc['foodId'];

      double calories = 0;

      // Nếu chưa cache thì mới query food
      if (!foodCaloriesCache.containsKey(foodId)) {

        final foodDoc =
        await _db.collection('food').doc(foodId).get();

        final foodData = foodDoc.data();

        calories = (foodData?['calories'] ?? 0).toDouble();

        foodCaloriesCache[foodId] = calories;

      } else {

        calories = foodCaloriesCache[foodId]!;
      }

      caloriesByDate[date] =
          (caloriesByDate[date] ?? 0) + calories;
    }

    /// Danh sách ngày
    final List<DateTime> allDays = [];

    DateTime cursor = start;

    while (!cursor.isAfter(end)) {

      allDays.add(cursor);

      cursor = cursor.add(const Duration(days: 1));
    }

    /// Stats từng ngày
    List<Map<String, dynamic>> dailyStats = [];

    /// =======================
    /// THỐNG KÊ THEO THÁNG
    /// =======================
    if (period == 'month') {

      final Map<int, List<DateTime>> weekMap = {};

      for (final day in allDays) {

        final weekIndex =
            ((day.day - 1) ~/ 7) + 1;

        weekMap.putIfAbsent(
          weekIndex,
              () => [],
        );

        weekMap[weekIndex]!.add(day);
      }

      dailyStats = weekMap.entries.map((entry) {

        final weekDays = entry.value;

        double totalWeekCalories = 0;

        bool isOver = false;

        for (final day in weekDays) {

          final key = _formatDate(day);

          final calories =
              caloriesByDate[key] ?? 0;

          totalWeekCalories += calories;

          if (targetCalories > 0 &&
              calories > targetCalories) {

            isOver = true;
          }
        }

        final firstDay = weekDays.first.day;

        final lastDay = weekDays.last.day;

        return {

          'label':
          'Tuần ${entry.key}\n($firstDay-$lastDay)',

          'calories': totalWeekCalories,

          'hasData': totalWeekCalories > 0,

          'isOver': isOver,
        };

      }).toList();

    }

    /// =======================
    /// THỐNG KÊ TUẦN / RANGE
    /// =======================
    else {

      dailyStats = allDays.map((day) {

        final key = _formatDate(day);

        final calories =
            caloriesByDate[key] ?? 0;

        final hasData = calories > 0;

        final isOver =
            targetCalories > 0 &&
                calories > targetCalories;

        return {

          'date': day,

          'label': period == 'week'

              ? [
            'T2',
            'T3',
            'T4',
            'T5',
            'T6',
            'T7',
            'CN',
          ][day.weekday - 1]

              : '${day.day}/${day.month}',

          'calories': calories,

          'hasData': hasData,

          'isOver': isOver,
        };

      }).toList();
    }

    /// Tổng calories
    final totalCalories = dailyStats.fold<double>(
      0,
          (sum, item) => sum + item['calories'],
    );

    /// Chỉ tính những ngày có dữ liệu
    final daysWithData = dailyStats.where(
          (e) => e['hasData'] == true,
    ).length;

    /// Trung bình calories / ngày
    /// CHỈ tính ngày có dữ liệu
    final averageCalories =
    daysWithData == 0
        ? 0
        : totalCalories / daysWithData;

    /// Số ngày vượt mức
    final overDays = dailyStats.where(
          (e) => e['isOver'] == true,
    ).length;

    /// Ngày không vượt mức
    final normalDays = dailyStats.where(
          (e) =>
      e['hasData'] == true &&
          e['isOver'] == false,
    ).length;

    /// Ngày không có dữ liệu
    final emptyDays = dailyStats.where(
          (e) => e['hasData'] == false,
    ).length;

    return {
      'dailyStats': dailyStats,

      'targetCalories': targetCalories,

      'totalCalories': totalCalories,

      'averageCalories': averageCalories,

      'daysWithData': daysWithData,

      'overDays': overDays,

      'normalDays': normalDays,

      'emptyDays': emptyDays,

      'startDate': start,

      'endDate': end,
    };
  }

  /// Cập nhật bữa ăn của một mon ăn trong nhật ký
  /// Lấy document của món theo foodId, ngày, sau đó cập nhật trường meal
  Future<bool> updateFoodMeal({
    required String foodId,
    required String dateString,
    required String newMeal,
  }) async {
    try {
      // Lấy user hiện tại
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // Truy vấn document của món ăn này trong nhật ký theo foodId, userId, date, meal
      final snapshot = await _db
          .collection('food_diary')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: dateString)
          .where('foodId', isEqualTo: foodId)
          .get();

      // Nếu không tìm thấy document, trả về false
      if (snapshot.docs.isEmpty) {
        return false;
      }

      // Lấy document đầu tiên (thường chỉ có 1)
      final docId = snapshot.docs.first.id;

      // Cập nhật trường meal thành bữa ăn mới
      await _db.collection('food_diary').doc(docId).update({
        'meal': newMeal,
      });

      return true;
    } catch (e) {
      print('Lỗi cập nhật bữa ăn: $e');
      return false;
    }
  }

  /// Xóa một món ăn khỏi nhật ký ăn uống
  /// Lấy document theo foodId và ngày, sau đó xóa
  Future<bool> deleteFoodFromDiary({
    required String foodId,
    required String dateString,
  }) async {
    try {
      // Lấy user hiện tại
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      // Truy vấn document của món ăn này trong nhật ký
      final snapshot = await _db
          .collection('food_diary')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: dateString)
          .where('foodId', isEqualTo: foodId)
          .get();

      // Nếu không tìm thấy document, trả về false
      if (snapshot.docs.isEmpty) {
        return false;
      }

      // Lấy document đầu tiên (thường chỉ có 1)
      final docId = snapshot.docs.first.id;

      // Xóa document khỏi Firestore
      await _db.collection('food_diary').doc(docId).delete();

      return true;
    } catch (e) {
      print('Lỗi xóa món ăn: $e');
      return false;
    }
  }
}