import '../services/AdminService.dart';

class AdminController {

  final AdminService _service = AdminService();

  /// Tải thống kê tổng số món ăn, phân loại và người dùng cho trang quản trị
  Future<Map<String, int>> loadStats() async {

    final result = await _service.loadStats();

    return {
      "totalFoods": result["totalFoods"] ?? 0,
      "totalUsers": result["totalUsers"] ?? 0,
      "totalCategories": result["totalCategories"] ?? 0,
    };
  }

  /// Lấy thông tin hồ sơ quản trị viên
  Future<Map<String, dynamic>?> getAdminProfile() async {
    return await _service.getAdminProfile();
  }
}