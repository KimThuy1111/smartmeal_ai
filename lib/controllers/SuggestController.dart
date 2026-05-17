import '../services/SuggestService.dart';

class SuggestController {

  final SuggestService _service = SuggestService();

  Map<String, List<Map<String, dynamic>>>? cachedMenu;
  String? cachedDate;
  Map<int, Map<String, dynamic>> foodCache = {};

  /// Kiểm tra cache thực đơn còn hợp lệ cho ngày hôm nay không
  bool isCacheValid(String today) {
    return cachedMenu != null && cachedDate == today;
  }

  /// Lưu cache thực đơn gợi ý cho ngày hiện tại
  void setCache(Map<String, List<Map<String, dynamic>>> menu, String today) {
    cachedMenu = menu;
    cachedDate = today;
  }

  /// Xóa cache thực đơn để tải lại dữ liệu mới
  void clearCache() {
    cachedMenu = null;
    cachedDate = null;
  }

  /// 4. Gọi API gợi ý thực đơn từ service
  /// Fetch thực đơn gợi ý dựa trên thông tin người dùng và lượng calo đã ăn
  Future<Map<String, dynamic>> fetchMenu(
      Map userData,
      double breakfast,
      double lunch,
      double dinner,
      List<int> recentFoods,
      List<int> excludedFoods,
      ) async {

    final data = await _service.fetchMenuAPI(
      userData: userData,
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      recentFoods: recentFoods,
      excludedFoods: excludedFoods,
    );

    return data;
  }

  /// 2.1 Lấy lịch sử món ăn 3 ngày gần nhất
  Future<List<int>> loadRecentFoodHistory() => _service.loadRecentFoodHistory();

  /// 2.3 Lấy tổng calories đã ăn trong ngày theo từng bữa
  Future<Map<String, double>> loadTodayCalories() => _service.loadTodayCalories();

  /// 7 Lưu thực đơn gợi ý vào Firestore và trả về ID document
  Future<String?> saveMenu(
      Map<String, List<Map<String, dynamic>>> menu
      ) {
    return _service.saveMenu(menu);
  }

  /// Lấy danh sách các món đã được gợi ý hôm nay để tránh trùng lặp
  Future<List<int>> getExcludedFoods() async {
    return await _service.getTodaySuggestedFoodStt();
  }
}