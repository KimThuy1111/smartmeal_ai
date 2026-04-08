import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/Food.dart';
import '../models/SuggestedMenu.dart';
import '../models/User.dart';

class MenuFeedbackService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Tải danh sách menu gợi ý và tổng hợp số lượt thích/không thích/chưa đánh giá.
  Future<Map<String, dynamic>> loadMenus() async {
    int likeCount = 0;
    int dislikeCount = 0;
    int notRatedCount = 0;

    final snap = await _db.collection('suggested_menus').get();

    final List<Map<String, dynamic>> result = [];

    for (var doc in snap.docs) {
      final suggested = SuggestedMenu.fromMap(doc.data());

      if (suggested.liked == true) {
        likeCount++;
      } else if (suggested.liked == false) {
        dislikeCount++;
      } else {
        notRatedCount++;
      }

      final userDoc = await _db.collection('users').doc(suggested.userId).get();

      if (!userDoc.exists) {
        continue;
      }

      final user = User.fromMap(userDoc.data()!, userDoc.id);

      final List<String> allFoodIds = [];

      suggested.menu.forEach((key, value) {
        allFoodIds.addAll(value);
      });

      final List<String> names = [];

      for (var id in allFoodIds) {
        final foodDoc = await _db.collection('food').doc(id).get();

        if (foodDoc.exists) {
          final food = Food.fromMap(
            foodDoc.data() as Map<String, dynamic>,
            foodDoc.id,
          );

          names.add(food.name);
        }
      }

      result.add({
        'user': user,
        'foods': names,
        'liked': suggested.liked,
        'menu': suggested.menu,
      });
    }

    return {
      'menus': result,
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'notRatedCount': notRatedCount,
    };
  }
}