import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Tải thống kê tổng số món ăn, phân loại và người dùng.
  Future<Map<String, int>> loadStats() async {
    final foodSnap = await _db.collection('food').get();
    final userSnap = await _db.collection('users').get();
    final categorySnap = await _db.collection('food_category').get();

    return {
      'totalFoods': foodSnap.docs.length,
      'totalUsers': userSnap.docs.length,
      'totalCategories': categorySnap.docs.length,
    };
  }

  // Lấy thông tin hồ sơ của tài khoản admin đang đăng nhập.
  Future<Map<String, dynamic>?> getAdminProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final doc = await _db.collection('users').doc(user.uid).get();

    return doc.data();
  }
}