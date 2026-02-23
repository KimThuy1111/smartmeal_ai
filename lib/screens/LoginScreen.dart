import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:smartmeal_ai/screens/RegisterScreen.dart';
import 'package:smartmeal_ai/screens/RegisterStep2Screen.dart';

import '../utils/notifier.dart';
import 'HomeScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool isLoading = false;
  bool showPass = true;

  // Hàm login
  void login() async {
    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    //2.2.3 Yêu cầu người dùng nhập đầy đủ thông tin
    if (email.isEmpty || password.isEmpty) {
      Notifier.showError(context, "Vui lòng nhập đầy đủ thông tin!");
      return;
    }

    try {
      setState(() => isLoading = true);

      //2.1.3 Gửi yêu cầu xác thực đến Firebase Authentication
      UserCredential userCredential =
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      //2.1.4 Lấy userId của người dùng
      String uid = userCredential.user!.uid;

      //2.1.5 Kiểm tra xem người dùng đã nhập thông tin cá nhân chưa
      DocumentSnapshot doc =
      await _db.collection("users").doc(uid).get();

      if (doc.exists) {
        //2.1.6 Chuyển đến trang home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
              (route) => false,
        );
        Notifier.showNotify(context, "Đăng nhập thành công!!!");

      } else {
        //2.2.6 Chuyển đến trang điền thông tin
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RegisterStep2Screen(
              uid: uid,
              email: email,
              name: userCredential.user!.displayName ?? "",
            ),
          ),
        );
      }

    } on FirebaseAuthException catch (e) {

  //2.2.3 Thông tin không hợp lệ
  String message = "Đăng nhập thất bại!";
  if (e.code == 'user-not-found') {
  message = "Email chưa được đăng ký!";
  }
  else if (e.code == 'wrong-password') {
  message = "Sai mật khẩu!";
  }
  else if (e.code == 'invalid-email') {
  message = "Email không hợp lệ!";
  }
  Notifier.showError(context, message);
  }
  finally {
      setState(() => isLoading = false);
    }
  }

  //UI
  @override
  Widget build(BuildContext context){
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE4FFE4), Colors.white,],
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
                Image.asset("assets/images/logo.png",height: 100,),
                const SizedBox(height: 5),

                const Text(
                  "CALO",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  "ĐĂNG NHẬP",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333),
                  ),
                ),
                const SizedBox(height: 30),

                //2.1.1 Người dùng nhập email và password
                buildInputField(
                  controller: emailController,
                  hint: "Nhập email",
                ),
                const SizedBox(height: 16),

                buildInputField(
                  controller: passwordController,
                  hint: "Nhập mật khẩu",
                  isPassword: true,
                ),
                const SizedBox(height: 30),

                if(isLoading)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: CircularProgressIndicator(),
                  ),
                const SizedBox(height: 10),

                //2.1.2 Khi người dùng click "Đăng nhập" gọi hàm login để xử lý
                GestureDetector(
                  onTap: login,
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
                      "ĐĂNG NHẬP",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  "Forgot Password?",
                  style: TextStyle(
                    color: Color(0xFF2196F3),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Bạn chưa có tài khoản? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text("Đăng ký",
                        style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text("---------- HOẶC ----------"),
                const SizedBox(height: 7),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    buildSocialIcon("assets/images/ic_google.png"),
                  ],
                ),
              ]
            )
          )
        )
      ),
    );
  }
  Widget buildInputField({
    required TextEditingController controller,
    required String hint,
    bool isPassword = false,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE0F2F1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: TextField(
          controller: controller,
          obscureText: isPassword ? showPass : false,
          decoration: InputDecoration(
            hintText: hint,
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Color(0xFF888888)),

            // Icon con mắt
            suffixIcon: isPassword
                ? IconButton(
              icon: Icon(
                showPass? Icons.visibility : Icons.visibility_off,
                color: Colors.grey,
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
      ),
    );
  }


  Widget buildSocialIcon(String path) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Image.asset(
        path,
        width: 32,
        height: 32,
      ),
    );
  }
}