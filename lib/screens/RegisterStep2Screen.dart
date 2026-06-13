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
  final bool showRegisterSuccessMessage;

  const RegisterStep2Screen({
    super.key,
    required this.uid,
    required this.email,
    required this.name,
    required this.avatar,
    this.showRegisterSuccessMessage = false,
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

  @override
  void initState() {
    super.initState();

    if (widget.showRegisterSuccessMessage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        // 5. Hệ thống hiển thị thông báo đăng ký thành công
        Notifier.showNotify(context, 'Đăng ký thành công!');
      });
    }
  }

  Future<void> _saveUser() async {
    try {
      // 3. Hệ thống kiểm tra dữ liệu
      if (ageController.text.isEmpty || weightController.text.isEmpty || heightController.text.isEmpty) {
        // 3a. Nếu người dùng nhập thiếu thông tin. Hệ thống hiển thị “Vui lòng nhập đầy đủ thông tin!”
        Notifier.showError(context, 'Vui lòng nhập đầy đủ thông tin!');
        return;
      }

      if (!_isValidNumber(ageController.text) || int.parse(ageController.text) <= 0) {
        // 3b. Nếu tuổi không hợp lệ. Hệ thống hiển thị “Tuổi phải là số nguyên dương!”
        Notifier.showError(context, 'Tuổi phải là số nguyên dương!');
        return;
      }

      if (!_isValidDecimal(weightController.text) || !_isValidDecimal(heightController.text) || double.parse(weightController.text) <= 0 || double.parse(heightController.text) <= 0) {
        // 3c. Nếu chiều cao hoặc cân nặng không hợp lệ. Hệ thống hiển thị “Chiều cao và cân nặng không hợp lệ!”
        Notifier.showError(context, 'Chiều cao và cân nặng không hợp lệ!');
        return;
      }

      if (!['Ít vận động', 'Vận động nhẹ', 'Vận động vừa phải', 'Vận động nhiều', 'Vận động cực nhiều'].contains(activity) || 
          !['Giảm cân', 'Duy trì cân nặng', 'Tăng cân'].contains(goal)) {
        // 3d. Nếu mức độ vận động hoặc mục tiêu cân nặng không hợp lệ. Hệ thống hiển thị “Mức độ vận động hoặc mục tiêu cân nặng không hợp lệ!”
        Notifier.showError(context, 'Mức độ vận động hoặc mục tiêu cân nặng không hợp lệ!');
        return;
      }

      // 4. Hệ thống tạo hồ sơ người dùng hoàn chỉnh
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

      // 5. Hệ thống lưu hồ sơ người dùng.
      await _userController.createUserProfile(
        uid: widget.uid,
        data: user.toMap(),
      );

      // Tính TDEE ngay sau khi tạo hồ sơ
      await _userController.recalculateTDEE(
        age: ageController.text,
        gender: gender,
        height: heightController.text,
        weight: weightController.text,
        activity: activity,
        goal: goal,
      );

      // 6. Hệ thống thông báo lưu thông tin thành công
      Notifier.showNotify(context, 'Lưu thông tin thành công!');

      // 7. Hệ thống điều hướng người dùng đến màn hình trang chủ.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on Exception catch (e) {
      if (e.toString().contains('network') || e.toString().contains('unavailable')) {
        // 5b. Nếu không có kết nối Internet. Hệ thống hiển thị “Lỗi mạng, cần kiểm tra lại kết nối!”
        Notifier.showError(context, 'Lỗi mạng, cần kiểm tra lại kết nối!');
      } else {
        // 5a. Nếu lưu hồ sơ thất bại. Hệ thống hiển thị “Lưu thông tin thất bại, vui lòng thử lại!”
        Notifier.showError(context, 'Lưu thông tin thất bại, vui lòng thử lại!');
      }
    } catch (_) {
      // 5c. Nếu xảy ra lỗi khác. Hệ thống hiển thị “Cập nhật thông tin thất bại!”
      Notifier.showError(
        context,
        'Cập nhật thông tin thất bại!',
      );
    }
  }

  bool _isValidNumber(String value) {
    try {
      int.parse(value);
      return true;
    } catch (_) {
      return false;
    }
  }

  bool _isValidDecimal(String value) {
    try {
      double.parse(value);
      return true;
    } catch (_) {
      return false;
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
              // 1. Người dùng nhập thông tin cá nhân (giới tính, tuổi, cân nặng, chiều cao, mức độ vận động, mục tiêu cân nặng).
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
                // 2. Người dùng chọn “Tiếp tục”
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

  // Tạo ô nhập số cho thông tin tuổi, cân nặng và chiều cao.
  Widget _buildInput(String hint, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(hintText: hint),
    );
  }

  // Tạo dropdown dùng chung cho mức vận động và mục tiêu dinh dưỡng.
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