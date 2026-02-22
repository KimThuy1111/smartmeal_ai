import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartmeal_ai/screens/RegisterStep2Screen.dart';
import 'package:smartmeal_ai/utils/notifier.dart';

import 'LoginScreen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Lấy dữ liệu người dùng nhập vào 
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmController = TextEditingController();
  final nameController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool showPassword = false;
  bool showConfirmPassword = false;


  // Hàm đăng ký
  void register() async {
    // Lấy dữ liệu từ TextField
    String email = emailController.text.trim();
    String password = passwordController.text.trim();
    String confirm = confirmController.text.trim();
    String name = nameController.text.trim();

    //Kiểm tra dữ liệu
    if (email.isEmpty || password.isEmpty || name.isEmpty) {
      Notifier.showError(context, "Vui lòng nhập đầy đủ thông tin!!! ");
      return;
    }
    if (password != confirm) {
      Notifier.showError(context, "Mật khẩu không khớp!!! ");
      return;
    }

    // Tạo tài khoản firebase auth
    try{
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      String uid = userCredential.user!.uid;

      // Chuyển sang step 2
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RegisterStep2Screen(uid: uid, email: email, name: name),
        ),
      );
    } catch (e) {
      Notifier.showError(context, e.toString());
    }
  }

// UI
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
              Image.asset("assets/images/logo.png",height: 100,),
              const SizedBox(height: 5),

              const Text(
                "CALO",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "ĐĂNG KÝ",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),

              const SizedBox(height: 30),

              buildInputField("Tên đầy đủ", nameController),
              const SizedBox(height: 16),

              buildInputField("Email", emailController),
              const SizedBox(height: 16),

              buildInputField(
                "Mật khẩu",
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

              buildInputField(
                "Xác nhận mật khẩu",
                confirmController,
                isPassword: true,
                showValue: showConfirmPassword,
                onToggle: () {
                  setState(() {
                    showConfirmPassword = !showConfirmPassword;
                  });
                },
              ),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: register,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF79EEF2),
                        Color(0xFF78F09C)
                      ],
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    "ĐĂNG KÝ",
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
                  const Text("Bạn đã có tài khoản? "),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginScreen(),
                        ),
                      );
                    },
                    child: const Text("Đăng nhập",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold),
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

  Widget buildInputField(
      String hint,
      TextEditingController controller, {
        bool isPassword = false,
        bool? showValue,
        VoidCallback? onToggle,
      }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE0F2F1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.center,
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
