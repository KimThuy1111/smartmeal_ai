import 'package:flutter/material.dart';
import '../controllers/AuthController.dart';
import '../utils/notifier.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {

  final AuthController _authController = AuthController();

  final currentPassController = TextEditingController();
  final newPassController = TextEditingController();
  final confirmPassController = TextEditingController();

  bool showPass = true;

  // Kiểm tra thông tin và thực hiện đổi mật khẩu
  Future<void> changePassword() async {

    String currentPass = currentPassController.text.trim();
    String newPass = newPassController.text.trim();
    String confirmPass = confirmPassController.text.trim();

    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      Notifier.showError(context, "Vui lòng nhập đầy đủ thông tin");
      return;
    }

    if (newPass != confirmPass) {
      Notifier.showError(context, "Mật khẩu xác nhận không khớp");
      return;
    }

    try {

      await _authController.changePassword(
        currentPass: currentPass,
        newPass: newPass,
      );

      Notifier.showNotify(context, "Đổi mật khẩu thành công");
      Navigator.pop(context);

    } catch (e) {

      String message = "Đổi mật khẩu thất bại";

      if (e is Exception) {
        if (e.toString().contains('wrong-password')) {
          message = "Mật khẩu hiện tại không đúng";
        }
      }

      Notifier.showError(context, message);
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

        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),

            child: Column(
              children: [

                // Thanh tiêu đề
                Row(
                  children: [

                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),

                    const Expanded(
                      child: Center(
                        child: Text(
                          "Thay đổi mật khẩu",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 30),

                buildInput("Mật khẩu hiện tại", currentPassController),

                const SizedBox(height: 16),

                buildInput("Mật khẩu mới", newPassController),

                const SizedBox(height: 16),

                buildInput("Xác nhận mật khẩu", confirmPassController),

                const SizedBox(height: 30),

                GestureDetector(
                  onTap: changePassword,
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF79EEF2), Color(0xFF78F09C)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      "Cập nhật mật khẩu",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInput(String hint, TextEditingController controller) {

    return TextField(
      controller: controller,
      obscureText: showPass,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),

        suffixIcon: IconButton(
          icon: Icon(
            showPass ? Icons.visibility : Icons.visibility_off,
          ),
          onPressed: () {
            setState(() {
              showPass = !showPass;
            });
          },
        ),
      ),
    );
  }
}