import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../controllers/AuthController.dart';
import '../utils/notifier.dart';
import 'LoginScreen.dart';
import 'RegisterStep2Screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final AuthController _authController = AuthController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmController = TextEditingController();
  final TextEditingController nameController = TextEditingController();

  bool showPassword = false;
  bool showConfirmPassword = false;
  bool isLoading = false;

  Future<void> _register() async {
    // 3. Hệ thống kiểm tra dữ liệu.
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String confirm = confirmController.text.trim();
    final String name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      // 3a. Nếu người dùng nhập thiếu thông tin, hệ thống yêu cầu nhập đầy đủ.
      Notifier.showError(context, 'Vui lòng nhập đầy đủ thông tin!!!');
      return;
    }

    // 3b. Nếu email sai định dạng, hệ thống thông báo email không hợp lệ.
    if (!_isValidEmail(email)) {
      Notifier.showError(context, 'Email không hợp lệ!!!');
      return;
    }

    // 3c. Nếu mật khẩu không trùng khớp, hệ thống thông báo lỗi.
    if (password != confirm) {
      Notifier.showError(context, 'Mật khẩu không khớp!!!');
      return;
    }

    // 3e. Mật khẩu không đủ mạnh, hệ thống yêu cầu người dùng đặt mật khẩu mạnh hơn.
    if (!_isStrongPassword(password)) {
      Notifier.showError(
        context,
        'Mật khẩu phải có ít nhất 8 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt!!!',
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      // 4. Nếu hợp lệ, hệ thống tạo tài khoản cho người dùng.
      final result = await _authController.register(
        email: email,
        password: password,
      );

      final String uid = result['uid'];

      // 6. Hệ thống chuyển sang trang nhập thông tin cá nhân.
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterStep2Screen(
            uid: uid,
            email: email,
            name: name,
            avatar: 'https://cdn-icons-png.flaticon.com/512/149/149071.png',
            showRegisterSuccessMessage: true,
          ),
        ),
      );
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

  bool _isStrongPassword(String password) {
    if (password.length < 8) {
      return false;
    }

    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

    return hasUpper && hasLower && hasDigit && hasSpecial;
  }

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      // 3d. Nếu email đã được sử dụng, hệ thống thông báo tài khoản đã tồn tại.
      case 'email-already-in-use':
        return 'Email đã được sử dụng!!!';

      // 3b. Nếu email sai định dạng, hệ thống thông báo email không hợp lệ.
      case 'invalid-email':
        return 'Email không hợp lệ!!!';

      // 3e. Mật khẩu không đủ mạnh, hệ thống yêu cầu người dùng đặt mật khẩu mạnh hơn.
      case 'weak-password':
        return 'Mật khẩu chưa đủ mạnh (ít nhất 8 ký tự, gồm chữ hoa, chữ thường, số và ký tự đặc biệt)!!!';

      // 3f / 4d. Không có kết nối Internet, hệ thống thông báo lỗi mạng và yêu cầu kiểm tra lại kết nối.
      case 'network-request-failed':
        return 'Lỗi kết nối mạng, vui lòng kiểm tra Internet!!!';

      // 4e. Nếu hệ thống trả về too-many-requests, thông báo người dùng thử lại sau.
      case 'too-many-requests':
        return 'Bạn thao tác quá nhiều, vui lòng thử lại sau!!!';

      // 4f. Nếu hệ thống trả về operation-not-allowed, thông báo chức năng hiện không khả dụng.
      case 'operation-not-allowed':
        return 'Chức năng đăng ký hiện không khả dụng!!!';

      // 3g / 4g. Nếu là các lỗi khác, hệ thống thông báo đăng ký thất bại.
      default:
        return 'Đăng ký thất bại, vui lòng thử lại!!!';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 0. Người dùng đang ở màn hình đăng ký.
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE4FFE4), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Image.asset('assets/images/logo.png', height: 100),
              const SizedBox(height: 5),
              const Text(
                'CALO',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'ĐĂNG KÝ',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 30),
              // 1. Người dùng nhập email, tên, mật khẩu, xác nhận mật khẩu.
              _buildInputField('Tên đầy đủ', nameController),
              const SizedBox(height: 16),
              _buildInputField('Email', emailController),
              const SizedBox(height: 16),
              _buildInputField(
                'Mật khẩu',
                passwordController,
                isPassword: true,
                showValue: showPassword,
                onToggle: () {
                  setState(() {
                    showPassword = !showPassword;
                  });
                },
              ),
              const SizedBox(height: 16),
              _buildInputField(
                'Xác nhận mật khẩu',
                confirmController,
                isPassword: true,
                showValue: showConfirmPassword,
                onToggle: () {
                  setState(() {
                    showConfirmPassword = !showConfirmPassword;
                  });
                },
              ),
              const SizedBox(height: 20),
              if (isLoading) const CircularProgressIndicator(),
              const SizedBox(height: 10),
              GestureDetector(
                // 2. Người dùng nhấn "Đăng ký".
                onTap: _register,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF79EEF2), Color(0xFF78F09C)],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Text(
                    'ĐĂNG KÝ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bạn đã có tài khoản? '),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      'Đăng nhập',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Tạo ô nhập liệu dùng chung, hỗ trợ bật/tắt hiển thị mật khẩu.
  Widget _buildInputField(
    String hint,
    TextEditingController controller, {
    bool isPassword = false,
    bool? showValue,
    VoidCallback? onToggle,
  }) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE0F2F1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? !(showValue ?? false) : false,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    (showValue ?? false)
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: onToggle,
                )
              : null,
        ),
      ),
    );
  }
}