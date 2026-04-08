import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/FoodCategory.dart';

class FoodCategoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = "food_category";

  Future<List<FoodCategory>> getAllCategories() async {
    final snapshot = await _db.collection(_collection).orderBy("name").get();

    return snapshot.docs
        .map((doc) => FoodCategory.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> addCategory(Map<String, dynamic> data) async {
    await _db.collection(_collection).add(data);
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await _db.collection(_collection).doc(id).update(data);
  }

  Future<void> deleteCategory(String id) async {
    await _db.collection(_collection).doc(id).delete();
  }
}
