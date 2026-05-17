import '../services/AuthService.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthController {
  final AuthService _service = AuthService();

  // Đăng ký tài khoản
  Future<Map<String, dynamic>> register({required String email, required String password,}) async {
    // 4.2. Hệ thống gọi phương thức đăng ký của AuthService
    final result = await _service.register(email: email, password: password);
    return result;
  }

  // Đăng nhập bằng email và mật khẩu
  Future<Map<String, dynamic>> login({required String email, required String password,}) async {
    final result = await _service.login(email: email, password: password,);
    DocumentSnapshot doc = result["doc"];
    if (!doc.exists) {
      throw Exception("User chưa có profile");
    }
    return result;
  }

  //Đăng nhập gg
  Future<Map<String, dynamic>?> loginWithGoogle() async {
    final result = await _service.loginWithGoogle();
    if (result == null) return null;
    // 6. Hệ thống kiểm tra hồ sơ người dùng
    DocumentSnapshot doc = result["doc"];
    if (!doc.exists) {
      User user = result["user"];
      await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .set({
        "name": user.displayName ?? "",
        "email": user.email ?? "",
        "createdAt": FieldValue.serverTimestamp(),
      });
    }
    return result;
  }
  // Gửi yêu cầu đặt lại mật khẩu
  Future<void> resetPassword(String email) async {
    await _service.resetPassword(email);
  }

  // Đổi mật khẩu
  Future<void> changePassword({
    required String currentPass,
    required String newPass,
  }) async {

    if (newPass.length < 6) {
      throw Exception("Mật khẩu phải >= 6 ký tự");
    }

    await _service.changePassword(
      currentPass: currentPass,
      newPass: newPass,
    );
  }
}