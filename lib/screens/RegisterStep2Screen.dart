import 'package:flutter/material.dart';

import '../controllers/UserController.dart';
import '../models/Role.dart';
import '../models/User.dart';
import '../utils/notifier.dart';
import 'HomeScreen.dart';

class RegisterStep2Screen extends StatefulWidget {
  final String uid;
  final String email;
  final String name;
  final String avatar;

  const RegisterStep2Screen({
    super.key,
    required this.uid,
    required this.email,
    required this.name,
    required this.avatar,
  });

  @override
  State<RegisterStep2Screen> createState() => _RegisterStep2ScreenState();
}

class _RegisterStep2ScreenState extends State<RegisterStep2Screen> {
  final UserController _userController = UserController();

  final TextEditingController ageController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController heightController = TextEditingController();

  String gender = 'Nam';
  String activity = 'Ít vận động';
  String goal = 'Duy trì cân nặng';

  /// Kiểm tra dữ liệu, tạo hồ sơ người dùng và lưu vào Firestore.
  Future<void> _saveUser() async {
    try {
      if (ageController.text.isEmpty ||
          weightController.text.isEmpty ||
          heightController.text.isEmpty) {
        Notifier.showError(context, 'Vui lòng nhập đầy đủ thông tin!!!');
        return;
      }

      final user = User(
        uid: widget.uid,
        email: widget.email,
        name: widget.name,
        age: int.parse(ageController.text),
        weight: double.parse(weightController.text),
        height: double.parse(heightController.text),
        gender: gender,
        activity: activity,
        goal: goal,
        avatar: widget.avatar.isEmpty
            ? 'https://cdn-icons-png.flaticon.com/512/149/149071.png'
            : widget.avatar,
        role: Role.user,
        createdAt: DateTime.now(),
      );

      await _userController.createUserProfile(
        uid: widget.uid,
        data: user.toMap(),
      );

      Notifier.showNotify(context, 'Đăng ký thành công!!!');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } catch (e) {
      Notifier.showError(context, 'Lỗi: ${e.toString()}');
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
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'THÔNG TIN CÁ NHÂN',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Giới tính',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 15),
                  Radio<String>(
                    value: 'Nam',
                    groupValue: gender,
                    onChanged: (g) => setState(() => gender = g!),
                  ),
                  const Text('Nam'),
                  const SizedBox(width: 20),
                  Radio<String>(
                    value: 'Nữ',
                    groupValue: gender,
                    onChanged: (g) => setState(() => gender = g!),
                  ),
                  const Text('Nữ'),
                ],
              ),
              const SizedBox(height: 16),
              _buildInput('Tuổi', ageController),
              const SizedBox(height: 16),
              _buildInput('Cân nặng (kg)', weightController),
              const SizedBox(height: 16),
              _buildInput('Chiều cao (cm)', heightController),
              const SizedBox(height: 20),
              _buildDropdown(
                activity,
                const [
                  'Ít vận động',
                  'Vận động nhẹ',
                  'Vận động vừa phải',
                  'Vận động nhiều',
                  'Vận động cực nhiều',
                ],
                (v) => setState(() => activity = v),
              ),
              const SizedBox(height: 20),
              _buildDropdown(
                goal,
                const ['Giảm cân', 'Duy trì cân nặng', 'Tăng cân'],
                (v) => setState(() => goal = v),
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _saveUser,
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
                    'Tiếp tục',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  /// Tạo ô nhập số cho thông tin tuổi, cân nặng và chiều cao.
  Widget _buildInput(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(hintText: hint),
    );
  }

  /// Tạo dropdown dùng chung cho mức vận động và mục tiêu dinh dưỡng.
  Widget _buildDropdown(
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem<String>(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => onChanged(v!),
    );
  }
}