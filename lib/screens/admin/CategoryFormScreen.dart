import 'package:flutter/material.dart';

import '../../controllers/FoodCategoryController.dart';
import '../../models/FoodCategory.dart';
import '../../utils/notifier.dart';

class CategoryFormScreen extends StatefulWidget {
  final FoodCategory? category;

  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final FoodCategoryController _controller = FoodCategoryController();
  final TextEditingController nameController = TextEditingController();

  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.category?.name ?? "";
  }

  Future<void> saveCategory() async {
    try {
      setState(() {
        saving = true;
      });

      if (widget.category == null) {
        await _controller.addCategory(nameController.text);
        Notifier.showNotify(context, "Thêm phân loại thành công");
      } else {
        await _controller.updateCategory(
          widget.category!.id,
          nameController.text,
        );
        Notifier.showNotify(context, "Cập nhật phân loại thành công");
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      final message = e.toString().replaceFirst("Exception: ", "");
      Notifier.showError(context, message);
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
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
          child: Column(
            children: [
              const SizedBox(height: 10),
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
                          widget.category == null
                              ? "Thêm phân loại"
                              : "Chỉnh sửa phân loại",
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
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: const Color(0xFFE0F2F1)),
                        ),
                        child: TextField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            hintText: "Tên phân loại",
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: saving ? null : saveCategory,
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
                          child: saving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Text(
                                  "LƯU PHÂN LOẠI",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
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
