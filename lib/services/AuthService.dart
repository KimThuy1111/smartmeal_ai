import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:smartmeal_ai/models/Role.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Đăng ký tài khoản mới bằng email/mật khẩu và tạo bản ghi người dùng cơ bản.
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
  }) async {
    // 4.3. Hệ thống gửi yêu cầu tạo tài khoản trên Firebase Auth
    final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final String uid = userCredential.user!.uid;
    // 4.4. Hệ thống tạo dữ liệu người dùng ban đầu trên Firestore
    await _db.collection('users').doc(uid).set({
      'email': email,
      'role': Role.user,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return {
      'uid': uid,
      'user': userCredential.user,
    };
  }

  // Đăng nhập bằng email/mật khẩu và lấy thông tin hồ sơ người dùng từ Firestore.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    // 4. Hệ thống thực hiện xác thực thông tin đăng nhập
    final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    final String uid = userCredential.user!.uid;
    final DocumentSnapshot doc = await _db.collection('users').doc(uid).get();

    return {
      'uid': uid,
      'user': userCredential.user,
      'doc': doc,
    };
  }

  // Đăng nhập bằng Google và trả về dữ liệu người dùng tương ứng trong Firestore.
  Future<Map<String, dynamic>?> loginWithGoogle() async {
    // 2. Hệ thống gửi yêu cầu đăng nhập Google
    // 3. Người dùng chọn tài khoản Google và cấp quyền truy cập
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      return null;
    }

    // 4. Hệ thống nhận thông tin xác thực từ Google
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // 5. Hệ thống xác thực thông tin đăng nhập
    final UserCredential userCredential = await _auth.signInWithCredential(credential);
    final User user = userCredential.user!;
    final String uid = user.uid;
    final userRef = _db.collection('users').doc(uid);
    // 6. Hệ thống kiểm tra hồ sơ người dùng
    final DocumentSnapshot doc = await userRef.get();

    if (!doc.exists) {
      await userRef.set({
        'email': user.email,
        'role': Role.user,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      final data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('role')) {
        await userRef.set({'role': Role.user}, SetOptions(merge: true));
      }
    }

    return {
      'uid': uid,
      'user': user,
      'doc': await userRef.get(),
    };
  }

  // Gửi email đặt lại mật khẩu cho tài khoản đã nhập.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Đổi mật khẩu sau khi xác thực lại bằng mật khẩu hiện tại.
  Future<void> changePassword({
    required String currentPass,
    required String newPass,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'User chưa đăng nhập',
      );
    }

    final String email = user.email!;

    final AuthCredential credential = EmailAuthProvider.credential(
      email: email,
      password: currentPass,
    );

    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPass);
  }
}