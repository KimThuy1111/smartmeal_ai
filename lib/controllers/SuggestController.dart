import '../services/SuggestService.dart';

class SuggestController {
  final SuggestService _service = SuggestService();

  Map<String, List<Map<String, dynamic>>>? cachedMenu;
  String? cachedDate;
  Map<int, Map<String, dynamic>> foodCache = {};

  // Kiểm tra cache thực đơn còn hợp lệ cho ngày hôm nay không
  bool isCacheValid(String today) {
    return cachedMenu != null && cachedDate == today;
  }

  // Lưu cache thực đơn gợi ý cho ngày hiện tại
  void setCache(Map<String, List<Map<String, dynamic>>> menu, String today) {
    cachedMenu = menu;
    cachedDate = today;
  }

  // Xóa cache thực đơn để tải lại dữ liệu mới
  void clearCache() {
    cachedMenu = null;
    cachedDate = null;
  }

  // Fetch thực đơn gợi ý dựa trên thông tin người dùng và lượng calo đã ăn
  Future<Map<String, dynamic>> fetchMenu(Map userData, double breakfast, double lunch, double dinner, List<int> recentFoods, List<int> excludedFoods) async {
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

  // Lấy lịch sử món ăn 3 ngày gần nhất
  Future<List<int>> loadRecentFoodHistory() => _service.loadRecentFoodHistory();

  // Lấy tổng calories đã ăn trong ngày theo từng bữa
  Future<Map<String, double>> loadTodayCalories() => _service.loadTodayCalories();

  // Lưu thực đơn gợi ý vào Firestore và trả về ID document
  Future<String?> saveMenu(Map<String, List<Map<String, dynamic>>> menu) {
    return _service.saveMenu(menu);
  }

  // Lấy danh sách các món đã được gợi ý hôm nay để tránh trùng lặp
  Future<List<int>> getExcludedFoods() async {
    return await _service.getTodaySuggestedFoodStt();
  }

  Future<void> rateMenu({required String menuId, required bool liked}) async {
    await _service.rateMenu(menuId: menuId, liked: liked);
  }

  Future<void> addFoodToDiary({
    required String foodId,
    required String meal,
    required String date,
  }) async {
    await _service.addFoodToDiary(foodId: foodId, meal: meal, date: date);
  }

  Future<Map<String, dynamic>> loadTodaySummary() async {
    return await _service.loadTodaySummary();
  }

  Future<Map<String, dynamic>?> loadMenuFromFirestore(String date) async {
    return await _service.loadMenuFromFirestore(date);
  }

  Future<Map<String, List<Map<String, dynamic>>>> buildFullMenu(
    Map<String, dynamic> aiMenu,
  ) async {
    return await _service.buildFullMenu(aiMenu);
  }
}
