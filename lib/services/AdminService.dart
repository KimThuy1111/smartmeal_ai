import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'BaseService.dart';

class AdminService extends BaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Lấy thống kê (chỉ active)
  Future<Map<String, int>> loadStats() async {
    final foodSnap = await _db
        .collection('food')
        .where('status', isEqualTo: 1)
        .get();
    final userSnap = await _db
        .collection('users')
        .where('status', isEqualTo: 1)
        .get();
    final categorySnap = await _db
        .collection('food_category')
        .where('status', isEqualTo: 1)
        .get();

    return {
      'totalFoods': foodSnap.docs.length,
      'totalUsers': userSnap.docs.length,
      'totalCategories': categorySnap.docs.length,
    };
  }

  /// Lấy thông tin hồ sơ admin (chỉ active)
  Future<Map<String, dynamic>?> getAdminProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      return null;
    }

    final doc = await _db.collection('users').doc(user.uid).get();
    final data = doc.data();
    
    if (data?['status'] != 1) {
      return null;
    }

    return data;
  }
}
