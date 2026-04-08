import '../services/SuggestService.dart';

class SuggestController {

  final SuggestService _service = SuggestService();

  Map<String, List<Map<String, dynamic>>>? cachedMenu;
  String? cachedDate;
  Map<int, Map<String, dynamic>> foodCache = {};

  // Kiểm tra cache còn hợp lệ hay không
  bool isCacheValid(String today) {
    return cachedMenu != null && cachedDate == today;
  }

  // Lưu cache thực đơn
  void setCache(Map<String, List<Map<String, dynamic>>> menu, String today) {
    cachedMenu = menu;
    cachedDate = today;
  }

  // Xóa cache thực đơn
  void clearCache() {
    cachedMenu = null;
    cachedDate = null;
  }

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

  Future<List<int>> loadRecentFoodHistory() => _service.loadRecentFoodHistory();

  Future<Map<String, double>> loadTodayCalories() => _service.loadTodayCalories();

  Future<String?> saveMenu(
      Map<String, List<Map<String, dynamic>>> menu
      ) {
    return _service.saveMenu(menu);
  }

  Future<List<int>> getExcludedFoods() async {
    return await _service.getTodaySuggestedFoodStt();
  }
}