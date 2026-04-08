import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class to initialize default food categories in Firestore
class CategoryInitializer {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = "food_category";

  /// Default categories list
  static const List<String> defaultCategories = [
    "Tinh bột",
    "Món nước",
    "Bánh",
    "Giải khát",
    "Khác",
    "Hải sản",
    "Trứng & Sữa",
    "Đồ ăn nhanh",
    "Trái cây",
  ];

  /// Initialize default categories if they don't exist
  static Future<void> initializeCategories() async {
    try {
      final snapshot = await _db.collection(_collection).get();
      final existingNames = <String>{};

      for (var doc in snapshot.docs) {
        final name = doc['name'] as String?;
        if (name != null) {
          existingNames.add(name);
        }
      }

      // Add missing categories
      int added = 0;
      for (final name in defaultCategories) {
        if (!existingNames.contains(name)) {
          await _db.collection(_collection).add({"name": name});
          added++;
        }
      }

      if (added > 0) {
        print("✓ Added $added new categories");
      } else if (snapshot.docs.isEmpty) {
        print("✓ Categories initialized successfully");
      } else {
        print("✓ All categories already exist");
      }
    } catch (e) {
      print("✗ Error initializing categories: $e");
    }
  }

  /// Get category ID by name
  static Future<String?> getCategoryIdByName(String name) async {
    try {
      final snapshot = await _db
          .collection(_collection)
          .where('name', isEqualTo: name)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.first.id;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Get all categories as a map of ID -> Name
  static Future<Map<String, String>> getCategoriesMap() async {
    try {
      final snapshot =
          await _db.collection(_collection).orderBy("name").get();

      final Map<String, String> map = {};
      for (var doc in snapshot.docs) {
        map[doc.id] = doc["name"] ?? "";
      }

      return map;
    } catch (_) {
      return {};
    }
  }
}
