import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../controllers/FoodCategoryController.dart';
import '../../models/Food.dart';
import '../../utils/notifier.dart';
import '../../controllers/FoodController.dart';

class FoodFormScreen extends StatefulWidget {

  final Food? food;

  const FoodFormScreen({super.key, this.food});

  @override
  State<FoodFormScreen> createState() => _FoodFormScreenState();
}

class _FoodFormScreenState extends State<FoodFormScreen> {

  final FoodController _controller = FoodController();
  final FoodCategoryController _categoryController =
  FoodCategoryController();

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
  String? selectedCategoryId;
  bool loadingCategories = true;

  Map<String, String> categoryMap = {};

  double parseValue(TextEditingController c) {
    if (c.text.trim().isEmpty) return 0;
    return double.tryParse(c.text.trim()) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    selectedCategoryId = widget.food?.categoryId;
    loadCategories();

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

  Future<void> loadCategories() async {
    try {
      final list = await _categoryController.getAllCategories();
      final tempMap = <String, String>{};

      for (var cat in list) {
        final name = cat.name.trim();
        if (name.isNotEmpty) {
          tempMap[cat.id] = name;
        }
      }

      if (mounted) {
        setState(() {
          categoryMap = tempMap;
          loadingCategories = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          loadingCategories = false;
        });
      }
    }
  }

  /// Chọn và tải ảnh lên
  Future<void> pickAndUploadImage() async {
    try {
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

      final url = await _controller.uploadImage(selectedImage!);

      if (url != null && url.isNotEmpty) {
        imageController.text = url;
        Notifier.showNotify(context, "Upload ảnh thành công");
      } else {
        Notifier.showError(context, "Upload ảnh thất bại");
      }
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      Notifier.showError(context, message);
    } finally {
      if (mounted) {
        setState(() {
          uploading = false;
        });
      }
    }
  }

  /// Lưu món ăn
  Future<void> saveFood() async {

    try {
      if (selectedCategoryId == null || selectedCategoryId!.trim().isEmpty) {
        Notifier.showError(context, "Vui lòng chọn phân loại món ăn");
        return;
      }

      String imageUrl = imageController.text.trim();

      // 🔥 Nếu có chọn ảnh mới → upload lại
      if (selectedImage != null) {
        final uploadedUrl = await _controller.uploadImage(selectedImage!);
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          imageUrl = uploadedUrl;
        }
      }

      final data = {

        "name": nameController.text.trim(),
        "englishName": englishController.text.trim(),
        "image": imageUrl,
        "categoryId": selectedCategoryId,

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

        await _controller.addFood(data);

        Notifier.showNotify(context, "Thêm món ăn thành công");

      } else {

        await _controller.updateFood(widget.food!.id, data);

        Notifier.showNotify(context, "Cập nhật món ăn thành công");
      }

      Navigator.pop(context);

    } catch (e) {

      Notifier.showError(context, "Lưu món ăn thất bại");

    }
  }

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
    return Column(
      children: [

        if (imageController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageController.text,
                height: 120,
                width: 120,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image_not_supported),
              ),
            ),
          ),

        Container(
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
        ),
      ],
    );
  }

  Widget categoryInput() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE0F2F1)),
      ),
      child: loadingCategories
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text("Đang tải phân loại..."),
                ],
              ),
            )
          : DropdownButtonHideUnderline(
              child: ButtonTheme(
                alignedDropdown: true,
                child: DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text("Chọn phân loại"),
                  value: selectedCategoryId,
                  items: categoryMap.entries
                      .map(
                        (entry) => DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            entry.value,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCategoryId = value;
                    });
                  },
                ),
              ),
            ),
    );
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
          child: Column(
            children: [

              const SizedBox(height: 10),

              /// Thanh tiêu đề
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

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    children: [

                      /// Thông tin cơ bản
                      input("Tên món ăn", nameController),
                      input("Tên tiếng Anh", englishController),
                      categoryInput(),

                      imageInput(),

                      const SizedBox(height: 10),

                      /// Chỉ số dinh dưỡng chính
                      input("Calories", calController,
                          type: TextInputType.number),
                      input("Protein", proteinController,
                          type: TextInputType.number),
                      input("Fat", fatController,
                          type: TextInputType.number),
                      input("Carb", carbController,
                          type: TextInputType.number),

                      const SizedBox(height: 10),

                      /// Chỉ số dinh dưỡng bổ sung
                      input("Calcium", calciumController,
                          type: const TextInputType.numberWithOptions(
                            decimal: true,
                          )),
                      input("Iron", ironController,
                          type: const TextInputType.numberWithOptions(
                            decimal: true,
                          )),
                      input("Zinc", zincController,
                          type: const TextInputType.numberWithOptions(
                            decimal: true,
                          )),
                      input("Sodium", sodiumController,
                          type: const TextInputType.numberWithOptions(
                            decimal: true,
                          )),
                      input("Magnesium", magnesiumController,
                          type: const TextInputType.numberWithOptions(
                            decimal: true,
                          )),
                      input("Vitamin A", vitaminAController,
                          type: const TextInputType.numberWithOptions(
                            decimal: true,
                          )),
                      input("Potassium", potassiumController,
                          type: const TextInputType.numberWithOptions(
                            decimal: true,
                          )),
                      input("MUFA + PUFA", mufaController,
                          type: const TextInputType.numberWithOptions(
                            decimal: true,
                          )),

                      const SizedBox(height: 20),

                      /// Nút lưu món ăn
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