import '../services/HomeService.dart';

class HomeController {

  final HomeService _service = HomeService();

  /// Tải dữ liệu trang chủ
  Future<Map<String, dynamic>> loadHomeData() async {

    final userData = await _service.loadUserData();
    final mealData = await _service.loadTodayMeals();

    return {

      "name": userData["name"] ?? "",
      "goal": userData["goal"] ?? "",
      "calories": userData["calories"] ?? 0,
      "protein": userData["protein"] ?? 0,
      "carb": userData["carb"] ?? 0,
      "fat": userData["fat"] ?? 0,

      "breakfastFoods": mealData["breakfastFoods"] ?? [],
      "lunchFoods": mealData["lunchFoods"] ?? [],
      "dinnerFoods": mealData["dinnerFoods"] ?? [],

      "breakfastCal": mealData["breakfastCal"] ?? 0,
      "lunchCal": mealData["lunchCal"] ?? 0,
      "dinnerCal": mealData["dinnerCal"] ?? 0,

      "eatenProtein": mealData["eatenProtein"] ?? 0,
      "eatencarb": mealData["eatencarb"] ?? 0,
      "eatenFat": mealData["eatenFat"] ?? 0,
    };
  }
}