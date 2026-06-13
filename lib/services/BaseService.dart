import 'package:cloud_firestore/cloud_firestore.dart';

/// Base service cung cấp helper method cho Soft Delete và Data Versioning
class BaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Tạo document mới với status = 1 và createdAt
  Future<void> createDocument({
    required String collection,
    required String docId,
    required Map<String, dynamic> data,
  }) async {
    final docData = {
      ...data,
      'status': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    };
    
    await _db.collection(collection).doc(docId).set(docData);
  }

  /// Soft delete: set status = 0 và updatedAt = now
  Future<void> softDeleteDocument({
    required String collection,
    required String docId,
  }) async {
    await _db.collection(collection).doc(docId).update({
      'status': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update document: cũ set status = 0, tạo mới với status = 1
  Future<String> updateDocumentWithVersioning({
    required String collection,
    required String oldDocId,
    required Map<String, dynamic> newData,
  }) async {
    // Cập nhật document cũ: status = 0, updatedAt = now
    await _db.collection(collection).doc(oldDocId).update({
      'status': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Tạo document mới với ID mới
    final newDocId = _db.collection(collection).doc().id;
    final newDocData = {
      ...newData,
      'status': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    };
    
    await _db.collection(collection).doc(newDocId).set(newDocData);
    
    return newDocId;
  }

  /// Lấy danh sách document chỉ có status = 1 (đang hoạt động)
  Future<List<Map<String, dynamic>>> getActiveDocuments({
    required String collection,
  }) async {
    final snapshot = await _db
        .collection(collection)
        .where('status', isEqualTo: 1)
        .get();
    
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Query với điều kiện status = 1
  Query getActiveQuery(String collection) {
    return _db.collection(collection).where('status', isEqualTo: 1);
  }

  /// Lấy single document active
  Future<Map<String, dynamic>?> getActiveDocument({
    required String collection,
    required String docId,
  }) async {
    final doc = await _db.collection(collection).doc(docId).get();
    
    if (!doc.exists) return null;
    
    final data = doc.data();
    if (data?['status'] != 1) return null;
    
    return data;
  }
}
