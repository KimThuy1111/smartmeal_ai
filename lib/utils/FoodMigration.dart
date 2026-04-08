import 'package:cloud_firestore/cloud_firestore.dart';

/// Utility class to migrate existing food records from category string to categoryId
class FoodMigration {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _foodCollection = "food";
  static const String _categoryCollection = "food_category";

  /// Migrate all existing food records to use categoryId instead of category name
  /// This should be run once after updating the Food model
  static Future<void> migrateToCategory() async {
    try {
      print("Starting food category migration...");

      // Get all categories map
      final categoryMap = await _getCategoryNameToIdMap();

      if (categoryMap.isEmpty) {
        print("No categories found, skipping migration");
        return;
      }

      // Get all foods with category field
      final foodSnapshot = await _db.collection(_foodCollection).get();

      int migrated = 0;
      int failed = 0;

      for (var doc in foodSnapshot.docs) {
        try {
          final data = doc.data();
          final category = data['category'];

          // If already has categoryId, skip
          if (data.containsKey('categoryId') && data['categoryId'] != null) {
            continue;
          }

          // If has category name, migrate to categoryId
          if (category != null && category is String && category.isNotEmpty) {
            final categoryId = categoryMap[category];

            if (categoryId != null) {
              await _db
                  .collection(_foodCollection)
                  .doc(doc.id)
                  .update({
                'categoryId': categoryId,
              });
              migrated++;
              print("✓ Migrated: $category -> $categoryId");
            } else {
              print("⚠ Category not found: $category (food: ${doc.id})");
              failed++;
            }
          }
        } catch (e) {
          print("✗ Error migrating food ${doc.id}: $e");
          failed++;
        }
      }

      print("✓ Migration completed: $migrated migrated, $failed failed");
    } catch (e) {
      print("✗ Error during migration: $e");
    }
  }

  /// Get category name to ID mapping
  static Future<Map<String, String>> _getCategoryNameToIdMap() async {
    try {
      final snapshot = await _db.collection(_categoryCollection).get();

      final Map<String, String> map = {};
      for (var doc in snapshot.docs) {
        final name = doc['name'] as String?;
        if (name != null && name.isNotEmpty) {
          map[name] = doc.id;
        }
      }

      return map;
    } catch (_) {
      return {};
    }
  }
}
