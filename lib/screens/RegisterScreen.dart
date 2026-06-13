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
  bool agreeToPolicy = false;

  Future<void> _register() async {
    // Kiểm tra xem người dùng đã đồng ý với chính sách bảo mật chưa
    if (!agreeToPolicy) {
      Notifier.showError(context, 'Vui lòng đồng ý với chính sách bảo mật của hệ thống!');
      return;
    }

    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();
    final String confirm = confirmController.text.trim();
    final String name = nameController.text.trim();

    // 3. Hệ thống kiểm tra tính hợp lệ của dữ liệu (email đúng định dạng, tên không được dài quá 255 ký tự, mật khẩu tối thiểu 8 ký tự, có chữ hoa, số, ký tự đặc biệt).
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      // 3a. Nếu người dùng nhập thiếu thông tin
      // 3a1. Hệ thống hiển thị “Nhập đầy đủ thông tin!”
      Notifier.showError(context, 'Vui lòng nhập đầy đủ thông tin!');
      // 3a2. Quay lại bước 1
      return;
    }

    if (!_isValidEmail(email)) {
      // 3b. Nếu email sai định dạng
      // 3b1. Hệ thống thông báo “Email không hợp lệ!”
      Notifier.showError(context, 'Email không hợp lệ!');
      // 3b2. Quay lại bước 1
      return;
    }

    if (password != confirm) {
      // 3c. Nếu mật khẩu không trùng khớp
      // 3c1. Hệ thống thông báo “Mật khẩu không trùng khớp!”
      Notifier.showError(context, 'Mật khẩu không trùng khớp!');
      // 3c2. Quay lại bước 1
      return;
    }

    if (!_isStrongPassword(password)) {
      // 3e. Nếu mật khẩu không đủ mạnh
      // 3e1. Hệ thống thông báo “Mật khẩu tối thiểu 8 ký tự, có chữ hoa, số, ký tự đặc biệt!”
      Notifier.showError(
        context,
        'Mật khẩu tối thiểu 8 ký tự, có chữ hoa, số, ký tự đặc biệt!',
      );
      // 3e2. Quay lại bước 1
      return;
    }
    
    if (name.length > 255) {
      // 3g. Nếu tên dài quá 255 ký tự 
      // 3g1. Hệ thống thông báo “Tên không được dài quá 255 ký tự!”
      Notifier.showError(context, 'Tên không được dài quá 255 ký tự!');
      // 3g2. Quay lại bước 1
      return;
    }

    try {
      setState(() => isLoading = true);

      // 4. Hệ thống tạo tài khoản cho người dùng
      final result = await _authController.register(
        email: email,
        password: password,
      );

      final String uid = result['uid'];

      // 6. Hệ thống chuyển sang trang nhập thông tin cá nhân
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
      // 3h. Nếu là các lỗi khác
      // 3h1. Hệ thống thông báo “Đăng ký thất bại!”
      Notifier.showError(
        context,
        'Đăng ký thất bại!',
      );
      // 3h2. Quay lại bước 1
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
      case 'email-already-in-use':
        // 3d. Nếu email đã được sử dụngdụng. Hệ thống thông báo “Tài khoản đã tồn tại!”
        return 'Tài khoản đã tồn tại!';

      case 'invalid-email':
        // 3b. Nếu email sai định dạng. Hệ thống thông báo “Email không hợp lệ!”
        return 'Email không hợp lệ!';

      case 'weak-password':
        // 3e. Nếu mật khẩu không đủ mạnh. Hệ thống thông báo “Mật khẩu tối thiểu 8 ký tự, có chữ hoa, số, ký tự đặc biệt!”
        return 'Mật khẩu tối thiểu 8 ký tự, có chữ hoa, số, ký tự đặc biệt!';

      case 'network-request-failed':
        // 3f. Nếu không có kết nối Internet. Hệ thống thông báo “Lỗi mạng, cần kiểm tra lại kết nối!”
        return 'Lỗi mạng, cần kiểm tra lại kết nối!';

      // 4f. Nếu hệ thống trả về operation-not-allowed, thông báo chức năng hiện không khả dụng.
      default:
        // 3g. Nếu là các lỗi khác. Hệ thống thông báo “Đăng ký thất bại!”
        return 'Đăng ký thất bại!';
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
              // Checkbox: Đồng ý với chính sách bảo mật
              Row(
                children: [
                  Checkbox(
                    value: agreeToPolicy,
                    onChanged: (value) {
                      setState(() {
                        agreeToPolicy = value ?? false;
                      });
                    },
                    activeColor: const Color(0xFF78F09C),
                  ),
                  const Expanded(
                    child: Text(
                      'Tôi đồng ý với chính sách bảo mật của hệ thống',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (isLoading) const CircularProgressIndicator(),
              const SizedBox(height: 10),
              GestureDetector(
                // 2. Người dùng nhấn "Đăng ký".
                onTap: agreeToPolicy ? _register : null,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: agreeToPolicy
                        ? const LinearGradient(
                            colors: [Color(0xFF79EEF2), Color(0xFF78F09C)],
                          )
                        : LinearGradient(
                            colors: [
                              const Color(0xFF79EEF2).withOpacity(0.4),
                              const Color(0xFF78F09C).withOpacity(0.4),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    'ĐĂNG KÝ',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: agreeToPolicy ? Colors.black : Colors.grey,
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