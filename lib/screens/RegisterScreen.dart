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

  // Xử lý đăng ký tài khoản, kiểm tra dữ liệu và chuyển sang bước nhập hồ sơ.
  Future<void> _register() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String confirm = confirmController.text.trim();
    final String name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      Notifier.showError(context, 'Vui lòng nhập đầy đủ thông tin!!!');
      return;
    }

    if (!_isValidEmail(email)) {
      Notifier.showError(context, 'Email không hợp lệ!!!');
      return;
    }

    if (password != confirm) {
      Notifier.showError(context, 'Mật khẩu không khớp!!!');
      return;
    }

    try {
      setState(() => isLoading = true);

      final result = await _authController.register(
        email: email,
        password: password,
      );
      final String uid = result['uid'];

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterStep2Screen(
            uid: uid,
            email: email,
            name: name,
            avatar: 'https://cdn-icons-png.flaticon.com/512/149/149071.png',
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

  String _mapFirebaseAuthError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email đã được sử dụng!!!';
      case 'invalid-email':
        return 'Email không hợp lệ!!!';
      case 'weak-password':
        return 'Mật khẩu quá yếu (tối thiểu 6 ký tự)!!!';
      case 'network-request-failed':
        return 'Lỗi kết nối mạng, vui lòng kiểm tra Internet!!!';
      case 'too-many-requests':
        return 'Bạn thao tác quá nhiều, vui lòng thử lại sau!!!';
      case 'operation-not-allowed':
        return 'Chức năng đăng ký hiện không khả dụng!!!';
      default:
        return 'Đăng ký thất bại, vui lòng thử lại!!!';
    }
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