import '../services/MenuFeedbackService.dart';

class MenuFeedbackController {
  final MenuFeedbackService _service = MenuFeedbackService();
  
  /// Tải danh sách thực đơn và số lượt đánh giá
  Future<Map<String, dynamic>> loadMenus() async {

    final data = await _service.loadMenus();

    return {
      "menus": data["menus"] ?? [],
      "likeCount": data["likeCount"] ?? 0,
      "dislikeCount": data["dislikeCount"] ?? 0,
      "notRatedCount": data["notRatedCount"] ?? 0,
    };
  }
}