import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../models/Food.dart';
import '../../utils/notifier.dart';

class FoodFormScreen extends StatefulWidget {
  final Food? food;

  const FoodFormScreen({super.key, this.food});

  @override
  State<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends State<FoodFormScreen> {

  final nameController = TextEditingController();
  final englishController = TextEditingController();
  final imageController = TextEditingController();

  final calController = TextEditingController();
  final proteinController = TextEditingController();
  final fatController = TextEditingController();
  final carbController = TextEditingController();

  final calciumController = TextEditingController();
  final ironController = TextEditingController();
  final zincController = TextEditingController();
  final sodiumController = TextEditingController();
  final magnesiumController = TextEditingController();
  final vitaminAController = TextEditingController();
  final potassiumController = TextEditingController();
  final mufaController = TextEditingController();

  File? selectedImage;
  bool uploading = false;

  double parseValue(TextEditingController c) {
    if (c.text.trim().isEmpty) return 0;
    return double.tryParse(c.text.trim()) ?? 0;
  }

  @override
  void initState() {
    super.initState();

    if (widget.food != null) {

      final f = widget.food!;

      nameController.text = f.name;
      englishController.text = f.englishName ?? "";
      imageController.text = f.image ?? "";

      calController.text = f.calories.toString();
      proteinController.text = f.protein.toString();
      fatController.text = f.fat.toString();
      carbController.text = f.carb.toString();

      calciumController.text = f.calcium.toString();
      ironController.text = f.iron.toString();
      zincController.text = f.zinc.toString();
      sodiumController.text = f.sodium.toString();
      magnesiumController.text = f.magnesium.toString();
      vitaminAController.text = f.vitaminA.toString();
      potassiumController.text = f.potassium.toString();
      mufaController.text = f.mufaPufa.toString();
    }
  }

  /// =========================================================
  /// PICK IMAGE
  /// =========================================================

  Future<void> pickAndUploadImage() async {

    final picker = ImagePicker();

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 75,
    );

    if (picked == null) return;

    setState(() {
      uploading = true;
      selectedImage = File(picked.path);
    });

    try {

      String fileName =
          "foods/${DateTime.now().millisecondsSinceEpoch}.jpg";

      final ref =
      FirebaseStorage.instance.ref().child(fileName);

      await ref.putFile(selectedImage!);

      String url = await ref.getDownloadURL();

      imageController.text = url;

      Notifier.showNotify(context, "Upload ảnh thành công");

    } catch (e) {

      Notifier.showError(context, "Upload ảnh thất bại");

    }

    setState(() {
      uploading = false;
    });
  }

  /// =========================================================
  /// SAVE FOOD
  /// =========================================================

  Future<void> saveFood() async {

    try {

      final data = {

        "name": nameController.text.trim(),
        "englishName": englishController.text.trim(),
        "image": imageController.text.trim(),

        "calories": parseValue(calController),
        "protein": parseValue(proteinController),
        "fat": parseValue(fatController),
        "carb": parseValue(carbController),

        "calcium": parseValue(calciumController),
        "iron": parseValue(ironController),
        "zinc": parseValue(zincController),
        "sodium": parseValue(sodiumController),
        "magnesium": parseValue(magnesiumController),
        "vitaminA": parseValue(vitaminAController),
        "potassium": parseValue(potassiumController),
        "mufaPufa": parseValue(mufaController),
      };

      if (widget.food == null) {

        await FirebaseFirestore.instance
            .collection("food")
            .add(data);

        Notifier.showNotify(context, "Thêm món ăn thành công");

      } else {

        await FirebaseFirestore.instance
            .collection("food")
            .doc(widget.food!.id)
            .update(data);

        Notifier.showNotify(context, "Cập nhật món ăn thành công");
      }

      Navigator.pop(context);

    } catch (e) {

      Notifier.showError(context, "Lưu món ăn thất bại");

    }
  }

  /// =========================================================
  /// INPUT
  /// =========================================================

  Widget input(String title, TextEditingController controller,
      {TextInputType type = TextInputType.text}) {

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE0F2F1)),
      ),

      child: TextField(
        controller: controller,
        keyboardType: type,
        decoration: InputDecoration(
          hintText: title,
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget imageInput() {

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE0F2F1)),
      ),

      child: TextField(
        controller: imageController,

        decoration: InputDecoration(
          hintText: "Link hình ảnh",
          border: InputBorder.none,

          suffixIcon: uploading
              ? const Padding(
            padding: EdgeInsets.all(12),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.upload),
            onPressed: pickAndUploadImage,
          ),
        ),
      ),
    );
  }

  /// =========================================================
  /// UI
  /// =========================================================

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      /// FIX: bỏ AppBar → dùng header giống FoodManagementScreen
      body: Container(

        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE4FFE4), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

        child: SafeArea(

          child: Column(

            children: [

              const SizedBox(height: 10),

              /// FIX: HEADER giống trang quản lý món ăn
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),

                child: Row(
                  children: [

                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.chevron_left, size: 28),
                    ),

                    Expanded(
                      child: Center(
                        child: Text(
                          widget.food == null
                              ? "Thêm món ăn"
                              : "Chỉnh sửa món ăn",
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 28),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              /// FORM
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    children: [

                      input("Tên món ăn", nameController),
                      input("Tên tiếng Anh", englishController),

                      imageInput(),

                      const SizedBox(height: 10),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Macros",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 10),

                      input("Calories", calController,
                          type: TextInputType.number),

                      input("Protein (g)", proteinController,
                          type: TextInputType.number),

                      input("Fat (g)", fatController,
                          type: TextInputType.number),

                      input("carb (g)", carbController,
                          type: TextInputType.number),

                      const SizedBox(height: 10),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Vi chất dinh dưỡng",
                          style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),

                      const SizedBox(height: 10),

                      input("Calcium", calciumController,
                          type: TextInputType.number),

                      input("Iron", ironController,
                          type: TextInputType.number),

                      input("Zinc", zincController,
                          type: TextInputType.number),

                      input("Sodium", sodiumController,
                          type: TextInputType.number),

                      input("Magnesium", magnesiumController,
                          type: TextInputType.number),

                      input("Vitamin A", vitaminAController,
                          type: TextInputType.number),

                      input("Potassium", potassiumController,
                          type: TextInputType.number),

                      input("MUFA + PUFA", mufaController,
                          type: TextInputType.number),

                      const SizedBox(height: 20),

                      GestureDetector(
                        onTap: saveFood,

                        child: Container(
                          height: 50,
                          width: double.infinity,

                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF79EEF2),
                                Color(0xFF78F09C),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(25),
                          ),

                          alignment: Alignment.center,

                          child: const Text(
                            "LƯU MÓN ĂN",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}