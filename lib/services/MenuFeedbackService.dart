import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/Food.dart';
import '../models/SuggestedMenu.dart';
import '../models/User.dart';
import 'BaseService.dart';

class MenuFeedbackService extends BaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  DateTime _startOfDay(DateTime date) => DateTime(date.year, date.month, date.day);

  DateTime _startOfWeek(DateTime date) {
    final normalized = _startOfDay(date);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  DateTime _endOfWeek(DateTime date) {
    return _startOfWeek(date).add(const Duration(days: 6));
  }

  DateTime _startOfMonth(DateTime date) => DateTime(date.year, date.month, 1);

  DateTime _endOfMonth(DateTime date) => DateTime(date.year, date.month + 1, 0);

  DateTime _startOfYear(DateTime date) => DateTime(date.year, 1, 1);

  DateTime _endOfYear(DateTime date) => DateTime(date.year, 12, 31);

  String _formatDate(DateTime date) => DateFormat('dd/MM/yyyy').format(date);

  String _formatRange(DateTime start, DateTime end) {
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  Map<String, dynamic> _calculateRangeStats({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final startDay = _startOfDay(rangeStart);
    final endDay = _startOfDay(rangeEnd);
    final days = endDay.difference(startDay).inDays + 1;

    final labels = List.generate(days, (index) {
      final date = startDay.add(Duration(days: index));
      return DateFormat('dd/MM').format(date);
    });

    final likes = List<int>.filled(days, 0);
    final dislikes = List<int>.filled(days, 0);

    int currentLikeCount = 0;
    int currentDislikeCount = 0;
    int previousLikeCount = 0;
    int previousDislikeCount = 0;

    final previousStart = startDay.subtract(Duration(days: days));
    final previousEnd = startDay.subtract(const Duration(days: 1));

    for (final doc in docs) {
      final data = doc.data();
      if (data['status'] != 1) continue; // Chỉ lấy active
      
      final dateStr = data['date'];
      final liked = data['liked'];

      if (dateStr == null || liked == null) {
        continue;
      }

      final parsed = DateTime.tryParse(dateStr.toString());
      if (parsed == null) {
        continue;
      }

      final day = _startOfDay(parsed);

      if (!day.isBefore(startDay) && !day.isAfter(endDay)) {
        final index = day.difference(startDay).inDays;
        if (liked == true) {
          likes[index]++;
          currentLikeCount++;
        } else if (liked == false) {
          dislikes[index]++;
          currentDislikeCount++;
        }
      } else if (!day.isBefore(previousStart) && !day.isAfter(previousEnd)) {
        if (liked == true) {
          previousLikeCount++;
        } else if (liked == false) {
          previousDislikeCount++;
        }
      }
    }

    final currentTotal = currentLikeCount + currentDislikeCount;
    final previousTotal = previousLikeCount + previousDislikeCount;
    final currentLikeRate = currentTotal == 0 ? 0.0 : currentLikeCount / currentTotal * 100;
    final previousLikeRate = previousTotal == 0 ? 0.0 : previousLikeCount / previousTotal * 100;

    return {
      'labels': labels,
      'likes': likes,
      'dislikes': dislikes,
      'currentLikeCount': currentLikeCount,
      'currentDislikeCount': currentDislikeCount,
      'currentLikeRate': currentLikeRate,
      'previousLikeRate': previousLikeRate,
      'improvement': currentLikeRate - previousLikeRate,
    };
  }

  Map<String, dynamic> _aggregateStats({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required DateTime currentStart,
    required DateTime currentEnd,
    required DateTime previousStart,
    required DateTime previousEnd,
    required int bucketCount,
    required int Function(DateTime date) bucketIndex,
    required List<String> labels,
  }) {
    final likes = List<int>.filled(bucketCount, 0);
    final dislikes = List<int>.filled(bucketCount, 0);

    int currentLikeCount = 0;
    int currentDislikeCount = 0;
    int previousLikeCount = 0;
    int previousDislikeCount = 0;

    for (final doc in docs) {
      final data = doc.data();
      if (data['status'] != 1) continue; // Chỉ lấy active
      
      final dateStr = data['date'];
      final liked = data['liked'];

      if (dateStr == null || liked == null) {
        continue;
      }

      final parsed = DateTime.tryParse(dateStr.toString());
      if (parsed == null) {
        continue;
      }

      final day = _startOfDay(parsed);

      if (!day.isBefore(currentStart) && !day.isAfter(currentEnd)) {
        final index = bucketIndex(day);
        if (index >= 0 && index < bucketCount) {
          if (liked == true) {
            likes[index]++;
            currentLikeCount++;
          } else if (liked == false) {
            dislikes[index]++;
            currentDislikeCount++;
          }
        }
      } else if (!day.isBefore(previousStart) && !day.isAfter(previousEnd)) {
        if (liked == true) {
          previousLikeCount++;
        } else if (liked == false) {
          previousDislikeCount++;
        }
      }
    }

    final currentTotal = currentLikeCount + currentDislikeCount;
    final previousTotal = previousLikeCount + previousDislikeCount;
    final currentLikeRate = currentTotal == 0 ? 0.0 : currentLikeCount / currentTotal * 100;
    final previousLikeRate = previousTotal == 0 ? 0.0 : previousLikeCount / previousTotal * 100;

    return {
      'labels': labels,
      'likes': likes,
      'dislikes': dislikes,
      'currentLikeCount': currentLikeCount,
      'currentDislikeCount': currentDislikeCount,
      'currentLikeRate': currentLikeRate,
      'previousLikeRate': previousLikeRate,
      'improvement': currentLikeRate - previousLikeRate,
    };
  }

  /// Lấy danh sách thực đơn (chỉ active)
  Future<Map<String, dynamic>> loadMenus() async {
    int likeCount = 0;
    int dislikeCount = 0;
    int notRatedCount = 0;

    // Query chỉ lấy status = 1
    final snap = await _db
        .collection('suggested_menus')
        .where('status', isEqualTo: 1)
        .get();

    final List<Map<String, dynamic>> result = [];
    final Map<String, User> userCache = {};
    final Map<String, Food> foodCache = {};

    final userIds = snap.docs
        .map((doc) => doc.data()['userId'] as String?)
        .whereType<String>()
        .toSet();

    final foodIds = <String>{};

    for (final doc in snap.docs) {
      final menu = doc.data()['menu'] as Map<String, dynamic>?;
      if (menu == null) {
        continue;
      }

      for (final value in menu.values) {
        foodIds.addAll(List<String>.from(value as List));
      }
    }

    final userDocs = await Future.wait(
      userIds.map((id) => _db.collection('users').doc(id).get()),
    );

    for (final doc in userDocs) {
      if (doc.exists && doc.data()?['status'] == 1) {
        userCache[doc.id] = User.fromMap(doc.data()!, doc.id);
      }
    }

    final foodDocs = await Future.wait(
      foodIds.map((id) => _db.collection('food').doc(id).get()),
    );

    for (final doc in foodDocs) {
      if (doc.exists && doc.data()?['status'] == 1) {
        foodCache[doc.id] = Food.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
    }

    for (var doc in snap.docs) {
      final suggested = SuggestedMenu.fromMap(doc.data());

      if (suggested.liked == true) {
        likeCount++;
      } else if (suggested.liked == false) {
        dislikeCount++;
      } else {
        notRatedCount++;
      }

      final user = userCache[suggested.userId];

      if (user == null) {
        continue;
      }

      final List<String> allFoodIds = [];

      suggested.menu.forEach((key, value) {
        allFoodIds.addAll(value);
      });

      final List<String> names = [];

      for (var id in allFoodIds) {
        final food = foodCache[id];

        if (food != null) {
          names.add(food.name);
        }
      }

      result.add({
        'user': user,
        'foods': names,
        'liked': suggested.liked,
        'menu': suggested.menu,
      });
    }

    return {
      'menus': result,
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'notRatedCount': notRatedCount,
    };
  }

  /// Lấy thống kê trend (chỉ active)
  Future<Map<String, dynamic>> loadTrendStats({
    required String period,
    int selectedIndex = 0,
  }) async {
    // Query chỉ lấy status = 1
    final snap = await _db
        .collection('suggested_menus')
        .where('status', isEqualTo: 1)
        .get();
    final docs = snap.docs;

    final now = DateTime.now();

    final List<Map<String, dynamic>> options = [];
    String title;

    if (period == 'year') {
      final monthIndex = selectedIndex.clamp(0, 11);
      final currentStart = _startOfYear(now);
      final currentEnd = _endOfYear(now);
      final previousStart = DateTime(now.year - 1, 1, 1);
      final previousEnd = DateTime(now.year - 1, 12, 31);

      for (var month = 1; month <= 12; month++) {
        final monthStart = DateTime(now.year, month, 1);
        final monthEnd = _endOfMonth(monthStart);
        options.add({
          'label': 'Th$month',
          'range': _formatRange(monthStart, monthEnd),
          'start': monthStart.toIso8601String(),
          'end': monthEnd.toIso8601String(),
        });
      }

      title = 'Năm ${now.year}';

      final result = _aggregateStats(
        docs: docs,
        currentStart: currentStart,
        currentEnd: currentEnd,
        previousStart: previousStart,
        previousEnd: previousEnd,
        bucketCount: 12,
        bucketIndex: (date) => date.month - 1,
        labels: List<String>.generate(12, (index) => 'Th${index + 1}'),
      );

      return {
        ...result,
        'period': 'year',
        'title': title,
        'range': _formatRange(DateTime(now.year, monthIndex + 1, 1), _endOfMonth(DateTime(now.year, monthIndex + 1, 1))),
        'options': options,
        'selectedIndex': monthIndex,
      };
    }

    if (period == 'month') {
      final monthStart = _startOfMonth(now);
      final monthEnd = _endOfMonth(now);
      final totalDays = monthEnd.day;
      final weekCount = ((totalDays + 6) / 7).floor();
      final weekIndex = selectedIndex.clamp(0, weekCount - 1);
      final previousMonthStart = _startOfMonth(DateTime(now.year, now.month - 1, 1));
      final previousMonthEnd = _endOfMonth(previousMonthStart);

      for (var week = 0; week < weekCount; week++) {
        final start = monthStart.add(Duration(days: week * 7));
        final end = week == weekCount - 1
            ? monthEnd
            : start.add(const Duration(days: 6));

        options.add({
          'label': 'Tuần ${week + 1}',
          'range': _formatRange(start, end),
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        });
      }

      final selectedRangeStart = monthStart.add(Duration(days: weekIndex * 7));
      final selectedRangeEnd = weekIndex == weekCount - 1
          ? monthEnd
          : selectedRangeStart.add(const Duration(days: 6));

      final result = _aggregateStats(
        docs: docs,
        currentStart: monthStart,
        currentEnd: monthEnd,
        previousStart: previousMonthStart,
        previousEnd: previousMonthEnd,
        bucketCount: weekCount,
        bucketIndex: (date) => ((date.day - 1) / 7).floor().clamp(0, weekCount - 1),
        labels: List<String>.generate(weekCount, (index) => 'Tuần ${index + 1}'),
      );

      return {
        ...result,
        'period': 'month',
        'title': 'Tháng ${now.month}/${now.year}',
        'range': _formatRange(selectedRangeStart, selectedRangeEnd),
        'options': options,
        'selectedIndex': weekIndex,
      };
    }

    final rangeStart = _startOfWeek(now);
    final rangeEnd = _endOfWeek(now);
    final previousStart = rangeStart.subtract(const Duration(days: 7));
    final previousEnd = rangeStart.subtract(const Duration(days: 1));

    final result = _aggregateStats(
      docs: docs,
      currentStart: rangeStart,
      currentEnd: rangeEnd,
      previousStart: previousStart,
      previousEnd: previousEnd,
      bucketCount: 7,
      bucketIndex: (date) => date.weekday - 1,
      labels: const ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'],
    );

    return {
      ...result,
      'period': 'week',
      'title': 'Tuần hiện tại',
      'range': _formatRange(rangeStart, rangeEnd),
      'options': const [],
      'selectedIndex': 0,
    };
  }
}
