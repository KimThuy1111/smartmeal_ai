import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/AuthController.dart';
import '../models/Role.dart';
import '../utils/notifier.dart';
import 'HomeScreen.dart';
import 'RegisterScreen.dart';
import 'RegisterStep2Screen.dart';
import 'admin/AdminDashboardScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthController _authController = AuthController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool showPass = true;

  Future<void> _login() async {
    // 3. Hệ thống kiểm tra dữ liệu.
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    
    if (email.isEmpty || password.isEmpty) {
      // 3a. Người dùng nhập thiếu thông tin, hiển thị thông báo vui lòng nhập đầy đủ thông tin.
      Notifier.showError(context, 'Vui lòng nhập đầy đủ thông tin!!!');
      return;
    }

    // 3b. Email không hợp lệ, hiển thị thông báo lỗi định dạng email.
    if (!_isValidEmail(email)) {
      Notifier.showError(context, 'Email không hợp lệ!!!');
      return;
    }

    try {
      setState(() => isLoading = true);

      // 4. Nếu dữ liệu hợp lệ, hệ thống thực hiện xác thực thông tin đăng nhập.
      final result = await _authController.login(
        email: email,
        password: password,
      );

      // Ghi chú kỹ thuật: xác thực thành công và nhận dữ liệu người dùng.
      final uid = result['uid'];

      // Ghi chú nghiệp vụ: kiểm tra vai trò và trạng thái hồ sơ để điều hướng đúng màn hình.
      final doc = result['doc'];

      final String role = doc['role'];

      // 5a. Tài khoản quản trị viên, điều hướng đến màn hình quản lý.
      if (role == Role.admin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        if (doc.exists) {
          // 5. Hệ thống điều hướng người dùng đến trang chủ.
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else {
          // 5b. Tài khoản người dùng chưa hoàn thiện hồ sơ, điều hướng đến màn hình nhập thông tin cá nhân.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RegisterStep2Screen(
                uid: uid,
                email: email,
                name: result['user'].displayName ?? '',
                avatar: 'https://cdn-icons-png.flaticon.com/512/149/149071.png',
              ),
            ),
          );
        }
      }

      // 6. Hệ thống thông báo đăng nhập thành công.
      Notifier.showNotify(context, 'Đăng nhập thành công!!!');
    } on FirebaseAuthException catch (e) {
      Notifier.showError(context, _mapFirebaseAuthError(e.code));
    } catch (_) {
      Notifier.showError(
        context,
        'Hệ thống đang bận, vui lòng thử lại sau!!!',
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  bool _isValidEmail(String email) {
    final RegExp emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'invalid-credential':
        // 4a. Nếu thông tin đăng nhập không đúng. Hệ thống hiển thị “Email không tồn tại hoặc sai mật khẩu!”
        return 'Email không tồn tại hoặc sai mật khẩu!';

      case 'user-disabled':
        // 4b. Nếu tài khoản bị vô hiệu hóa. Hệ thống hiển thị “Tài khoản đã bị vô hiệu hóa!”
        return 'Tài khoản đã bị vô hiệu hóa!';

      case 'too-many-requests':
        // 4c. Nếu người dùng thao tác quá nhiều lần. Hệ thống hiển thị “Bạn đã thử quá nhiều lần, vui lòng thử lại sau!”
        return 'Bạn đã thử quá nhiều lần, vui lòng thử lại sau!';

      case 'network-request-failed':
        // 4d. Nếu không có kết nối Internet. Hệ thống hiển thị “Lỗi kết nối mạng, vui lòng kiểm tra Internet!”
        return 'Lỗi kết nối mạng, vui lòng kiểm tra Internet!';

      case 'operation-not-allowed':
        // 4e. Nếu xảy ra các lỗi khác. Hệ thống hiển thị “Đăng nhập thất bại, vui lòng thử lại!”
        return 'Đăng nhập thất bại, vui lòng thử lại!';

      default:
        // 4e. Nếu xảy ra các lỗi khác. Hệ thống hiển thị “Đăng nhập thất bại, vui lòng thử lại!”
        return 'Đăng nhập thất bại, vui lòng thử lại!';
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() => isLoading = true);

      // 2. Hệ thống gửi yêu cầu đăng nhập Google
      final result = await _authController.loginWithGoogle();

      if (result == null) {
        // 4a. Nếu người dùng hủy thao tác hoặc đăng nhập Google thất bại, hệ thống hiển thị “Đăng nhập Google thất bại!”
        Notifier.showError(context, 'Đăng nhập Google thất bại!');
        return;
      }

      // 6. Hệ thống kiểm tra hồ sơ người dùng
      final doc = result['doc'];
      final user = result['user'];
      final uid = result['uid'];

      final String role = doc['role'];

      if (role == Role.admin) {
        // 8a. Nếu là tài khoản quản trị viên, hệ thống điều hướng đến trang quản trị.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
        );
      } else {
        if (doc.exists) {
          // 8. Hệ thống điều hướng người dùng đến trang chủ
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else {
          // 7b. Nếu là người dùng chưa hoàn thành hồ sơ, hệ thống điều hướng đến trang nhập thông tin cá nhân.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => RegisterStep2Screen(
                uid: uid,
                email: user.email ?? '',
                name: user.displayName ?? '',
                avatar:
                    user.photoURL ??
                    'https://cdn-icons-png.flaticon.com/512/149/149071.png',
              ),
            ),
          );
        }
      }

      // 7. Hệ thống thông báo đăng nhập thành công
      Notifier.showNotify(context, 'Đăng nhập thành công!');
    } catch (_) {
      // 5a. Nếu xác thực thông tin thất bại, hệ thống hiển thị “Đăng nhập thất bại, vui lòng thử lại!”
      // 6a. Nếu không lấy được hồ sơ người dùng, hệ thống hiển thị “Không thể lấy thông tin người dùng!”
      Notifier.showError(context, 'Đăng nhập thất bại, vui lòng thử lại!');
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Hiển thị hộp thoại nhập email để gửi link đặt lại mật khẩu.
  void _showEmailDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quên mật khẩu',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: 'Nhập email',
                  ),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () async {
                    final String email = emailController.text.trim();

                    if (email.isEmpty) {
                      Notifier.showError(context, 'Vui lòng nhập email');
                      return;
                    }

                    try {
                      await _authController.resetPassword(email);
                      Navigator.pop(context);
                      Notifier.showNotify(
                        context,
                        'Link đổi mật khẩu đã gửi vào email',
                      );
                    } catch (e) {
                      Notifier.showError(context, 'Email không tồn tại');
                    }
                  },
                  child: Container(
                    height: 45,
                    width: double.infinity,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.greenAccent,
                    ),
                    child: const Text('GỬI LINK'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE4FFE4), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Image.asset('assets/images/logo.png', height: 100),
                const SizedBox(height: 5),
                const Text(
                  'CALO',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'ĐĂNG NHẬP',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 30),
                // 1. Người dùng nhập email và mật khẩu
                _buildInputField(
                  controller: emailController,
                  hint: 'Nhập email',
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: passwordController,
                  hint: 'Nhập mật khẩu',
                  isPassword: true,
                ),
                const SizedBox(height: 10),
                if (isLoading) const CircularProgressIndicator(),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _showEmailDialog,
                    child: const Text(
                      'Quên mật khẩu ?',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  // 2. Người dùng chọn "Đăng nhập"
                  onTap: _login,
                  child: _buildButton('ĐĂNG NHẬP'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Bạn chưa có tài khoản? '),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        'Đăng ký',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('---------- HOẶC ----------'),
                const SizedBox(height: 10),
                GestureDetector(
                  // 1. Người dùng chọn biểu tượng đăng nhập bằng Google
                  onTap: _signInWithGoogle,
                  child: _buildSocialIcon('assets/images/ic_google.png'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Tạo nút chính dùng cho thao tác đăng nhập.
  Widget _buildButton(String text) {
    return Container(
      height: 50,
      width: double.infinity,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFF79EEF2), Color(0xFF78F09C)],
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Tạo ô nhập liệu, hỗ trợ ẩn/hiện mật khẩu khi là trường password.
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? showPass : false,
        decoration: InputDecoration(
          hintText: hint,
          border: InputBorder.none,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    showPass ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      showPass = !showPass;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }

  // Hiển thị icon mạng xã hội dùng cho đăng nhập bên thứ ba.
  Widget _buildSocialIcon(String path) {
    return Image.asset(path, width: 32, height: 32);
  }
}