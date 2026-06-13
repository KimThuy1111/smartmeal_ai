import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/Food.dart';
import 'BaseService.dart';

class FoodService extends BaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, List<Food>> _searchCache = {};
  List<Food>? _lastSearchResult;

  // Lấy danh sách món ăn nổi bật
  Future<List<Food>> getTopFoods(int limit) async {
    try {
      if (_lastSearchResult != null && _lastSearchResult!.isNotEmpty) {
        return _lastSearchResult!.take(limit).toList();
      }

      // Query chỉ lấy status = 1
      final snapshot = await _db
          .collection('food')
          .where('status', isEqualTo: 1)
          .limit(limit)
          .get();

      final List<Food> list = snapshot.docs
          .map((doc) => Food.fromMap(doc.data(), doc.id))
          .toList();

      return list.toList();
    } catch (e) {
      print('Lỗi: $e');
      return [];
    }
  }

  // Tìm kiếm món ăn theo từ khóa
  Future<List<Food>> searchFood(String value) async {
    try {
      if (_searchCache.containsKey(value)) {
        return _searchCache[value]!;
      }
      // Query với điều kiện status = 1
      final snapshot = await _db
          .collection('food')
          .where('status', isEqualTo: 1)
          .orderBy('name')
          .startAt([value])
          .endAt(['$value\uf8ff'])
          .get();

      final result = snapshot.docs
          .map((doc) => Food.fromMap(doc.data(), doc.id))
          .toList();
      _searchCache[value] = result;
      _lastSearchResult = result;
      return result;
    } catch (e) {
      print('Lỗi tìm kiếm: $e');
      return [];
    }
  }

  // Lấy chi tiết món ăn theo ID
  Future<Food?> getFoodById(String foodId) async {
    final doc = await _db.collection('food').doc(foodId).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data?['status'] != 1) return null;

    return Food.fromMap(data!, doc.id);
  }

  // Thêm món ăn vào nhật ký
  Future<void> addFoodToDiary({required String foodId, required String meal}) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User chưa đăng nhập');

    await _db.collection('food_diary').add({
      'userId': user.uid,
      'foodId': foodId,
      'meal': meal,
      'date': DateTime.now().toString().substring(0, 10),
      'status': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    });
  }

  // Upload ảnh lên Cloudinary
  Future<String?> uploadImage(File file) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/dhfjendel/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'smartmeal_avatar'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(body) as Map<String, dynamic>;
        return data['secure_url'] as String?;
      }

      throw Exception('Upload thất bại (${response.statusCode}): $body');
    } catch (e) {
      throw Exception('Không thể upload ảnh: $e');
    }
  }

  // Thêm món ăn mới
  Future<void> addFood(Map<String, dynamic> data) async {
    final foodData = {
      ...data,
      'status': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    };
    
    await _db.collection('food').add(foodData);
  }

  // Cập nhật món ăn: cũ set status = 0, tạo mới
  Future<void> updateFood(String id, Map<String, dynamic> data) async {
    // Set cũ: status = 0
    await _db.collection('food').doc(id).update({
      'status': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Lấy dữ liệu cũ
    final oldDoc = await _db.collection('food').doc(id).get();
    if (!oldDoc.exists) throw Exception('Món ăn không tồn tại');

    // Tạo document mới
    final newData = {
      ...oldDoc.data() ?? {},
      ...data,
      'status': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    };
    
    await _db.collection('food').add(newData);
  }

  // Lấy tất cả món ăn
  Future<List<Food>> getAllFoods() async {
    final snapshot = await _db
        .collection('food')
        .where('status', isEqualTo: 1)
        .get();

    return snapshot.docs
        .map((e) => Food.fromMap(e.data(), e.id))
        .toList();
  }

  // Xóa món ăn
  Future<void> deleteFood(String id) async {
    await _db.collection('food').doc(id).update({
      'status': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Lấy chi tiết món ăn theo menu (chỉ active)
  Future<Map<String, List<Map<String, dynamic>>>> getFoodsByMenu(
    Map<String, List<String>> menu,
  ) async {
    final Map<String, List<Map<String, dynamic>>> result = {};

    for (final String meal in menu.keys) {
      final List<Map<String, dynamic>> list = [];

      for (final String id in menu[meal]!) {
        final doc = await _db.collection('food').doc(id).get();

        if (doc.exists) {
          final data = doc.data();
          // Chỉ lấy nếu status = 1
          if (data?['status'] == 1) {
            data!['id'] = doc.id;
            list.add(data);
          }
        }
      }

      result[meal] = list;
    }

    return result;
  }
}
