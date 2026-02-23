import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/Food.dart';

class FoodRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Lấy random top foods
  Future<List<Food>> getTopFoods(int limit) async {
    final snapshot = await _db.collection('food').get();

    List<Food> list = snapshot.docs
        .map((doc) => Food.fromMap(doc.data(), doc.id)) // ✅ sửa ở đây
        .toList();

    list.shuffle();

    if (list.length > limit) {
      list = list.sublist(0, limit);
    }

    return list;
  }

  // Search local filter
  Future<List<Food>> searchFood(String keyword) async {
    final snapshot = await _db.collection('food').get();

    return snapshot.docs
        .map((doc) => Food.fromMap(doc.data(), doc.id)) // ✅ sửa ở đây
        .where((f) =>
        f.name.toLowerCase().contains(keyword.toLowerCase()))
        .toList();
  }
}