import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/User.dart';

class UserService {
  final auth.FirebaseAuth _auth = auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Tạo hồ sơ người dùng trong Firestore với document id là uid.
  Future<void> createUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _db.collection('users').doc(uid).set(data);
  }

  // Lấy dữ liệu người dùng đang đăng nhập.
  Future<Map<String, dynamic>?> getUserData() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final doc = await _db.collection('users').doc(user.uid).get();
    return doc.data();
  }

  // Cập nhật thông tin hồ sơ cơ bản của người dùng hiện tại.
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
    if (user == null) {
      throw Exception('User not found');
    }

    await _db.collection('users').doc(user.uid).update({
      'name': name,
      'age': age,
      'weight': weight,
      'height': height,
      'gender': gender,
      'activity': activity,
      'goal': goal,
    });
  }

  // Cập nhật vai trò của một người dùng theo uid.
  Future<void> updateUserRole({
    required String uid,
    required String role,
  }) async {
    await _db.collection('users').doc(uid).update({'role': role});
  }

  // Tải avatar lên Firebase Storage, lưu URL vào hồ sơ và trả về URL mới.

Future<String?> uploadAvatar(File file) async {
  final user = _auth.currentUser;
  if (user == null) {
    throw Exception('User not found');
  }

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

      // lưu vào firestore
      await _db.collection('users').doc(user.uid).set({
        'avatar': imageUrl,
      }, SetOptions(merge: true));

      return imageUrl;
    } else {
      throw Exception('Upload thất bại');
    }
  } catch (e) {
    throw Exception('Không thể đổi avatar: $e');
  }
}
  // Lấy thông tin hồ sơ đầy đủ của người dùng hiện tại.
  Future<Map<String, dynamic>?> getUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) {
      return null;
    }

    return doc.data();
  }

  // Đăng xuất tài khoản hiện tại.
  Future<void> logout() async {
    await _auth.signOut();
  }

  // Lấy toàn bộ danh sách người dùng từ hệ thống.
  Future<List<User>> getAllUsers() async {
    final snapshot = await _db.collection('users').get();

    return snapshot.docs
        .map((e) => User.fromMap(e.data() as Map<String, dynamic>, e.id))
        .toList();
  }

  // Thống kê số lượng người dùng theo tuần/tháng/năm.
  Future<Map<String, dynamic>> getUserStats({
    required String type,
    required int month,
    required int year,
  }) async {
    final snapshot = await _db.collection('users').get();

    final Map<String, int> counts = {};
    final Map<String, String> ranges = {};

    for (final doc in snapshot.docs) {
      final data = doc.data();
      // Bỏ qua bản ghi chưa có thời gian tạo để tránh lỗi ép kiểu Timestamp.
      if (data['createdAt'] == null) {
        continue;
      }

      final DateTime date = (data['createdAt'] as Timestamp).toDate();

      if (type == 'week') {
        if (date.month != month || date.year != year) {
          continue;
        }

        final int week = ((date.day - 1) ~/ 7) + 1;
        final String key = 'Tuần $week';

        counts[key] = (counts[key] ?? 0) + 1;

        final int start = (week - 1) * 7 + 1;
        int end = week * 7;

        final int lastDay = DateTime(year, month + 1, 0).day;
        if (end > lastDay) {
          end = lastDay;
        }

        ranges[key] = '$start-$end/$month';
      }

      if (type == 'month') {
        if (date.year != year) {
          continue;
        }

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

  // Lọc danh sách người dùng theo mốc thời gian tuần/tháng/năm.
  Future<List<User>> getUsersByTime({
    required String type,
    required int month,
    required int year,
  }) async {
    final snapshot = await _db.collection('users').get();
    final List<User> result = [];

    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data['createdAt'] == null) {
        continue;
      }

      final DateTime date = (data['createdAt'] as Timestamp).toDate();
      bool match = false;

      if (type == 'week') {
        match = date.month == month && date.year == year;
      }

      if (type == 'month') {
        match = date.year == year;
      }

      if (type == 'year') {
        match = true;
      }

      if (match) {
        result.add(User.fromMap(data, doc.id));
      }
    }

    return result;
  }
}