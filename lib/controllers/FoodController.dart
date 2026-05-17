import '../services/FoodService.dart';
import '../models/Food.dart';
import 'dart:io';

class FoodController {

  final FoodService _service = FoodService();

  /// 5.5 Lấy thông tin chi tiết một món ăn theo ID
  Future<Food?> getFoodById(String id) async {
    return await _service.getFoodById(id);
  }

  /// 3.3 Tìm kiếm món ăn theo từ khóa
  Future<List<Food>> searchFood(String keyword) async {
    // Kiểm tra từ khóa có hợp lệ không
    if (keyword.trim().isEmpty) return [];

    return await _service.searchFood(keyword);
  }

  /// 2a.3 Lấy danh sách món ăn nổi bật
  Future<List<Food>> getTopFoods(int limit) async {
    return await _service.getTopFoods(limit);
  }

  /// 4.3 Thêm món ăn vào nhật ký theo bữa ăn
  Future<void> addFoodToDiary({
    required String foodId,
    required String meal,
  }) async {
    // Kiểm tra dữ liệu hợp lệ
    if (meal.isEmpty) {
      throw Exception("Meal không hợp lệ");
    }

    await _service.addFoodToDiary(
      foodId: foodId,
      meal: meal,
    );
  }

  /// Kiểm tra xử lý đồng thời (concurrent requests)
  Future<void> testConcurrent({
    required String keyword,
    required int totalRequests,
  }) async {
    await _service.testConcurrent(
      keyword: keyword,
      totalRequests: totalRequests,
    );
  }

  /// Tải ảnh lên Cloudinary
  Future<String?> uploadImage(File file) async {
    return await _service.uploadImage(file);
  }

  /// Thêm một món ăn mới vào database
  Future<void> addFood(Map<String, dynamic> data) async {
    // Kiểm tra dữ liệu bắt buộc
    if (!data.containsKey("name") || data["name"].isEmpty) {
      throw Exception("Tên món ăn không được để trống");
    }

    await _service.addFood(data);
  }

  /// Cập nhật thông tin món ăn
  Future<void> updateFood(String id, Map<String, dynamic> data) async {
    await _service.updateFood(id, data);
  }

  /// Xóa một món ăn khỏi database
  Future<void> deleteFood(String id) async {
    await _service.deleteFood(id);
  }

  /// Lấy tất cả các món ăn từ database
  Future<List<Food>> getAllFoods() async {
    return await _service.getAllFoods();
  }

  /// Lấy danh sách các món ăn dựa trên thực đơn gợi ý
  Future<Map<String, List<Map<String, dynamic>>>> getFoodsByMenu(
      Map<String, List<String>> menu) async {

    return await _service.getFoodsByMenu(menu);
  }
}