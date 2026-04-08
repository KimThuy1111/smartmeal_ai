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

  Future<Map<String, dynamic>> loadPeriodStats({
    required DateTime referenceDate,
    required String period,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User chưa đăng nhập');
    }

    final uid = user.uid;
    final targetCalories = await _getTargetCalories(uid);

    final allDocs = await _db
        .collection('food_diary')
        .where('userId', isEqualTo: uid)
        .get();

    final normalizedReference = _dateOnly(referenceDate);
    late final DateTime startDate;
    late final DateTime endDate;

    if (period == 'week') {
      startDate = normalizedReference.subtract(
        Duration(days: normalizedReference.weekday - 1),
      );
      endDate = startDate.add(const Duration(days: 6));
    } else {
      startDate = DateTime(normalizedReference.year, normalizedReference.month, 1);
      endDate = DateTime(
        normalizedReference.year,
        normalizedReference.month + 1,
        0,
      );
    }

    final Map<String, double> caloriesByDate = {};
    for (var doc in allDocs.docs) {
      final dateString = doc['date']?.toString();
      if (dateString == null || dateString.length < 10) continue;

      final parsed = DateTime.tryParse(dateString);
      if (parsed == null) continue;

      final day = _dateOnly(parsed);
      if (day.isBefore(startDate) || day.isAfter(endDate)) continue;

      final foodId = doc['foodId'];
      final foodDoc = await _db.collection('food').doc(foodId).get();
      final foodData = foodDoc.data();
      if (foodData == null) continue;

      final calories = (foodData['calories'] ?? 0).toDouble();
      final key = _formatDate(day);
      caloriesByDate[key] = (caloriesByDate[key] ?? 0) + calories;
    }

    final List<DateTime> days = [];
    DateTime cursor = startDate;
    while (!cursor.isAfter(endDate)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }

    final List<Map<String, dynamic>> dailyStats = days.map((day) {
      final key = _formatDate(day);
      final calories = caloriesByDate[key] ?? 0;
      return {
        'date': day,
        'label': period == 'week'
            ? ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'][day.weekday - 1]
            : '${day.day}',
        'calories': calories,
        'isOver': targetCalories > 0 && calories > targetCalories,
      };
    }).toList();

    final totalCalories = dailyStats.fold<double>(
      0,
      (sum, item) => sum + (item['calories'] as double),
    );

    final daysWithData = dailyStats.where((item) => (item['calories'] as double) > 0).length;
    final averageCalories = dailyStats.isEmpty
        ? 0
        : totalCalories / dailyStats.length;
    final overDays = dailyStats.where((item) => item['isOver'] == true).length;
    final maxCalories = dailyStats.isEmpty
        ? 0
        : dailyStats
            .map((e) => e['calories'] as double)
            .reduce((a, b) => a > b ? a : b);

    return {
      'period': period,
      'startDate': startDate,
      'endDate': endDate,
      'targetCalories': targetCalories,
      'totalCalories': totalCalories,
      'averageCalories': averageCalories,
      'daysWithData': daysWithData,
      'overDays': overDays,
      'maxCalories': maxCalories,
      'dailyStats': dailyStats,
    };
  }
}