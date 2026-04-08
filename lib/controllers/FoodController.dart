import '../services/FoodService.dart';
import '../models/Food.dart';
import 'dart:io';

class FoodController {

  final FoodService _service = FoodService();

  // Lấy món ăn theo ID
  Future<Food?> getFoodById(String id) async {
    return await _service.getFoodById(id);
  }

  // Tìm kiếm món ăn
  Future<List<Food>> searchFood(String keyword) async {

    if (keyword.trim().isEmpty) return [];

    return await _service.searchFood(keyword);
  }

  // Lấy danh sách món ăn nổi bật
  Future<List<Food>> getTopFoods(int limit) async {
    return await _service.getTopFoods(limit);
  }

  // Thêm món ăn vào nhật ký
  Future<void> addFoodToDiary({
    required String foodId,
    required String meal,
  }) async {

    if (meal.isEmpty) {
      throw Exception("Meal không hợp lệ");
    }

    await _service.addFoodToDiary(
      foodId: foodId,
      meal: meal,
    );
  }
  // Kiểm tra xử lý đồng thời
  Future<void> testConcurrent({
    required String keyword,
    required int totalRequests,
  }) async {
    await _service.testConcurrent(
      keyword: keyword,
      totalRequests: totalRequests,
    );
  }

  // Tải ảnh lên
  Future<String?> uploadImage(File file) async {
    return await _service.uploadImage(file);
  }

  // Thêm món ăn mới
  Future<void> addFood(Map<String, dynamic> data) async {

    if (!data.containsKey("name") || data["name"].isEmpty) {
      throw Exception("Tên món ăn không được để trống");
    }

    await _service.addFood(data);
  }

  // Cập nhật món ăn
  Future<void> updateFood(String id, Map<String, dynamic> data) async {
    await _service.updateFood(id, data);
  }

  // Xóa món ăn
  Future<void> deleteFood(String id) async {
    await _service.deleteFood(id);
  }

  // Lấy tất cả món ăn
  Future<List<Food>> getAllFoods() async {
    return await _service.getAllFoods();
  }

  // Lấy món ăn theo thực đơn
  Future<Map<String, List<Map<String, dynamic>>>> getFoodsByMenu(
      Map<String, List<String>> menu) async {

    return await _service.getFoodsByMenu(menu);
  }
}