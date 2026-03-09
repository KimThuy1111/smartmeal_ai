import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../utils/notifier.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  // Load dữ liệu user hiện tại
  Future<void> loadUser() async {

    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _db.collection("users").doc(user.uid).get();

    if (doc.exists) {

      final data = doc.data();

      nameController.text = data?["name"] ?? "";
      ageController.text = (data?["age"] ?? 0).toString();
      weightController.text = (data?["weight"] ?? 0).toString();
      heightController.text = (data?["height"] ?? 0).toString();

      gender = data?["gender"] ?? "Nam";
      activity = data?["activity"] ?? "Ít vận động";
      goal = data?["goal"] ?? "Duy trì cân nặng";

      selectedDiseases = List<String>.from(data?["diseases"] ?? []);
    }

    setState(() {
      isLoading = false;
    });
  }

  // Cập nhật Firestore
  Future<void> updateProfile() async {

    final user = _auth.currentUser;
    if (user == null) return;

    await _db.collection("users").doc(user.uid).update({

      "name": nameController.text,
      "age": int.parse(ageController.text),
      "weight": double.parse(weightController.text),
      "height": double.parse(heightController.text),

      "gender": gender,
      "activity": activity,
      "goal": goal,
      "diseases": selectedDiseases
    });

    Notifier.showNotify(context, "Cập nhật thành công");

    Navigator.pop(context);
  }

  // checkbox bệnh
  Widget buildCheckbox(String disease) {
    return CheckboxListTile(
      value: selectedDiseases.contains(disease),
      title: Text(disease),
      onChanged: (value) {
        setState(() {
          if (value == true) {
            selectedDiseases.add(disease);
          } else {
            selectedDiseases.remove(disease);
          }
        });
      },
    );
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

                // HEADER
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

                    const SizedBox(width: 48), // giữ tiêu đề nằm giữa
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
                  child: Text(
                    "Giới tính",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
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
                  child: Text(
                    "Mức độ vận động",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                buildDropdown(
                    activity,
                    [
                      "Ít vận động",
                      "Vận động nhẹ",
                      "Vận động vừa phải",
                      "Vận động nhiều"
                    ],
                        (v) => setState(() => activity = v)
                ),

                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Mục tiêu cân nặng",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                buildDropdown(
                    goal,
                    [
                      "Giảm cân",
                      "Duy trì cân nặng",
                      "Tăng cân"
                    ],
                        (v) => setState(() => goal = v)
                ),

                const SizedBox(height: 20),

                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Bệnh nền",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                buildCheckbox("Tăng huyết áp"),
                buildCheckbox("Bệnh tim"),
                buildCheckbox("Bệnh thận"),
                buildCheckbox("Tiểu đường"),
                buildCheckbox("Mụn trứng cá"),

                const SizedBox(height: 30),

                GestureDetector(
                  onTap: updateProfile,
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF79EEF2), Color(0xFF78F09C),],),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    alignment: Alignment.center,
                    child: const Text("Cập nhật",
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
          ),
        ),
      ),
    );
  }

  Widget buildInput(String hint, TextEditingController controller) {

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

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