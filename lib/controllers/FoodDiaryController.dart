import '../services/FoodDiaryService.dart';
import '../models/FoodDiary.dart';

class FoodDiaryController {

  final FoodDiaryService _service = FoodDiaryService();

  /// Tải nhật ký ăn uống cho một ngày được chọn
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

  /// Tải thống kê trong khoảng ngày
  Future<Map<String, dynamic>> loadPeriodStats({
    required DateTime startDate,
    required DateTime endDate,
    required String period,
  }) async {

    return await _service.loadPeriodStats(
      startDate: startDate,
      endDate: endDate,
      period: period,
    );
  }
  // Cập nhật bữa ăn của một món trong nhật ký. Gọi service để cập nhật trường meal trong Firestore
  Future<bool> updateFoodMeal({
    required String foodId,
    required String dateString,
    required String newMeal,
  }) async {
    return await _service.updateFoodMeal(
      foodId: foodId,
      dateString: dateString,
      newMeal: newMeal,
    );
  }

  /// Xóa một món ăn khỏi nhật ký
  /// Gọi service để xóa document từ Firestore
  Future<bool> deleteFoodFromDiary({
    required String foodId,
    required String dateString,
  }) async {
    return await _service.deleteFoodFromDiary(
      foodId: foodId,
      dateString: dateString,
    );
  }
}