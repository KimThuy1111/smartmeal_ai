import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user.dart';
import '../utils/notifier.dart';
import 'HomeScreen.dart';

class RegisterStep2Screen extends StatefulWidget {
  final String uid;
  final String email;
  final String name;
  
  const RegisterStep2Screen({
    super.key,
    required this.uid,
    required this.email,
    required this.name,
  });
  
  @override
  State<RegisterStep2Screen> createState() => _RegisterStep2ScreenState();
}

class _RegisterStep2ScreenState extends State<RegisterStep2Screen> {
  // Lấy dữ liệu từ textField
  final ageController = TextEditingController();
  final weightController = TextEditingController();
  final heightController = TextEditingController();
  String gender = "Nam";
  String activity = "Ít vận động";
  String goal = "Duy trì cân nặng";
  List<String> selectedDiseases = [];

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Hàm lưu user vào firestore
  void saveUser() async {
    try {
      // Kiểm tra dữ liệu
      if (ageController.text.isEmpty || weightController.text.isEmpty || heightController.text.isEmpty) {
        Notifier.showError(context, "Vui lòng nhập đầy đủ thông tin!!!");
        return;
      }

      User user = User(
        uid: widget.uid,
        email: widget.email,
        name: widget.name,
        age: int.parse(ageController.text),
        weight: double.parse(weightController.text),
        height: double.parse(heightController.text),
        gender: gender,
        activity: activity,
        goal: goal,
        diseases: selectedDiseases,
      );

      await _db.collection("users").doc(widget.uid).set(user.toMap());
      Notifier.showNotify(context, "Đăng ký thành công!!!");

      // Chuyển về Login và xóa toàn bộ stack trước đó
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
      );
    } catch (e) {
      Notifier.showError(context, "Lỗi: ${e.toString()}");
    }
  }

  // Tạo checkbox bệnh
  Widget buildCheckbox(String disease) {
    return CheckboxListTile(
      value: selectedDiseases.contains(disease),
      title: Text(disease),
      onChanged: (value) {
        setState(() {
          if (value == true) {
            selectedDiseases.add(disease);
          }else {
            selectedDiseases.remove(disease);
          }
        });
      },
    );
  }

  // UI
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFFE4FFE4), Colors.white],
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
              const SizedBox(height: 10),

              const Text(
                "THÔNG TIN CÁ NHÂN",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Giới tính",
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Radio(
                    activeColor: const Color(0xFF68E3B5),
                    value: "Nam",
                    groupValue: gender,
                    onChanged: (g) => setState(() => gender = g!),
                  ),
                  const Text("Nam"),
                  const SizedBox(width: 20),

                  Radio(
                    activeColor: const Color(0xFF68E3B5),
                    value: "Nữ",
                    groupValue: gender,
                    onChanged: (g) => setState(() => gender = g!),
                  ),
                  const Text("Nữ"),
                ],
              ),
              const SizedBox(height: 16),

              buildInput("Tuổi", ageController),
              const SizedBox(height: 16),

              buildInput("Cân nặng (kg)", weightController),
              const SizedBox(height: 16),

              buildInput("Chiều cao (cm)", heightController),
              const SizedBox(height: 16),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Mức độ vận động",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              buildDropdown(activity, ["Ít vận động", "Vận động nhẹ", "Vận động mạnh"], (a) => setState(() => activity = a)),
              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Mục tiêu cân nặng",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              buildDropdown(goal, ["Giảm cân", "Duy trì cân nặng", "Tăng cân"], (g) => setState(() => goal = g)),
              const SizedBox(height: 24),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Bệnh nền (nếu có)",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 10),
              buildCheckbox("Tăng huyết áp"),
              buildCheckbox("Bệnh tim"),
              buildCheckbox("Bệnh thận"),
              buildCheckbox("Tiểu đường"),
              buildCheckbox("Mụn trứng cá"),

              const SizedBox(height: 30),

              GestureDetector(
                onTap: saveUser,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF79EEF2), Color(0xFF78F09C),],),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  alignment: Alignment.center,
                  child: const Text("Tiếp tục",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight:  FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        )

      ),
    );
  }
  
  Widget buildInput(String hint, TextEditingController controller){
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
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
        ),
      ),
    );
  }

  Widget buildDropdown(
      String value,
      List<String> items,
      Function(String) onChanged) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE0F2F1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items.map((e) =>
              DropdownMenuItem(
                value: e,
                child: Text(e),
              )).toList(),
          onChanged: (v) => onChanged(v!),
        ),
      ),
    );
  }
}