import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/User.dart';
import 'BaseService.dart';

class UserService extends BaseService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Tạo hồ sơ người dùng mới với Soft Delete fields
  Future<void> createUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    final userData = {
      ...data,
      'userId': uid,  // Thêm userId để dễ query
      'status': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'originalCreatedAt': FieldValue.serverTimestamp(),
      'updatedAt': null,
    };
    
    await _db.collection('users').doc(uid).set(userData);
  }

  /// Lấy dữ liệu người dùng đang đăng nhập (chỉ active - status = 1)
  /// Query tất cả documents có userId = user.uid, lấy cái mới nhất có status = 1
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Query đơn giản: chỉ userId, không cần composite index
      final snapshot = await _db
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) return null;
      
      // Filter status=1 và sort trong code
      final activeDocs = snapshot.docs
          .where((doc) => doc['status'] == 1)
          .toList();
      
      if (activeDocs.isEmpty) return null;
      
      // Sort by createdAt descending
      activeDocs.sort((a, b) {
        final createdAtA = a['createdAt'] as Timestamp?;
        final createdAtB = b['createdAt'] as Timestamp?;
        if (createdAtA == null || createdAtB == null) return 0;
        return createdAtB.compareTo(createdAtA);
      });
      
      return activeDocs.first.data();
    } catch (e) {
      print('Error querying userId: $e');
      // Fallback: nếu không có userId field, query document cũ
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data?['status'] != 1) return null;
      
      return data;
    }
  }

  /// Cập nhật hồ sơ: tạo document mới, set cũ status = 0
  /// Thêm userId field để dễ query document active
  Future<void> updateUser({
    required String name,
    required int age,
    required double weight,
    required double height,
    required String gender,
    required String activity,
    required String goal,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User không tồn tại');

    // Lấy document cũ
    final oldDoc = await _db.collection('users').doc(user.uid).get();
    if (!oldDoc.exists) throw Exception('User profile không tồn tại');

    // Giữ các field cũ, update field mới
    final oldData = oldDoc.data() ?? {};
    final newData = {
      ...oldData,
      'userId': user.uid,  // Thêm userId để dễ query
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'activity': activity,
      'goal': goal,
    };

    // Set document cũ: status = 0
    await _db.collection('users').doc(user.uid).update({
      'status': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Tạo document mới với ID mới
    final newDocId = _db.collection('users').doc().id;
    newData['status'] = 1;
    newData['createdAt'] = FieldValue.serverTimestamp();
    // Giữ lại originalCreatedAt từ document cũ, không ghi đè
    newData['originalCreatedAt'] = oldData['originalCreatedAt'] ?? FieldValue.serverTimestamp();
    newData['updatedAt'] = null;
    
    await _db.collection('users').doc(newDocId).set(newData);
  }

  /// Cập nhật vai trò người dùng
  Future<void> updateUserRole({
    required String uid,
    required String role,
  }) async {
    // Set document cũ: status = 0
    await _db.collection('users').doc(uid).update({
      'status': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // Tạo document mới
    final oldDoc = await _db.collection('users').doc(uid).get();
    if (!oldDoc.exists) throw Exception('User không tồn tại');

    final oldData = oldDoc.data() ?? {};
    final newDocId = _db.collection('users').doc().id;
    
    final newData = {
      ...oldData,
      'userId': uid,  // Đảm bảo userId luôn có
      'role': role,
      'status': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'originalCreatedAt': oldData['originalCreatedAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': null,
    };
    
    await _db.collection('users').doc(newDocId).set(newData);
  }

  /// Upload avatar
  Future<String?> uploadAvatar(File file) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User không tồn tại');

    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/dhfjendel/image/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = 'smartmeal_avatar'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final data = jsonDecode(resBody);
        final imageUrl = data['secure_url'];

        // Cập nhật avatar (Soft Delete style)
        await _db.collection('users').doc(user.uid).update({
          'status': 0,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Tạo document mới
        final oldDoc = await _db.collection('users').doc(user.uid).get();
        final oldData = oldDoc.data() ?? {};
        final newDocId = _db.collection('users').doc().id;
        
        final newData = {
          ...oldData,
          'userId': user.uid,  // Đảm bảo userId luôn có
          'avatar': imageUrl,
          'status': 1,
          'createdAt': FieldValue.serverTimestamp(),
          'originalCreatedAt': oldData['originalCreatedAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': null,
        };
        
        await _db.collection('users').doc(newDocId).set(newData);
        return imageUrl;
      } else {
        throw Exception('Upload thất bại');
      }
    } catch (e) {
      throw Exception('Không thể đổi avatar: $e');
    }
  }

  /// Lấy hồ sơ người dùng đầy đủ (chỉ active - status = 1)
  /// Query document mới nhất có userId = user.uid và status = 1
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      // Query đơn giản: chỉ userId, không cần composite index
      final snapshot = await _db
          .collection('users')
          .where('userId', isEqualTo: user.uid)
          .get();

      if (snapshot.docs.isEmpty) return null;
      
      // Filter status=1 và sort trong code
      final activeDocs = snapshot.docs
          .where((doc) => doc['status'] == 1)
          .toList();
      
      if (activeDocs.isEmpty) return null;
      
      // Sort by createdAt descending
      activeDocs.sort((a, b) {
        final createdAtA = a['createdAt'] as Timestamp?;
        final createdAtB = b['createdAt'] as Timestamp?;
        if (createdAtA == null || createdAtB == null) return 0;
        return createdAtB.compareTo(createdAtA);
      });
      
      return activeDocs.first.data();
    } catch (e) {
      print('Error querying userId: $e');
      // Fallback: nếu không có userId field, query document cũ
      final doc = await _db.collection('users').doc(user.uid).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data?['status'] != 1) return null;
      
      return data;
    }
  }

  /// Đăng xuất
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Lấy toàn bộ người dùng active
  Future<List<User>> getAllUsers() async {
    final snapshot = await _db
        .collection('users')
        .where('status', isEqualTo: 1)
        .get();

    return snapshot.docs
        .map((e) => User.fromMap(e.data() as Map<String, dynamic>, e.id))
        .toList();
  }

  /// Thống kê người dùng theo tuần/tháng/năm (chỉ active)
  Future<Map<String, dynamic>> getUserStats({
    required String type,
    required int month,
    required int year,
  }) async {
    final snapshot = await _db
        .collection('users')
        .where('status', isEqualTo: 1)
        .get();

    final Map<String, int> counts = {};
    final Map<String, String> ranges = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      
      // Sử dụng originalCreatedAt để lấy ngày đăng ký ban đầu
      final timestamp = (data['originalCreatedAt'] ?? data['createdAt']) as Timestamp?;
      if (timestamp == null) continue;

      final DateTime date = timestamp.toDate();

      if (type == 'week') {
        if (date.month != month || date.year != year) continue;

        final int week = ((date.day - 1) ~/ 7) + 1;
        final int start = (week - 1) * 7 + 1;
        int end = week * 7;

        final int lastDay = DateTime(year, month + 1, 0).day;
        if (end > lastDay) end = lastDay;

        final String key = 'Tuần $week\n($start-$end)';
        counts[key] = (counts[key] ?? 0) + 1;
        ranges[key] = '$start-$end/$month';
      }

      if (type == 'month') {
        if (date.year != year) continue;

        final String key = 'Tháng ${date.month}';
        counts[key] = (counts[key] ?? 0) + 1;
        ranges[key] = 'Tháng ${date.month}/$year';
      }

      if (type == 'year') {
        final String key = 'Năm ${date.year}';
        counts[key] = (counts[key] ?? 0) + 1;
        ranges[key] = 'Năm ${date.year}';
      }
    }

    return {
      'counts': counts,
      'ranges': ranges,
    };
  }

  /// Lọc người dùng theo khoảng thời gian (chỉ active)
  Future<List<User>> getUsersByTime({
    required String type,
    required int month,
    required int year,
  }) async {
    final snapshot = await _db
        .collection('users')
        .where('status', isEqualTo: 1)
        .get();
    
    final List<User> result = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      // Sử dụng originalCreatedAt để lấy ngày đăng ký ban đầu
      final timestamp = (data['originalCreatedAt'] ?? data['createdAt']) as Timestamp?;
      if (timestamp == null) continue;

      final DateTime date = timestamp.toDate();
      bool match = false;

      if (type == 'week') {
        match = date.month == month && date.year == year;
      } else if (type == 'month') {
        match = date.year == year;
      } else if (type == 'year') {
        match = true;
      }

      if (match) {
        result.add(User.fromMap(data, doc.id));
      }
    }

    return result;
  }

  /// Thống kê người dùng theo ngày (chỉ active)
  Future<Map<String, dynamic>> getUserStatsByDay({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _db
        .collection('users')
        .where('status', isEqualTo: 1)
        .get();

    final Map<String, int> counts = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      // Sử dụng originalCreatedAt để lấy ngày đăng ký ban đầu
      final timestamp = (data['originalCreatedAt'] ?? data['createdAt']) as Timestamp?;
      if (timestamp == null) continue;

      final DateTime date = timestamp.toDate();
      final onlyDate = DateTime(date.year, date.month, date.day);
      final start = DateTime(startDate.year, startDate.month, startDate.day);
      final end = DateTime(endDate.year, endDate.month, endDate.day);

      if ((onlyDate.isAtSameMomentAs(start) || onlyDate.isAfter(start)) &&
          (onlyDate.isAtSameMomentAs(end) || onlyDate.isBefore(end))) {
        final String key = '${date.day}/${date.month}';
        counts[key] = (counts[key] ?? 0) + 1;
      }
    }

    // Đảm bảo mỗi ngày có dữ liệu
    DateTime current = startDate;
    while (!current.isAfter(endDate)) {
      final String key = '${current.day}/${current.month}';
      if (!counts.containsKey(key)) counts[key] = 0;
      current = current.add(const Duration(days: 1));
    }

    // Sắp xếp theo ngày
    final sortedKeys = counts.keys.toList()
      ..sort((a, b) {
        final aParts = a.split('/').map(int.parse).toList();
        final bParts = b.split('/').map(int.parse).toList();
        if (aParts[1] != bParts[1]) return aParts[1].compareTo(bParts[1]);
        return aParts[0].compareTo(bParts[0]);
      });

    final sortedCounts = <String, int>{};
    for (final key in sortedKeys) {
      sortedCounts[key] = counts[key]!;
    }

    return {
      'counts': sortedCounts,
      'ranges': <String, String>{},
    };
  }

  /// Soft delete người dùng
  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).update({
      'status': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
