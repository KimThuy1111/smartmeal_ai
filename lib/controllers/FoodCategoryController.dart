import '../models/FoodCategory.dart';
import '../services/FoodCategoryService.dart';

class FoodCategoryController {
  final FoodCategoryService _service = FoodCategoryService();

  Future<List<FoodCategory>> getAllCategories() async {
    return await _service.getAllCategories();
  }

  Future<void> addCategory(String name) async {
    final value = name.trim();
    if (value.isEmpty) {
      throw Exception("Tên phân loại không được để trống");
    }

    await _service.addCategory({"name": value});
  }

  Future<void> updateCategory(String id, String name) async {
    final value = name.trim();
    if (value.isEmpty) {
      throw Exception("Tên phân loại không được để trống");
    }

    await _service.updateCategory(id, {"name": value});
  }

  Future<void> deleteCategory(String id) async {
    await _service.deleteCategory(id);
  }
}
