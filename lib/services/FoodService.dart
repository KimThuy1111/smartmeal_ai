import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../models/Food.dart';

class FoodService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final Map<String, List<Food>> _searchCache = {};
  List<Food>? _lastSearchResult;

  /// 2a.3 Lấy danh sách món ăn nổi bật/gợi ý ban đầu
  /// Ưu tiên sử dụng kết quả tìm kiếm trước đó, nếu không có thì lấy từ Firestore
  Future<List<Food>> getTopFoods(int limit) async {
    try {
      // Kiểm tra xem có kết quả tìm kiếm lần trước không để sử dụng lại
      if (_lastSearchResult != null && _lastSearchResult!.isNotEmpty) {
        return _lastSearchResult!.take(limit).toList();
      }

      // Truy vấn dữ liệu từ Firestore
      final snapshot = await _db.collection('food').limit(limit).get();
      // Chuyển đổi dữ liệu từ Firestore sang model Food
      final List<Food> list = snapshot.docs
          .map((doc) => Food.fromMap(doc.data(), doc.id))
          .toList();

      // Trộn ngẫu nhiên danh sách để hiển thị đa dạng
      list.shuffle();
      return list.take(limit).toList();
    } catch (e) {
      print('Lỗi: $e');
      return [];
    }
  }

  /// 3.3 Tìm kiếm món ăn theo từ khóa
  /// Sử dụng cache để tăng tốc độ, tìm kiếm theo tiền tố tên món
  Future<List<Food>> searchFood(String keyword) async {
    try {
      final value = keyword.trim();
      // Kiểm tra từ khóa có hợp lệ không
      if (value.isEmpty) {
        return [];
      }

      // Kiểm tra bộ nhớ cache xem từ khóa này đã được tìm kiếm trước đó chưa
      if (_searchCache.containsKey(value)) {
        return _searchCache[value]!;
      }

      // Truy vấn Firestore tìm kiếm theo tiền tố của từ khóa
      final snapshot = await _db
          .collection('food')
          .orderBy('name')
          .startAt([value])
          .endAt(['$value\uf8ff'])
          .limit(10)
          .get();

      // Chuyển đổi kết quả từ Firestore thành danh sách đối tượng Food
      final result = snapshot.docs
          .map((doc) => Food.fromMap(doc.data(), doc.id))
          .toList();

      // Lưu kết quả vào cache để tìm kiếm nhanh hơn lần sau
      _searchCache[value] = result;
      _lastSearchResult = result;

      return result;
    } catch (e) {
      print('Error searchFood: $e');
      return [];
    }
  }

  /// 5.5 Lấy thông tin chi tiết một món ăn theo ID
  /// Truy vấn Firestore lấy tài liệu theo ID
  Future<Food?> getFoodById(String foodId) async {
    // Truy vấn Firestore lấy tài liệu theo ID
    final doc = await _db.collection('food').doc(foodId).get();
    // Kiểm tra xem tài liệu có tồn tại không
    if (!doc.exists) {
      return null;
    }

    // Chuyển đổi dữ liệu từ Firestore sang model Food
    return Food.fromMap(doc.data()!, doc.id);
  }

  /// 4.3 Thêm món ăn vào nhật ký theo bữa của người dùng
  /// Lưu thông tin: userId, foodId, meal (breakfast/lunch/dinner), ngày, thời gian
  Future<void> addFoodToDiary({
    required String foodId,
    required String meal,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('User chưa đăng nhập');
    }

    await _db.collection('food_diary').add({
      'userId': user.uid,
      'foodId': foodId,
      'meal': meal,
      'date': DateTime.now().toString().substring(0, 10),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Tải ảnh món ăn lên Cloudinary và trả về URL công khai
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
      throw Exception('Không thể upload ảnh món ăn: $e');
    }
  }

  /// Thêm một món ăn mới vào Firestore
  Future<void> addFood(Map<String, dynamic> data) async {
    await _db.collection('food').add(data);
  }

  /// Cập nhật thông tin món ăn theo ID
  Future<void> updateFood(String id, Map<String, dynamic> data) async {
    await _db.collection('food').doc(id).update(data);
  }

  // Truy vấn toàn bộ danh sách món ăn từ Firestore
  // Lấy toàn bộ danh sách món ăn từ Firestore.
  Future<List<Food>> getAllFoods() async {
    // Truy vấn tất cả tài liệu trong collection food
    final snapshot = await _db.collection('food').get();

    // Chuyển đổi tất cả dữ liệu sang danh sách đối tượng Food
    return snapshot.docs.map((e) => Food.fromMap(e.data(), e.id)).toList();
  }

  // Xóa món ăn theo id.
  Future<void> deleteFood(String id) async {
    await _db.collection('food').doc(id).delete();
  }

  // Truy vấn chi tiết món ăn theo danh sách id cho từng bữa trong menu
  // Lấy thông tin chi tiết món ăn theo danh sách id cho từng bữa trong menu.
  Future<Map<String, List<Map<String, dynamic>>>> getFoodsByMenu(
    Map<String, List<String>> menu,
  ) async {
    final Map<String, List<Map<String, dynamic>>> result = {};

    // Duyệt qua từng bữa ăn trong menu
    for (final String meal in menu.keys) {
      final List<Map<String, dynamic>> list = [];

      // Truy vấn chi tiết cho từng ID món ăn trong bữa đó
      for (final String id in menu[meal]!) {
        final doc = await _db.collection('food').doc(id).get();

        // Kiểm tra xem tài liệu tồn tại rồi thêm vào danh sách
        if (doc.exists) {
          final data = doc.data()!;
          data['id'] = doc.id;
          list.add(data);
        }
      }

      result[meal] = list;
    }

    return result;
  }

  // Chạy kiểm thử đồng thời cho tìm kiếm để đo hiệu năng và tỷ lệ lỗi.
  Future<void> testConcurrent({
    required String keyword,
    required int totalRequests,
  }) async {
    final List<int> times = [];
    int errorCount = 0;

    final startTotal = DateTime.now();

    await Future.wait(
      List.generate(totalRequests, (i) async {
        final start = DateTime.now();

        try {
          final result = await searchFood(keyword);

          if (result.isEmpty) {
            errorCount++;
          }

          final end = DateTime.now();
          times.add(end.difference(start).inMilliseconds);
        } catch (e) {
          errorCount++;
          times.add(0);
        }
      }),
    );

    final endTotal = DateTime.now();

    final int minTime = times.reduce((a, b) => a < b ? a : b);
    final int maxTime = times.reduce((a, b) => a > b ? a : b);
    final double avgTime = times.reduce((a, b) => a + b) / times.length;
    final double errorPercent = (errorCount / totalRequests) * 100;
    final double totalSeconds =
        endTotal.difference(startTotal).inMilliseconds / 1000;
    final double throughput = totalRequests / totalSeconds;

    print('=========== CONCURRENT RESULT ===========');
    print('Total Requests: $totalRequests');
    print('Avg: ${avgTime.toStringAsFixed(2)} ms');
    print('Min: $minTime ms');
    print('Max: $maxTime ms');
    print('Error: ${errorPercent.toStringAsFixed(2)}%');
    print('Throughput: ${throughput.toStringAsFixed(2)} req/s');
  }
}