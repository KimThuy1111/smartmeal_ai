import '../services/FoodDiaryService.dart';
import '../models/FoodDiary.dart';

class FoodDiaryController {

  final FoodDiaryService _service = FoodDiaryService();

  // Tải nhật ký ăn uống
  Future<Map<String, dynamic>> loadDiary(DateTime date) async {

    final result = await _service.loadDiary(date);

    double total = result["totalCalories"] ?? 0;
    double target = result["targetCalories"] ?? 0;

    bool isOver = total > target && target > 0;

    return {
      "breakfast": result["breakfast"] ?? <FoodDiary>[],
      "lunch": result["lunch"] ?? <FoodDiary>[],
      "dinner": result["dinner"] ?? <FoodDiary>[],
      "totalCalories": total,
      "targetCalories": target,
      "isOver": isOver,
    };
  }

  Future<Map<String, dynamic>> loadPeriodStats({
    required DateTime referenceDate,
    required String period,
  }) async {
    return await _service.loadPeriodStats(
      referenceDate: referenceDate,
      period: period,
    );
  }
}