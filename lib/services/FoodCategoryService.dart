import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/FoodCategory.dart';
import 'BaseService.dart';

class FoodCategoryService extends BaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = "food_category";

  /// Lấy tất cả danh mục (chỉ active)
  Future<List<FoodCategory>> getAllCategories() async {
    final snapshot = await _db
        .collection(_collection)
        .where('status', isEqualTo: 1)
        .get();

    return snapshot.docs
        .map((doc) => FoodCategory.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Thêm danh mục mới với status = 1
  Future<void> addCategory(Map<String, dynamic> data) async {
    final categoryData = {
      ...data,
      'status': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    };
    
    await _db.collection(_collection).add(categoryData);
  }

  /// Cập nhật danh mục: cũ set status = 0, tạo mới
  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    // Set cũ: status = 0
    await _db.collection(_collection).doc(id).update({
      'status': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Lấy dữ liệu cũ
    final oldDoc = await _db.collection(_collection).doc(id).get();
    if (!oldDoc.exists) throw Exception('Danh mục không tồn tại');

    // Tạo document mới
    final newData = {
      ...oldDoc.data() ?? {},
      ...data,
      'status': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    };
    
    await _db.collection(_collection).add(newData);
  }

  /// Soft delete: set status = 0
  Future<void> deleteCategory(String id) async {
    await _db.collection(_collection).doc(id).update({
      'status': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
