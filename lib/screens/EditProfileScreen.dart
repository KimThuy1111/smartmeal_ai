import 'package:flutter/material.dart';
import '../utils/notifier.dart';
import '../controllers/UserController.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  final UserController _userController = UserController();

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();

  String gender = "Nam";
  String activity = "Ít vận động";
  String goal = "Duy trì cân nặng";

  List<String> selectedDiseases = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  // Tải thông tin người dùng hiện tại để hiển thị lên form
  Future<void> loadUser() async {
    final data = await _userController.getUserData();

    if (data != null) {
      nameController.text = data["name"] ?? "";
      ageController.text = (data["age"] ?? 0).toString();
      weightController.text = (data["weight"] ?? 0).toString();
      heightController.text = (data["height"] ?? 0).toString();

      gender = data["gender"] ?? "Nam";
      activity = data["activity"] ?? "Ít vận động";
      goal = data["goal"] ?? "Duy trì cân nặng";

      selectedDiseases = List<String>.from(data["diseases"] ?? []);
    }

    setState(() {
      isLoading = false;
    });
  }

  // Kiểm tra dữ liệu và cập nhật thông tin hồ sơ
  Future<void> updateProfile() async {
    try {
      await _userController.updateUser(
        name: nameController.text,
        age: ageController.text,
        weight: weightController.text,
        height: heightController.text,
        gender: gender,
        activity: activity,
        goal: goal,
      );

      Notifier.showNotify(context, "Cập nhật thành công");
      Navigator.pop(context);
    } catch (e) {
      Notifier.showError(context, "Cập nhật thất bại");
    }
  }

  @override
  Widget build(BuildContext context) {

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                const SizedBox(height: 10),

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
                          "Chỉnh sửa thông tin",
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

                const SizedBox(height: 20),

                buildInput("Tên", nameController),
                const SizedBox(height: 16),

                buildInput("Tuổi", ageController),
                const SizedBox(height: 16),

                buildInput("Cân nặng (kg)", weightController),
                const SizedBox(height: 16),

                buildInput("Chiều cao (cm)", heightController),

                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Giới tính",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),

                Row(
                  children: [
                    Radio(
                      value: "Nam",
                      groupValue: gender,
                      onChanged: (v) => setState(() => gender = v!),
                    ),
                    const Text("Nam"),
                    Radio(
                      value: "Nữ",
                      groupValue: gender,
                      onChanged: (v) => setState(() => gender = v!),
                    ),
                    const Text("Nữ"),
                  ],
                ),

                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Mức độ vận động",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),

                buildDropdown(activity,
                    ["Ít vận động", "Vận động nhẹ", "Vận động vừa phải", "Vận động nhiều"],
                        (v) => setState(() => activity = v)),

                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Mục tiêu cân nặng",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),

                buildDropdown(goal,
                    ["Giảm cân", "Duy trì cân nặng", "Tăng cân"],
                        (v) => setState(() => goal = v)),

                const SizedBox(height: 30),

                // Nút lưu thay đổi
                GestureDetector(
                  onTap: updateProfile,
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
                      "Cập nhật",
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

  // Tạo ô nhập liệu dùng chung cho form chỉnh sửa hồ sơ
  Widget buildInput(String text, TextEditingController controller) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: text,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  // Tạo danh sách chọn dạng dropdown cho giới tính, vận động và mục tiêu
  Widget buildDropdown(
      String value,
      List<String> items,
      Function(String) onChanged) {

    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
          .toList(),
      onChanged: (v) => onChanged(v!),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}