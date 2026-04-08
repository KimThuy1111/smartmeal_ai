import 'package:flutter/material.dart';

import '../../controllers/FoodCategoryController.dart';
import '../../models/FoodCategory.dart';
import '../../utils/notifier.dart';
import 'CategoryFormScreen.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() => _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final FoodCategoryController _controller = FoodCategoryController();

  List<FoodCategory> categories = [];
  List<FoodCategory> filteredCategories = [];
  bool loading = true;
  bool isSearching = false;

  int currentPage = 0;
  final int pageSize = 10;

  double fabX = 300;
  double fabY = 450;

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final list = await _controller.getAllCategories();

    setState(() {
      categories = list;
      filteredCategories = list;
      loading = false;
      currentPage = 0;
    });
  }

  Future<void> deleteCategory(FoodCategory category) async {
    try {
      await _controller.deleteCategory(category.id);
      Notifier.showNotify(context, "Xóa phân loại thành công");
      loadCategories();
    } catch (e) {
      Notifier.showError(context, "Không thể xóa phân loại");
    }
  }

  void searchCategory(String keyword) {
    final value = keyword.trim().toLowerCase();
    setState(() {
      filteredCategories = categories.where((c) {
        return c.name.toLowerCase().contains(value);
      }).toList();
      currentPage = 0;
    });
  }

  List<FoodCategory> get paginatedCategories {
    int start = currentPage * pageSize;
    int end = start + pageSize;

    if (start >= filteredCategories.length) return [];
    if (end > filteredCategories.length) {
      end = filteredCategories.length;
    }

    return filteredCategories.sublist(start, end);
  }

  int get totalPages {
    if (filteredCategories.isEmpty) {
      return 1;
    }
    return (filteredCategories.length / pageSize).ceil();
  }

  Future<void> confirmDelete(FoodCategory category) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa phân loại"),
        content: Text("Bạn có chắc muốn xóa '${category.name}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Xóa",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteCategory(category);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
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
                        const SizedBox(width: 10),
                        Expanded(
                          child: isSearching
                              ? TextField(
                                  controller: searchController,
                                  autofocus: true,
                                  onChanged: searchCategory,
                                  decoration: InputDecoration(
                                    hintText: "Lọc phân loại...",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                    ),
                                  ),
                                )
                              : const Center(
                                  child: Text(
                                    "Quản lý phân loại món ăn",
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSearching) {
                                isSearching = false;
                                searchController.clear();
                                filteredCategories = categories;
                              } else {
                                isSearching = true;
                              }
                              currentPage = 0;
                            });
                          },
                          child: Icon(
                            isSearching ? Icons.close : Icons.search,
                            size: 26,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : filteredCategories.isEmpty
                            ? const Center(
                                child: Text("Không có phân loại"),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: paginatedCategories.length,
                                itemBuilder: (context, index) {
                                  final category = paginatedCategories[index];

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE4FFF1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: const Icon(
                                            Icons.category,
                                            color: Color(0xFF00C569),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            category.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        PopupMenuButton<int>(
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          itemBuilder: (context) => [
                                            const PopupMenuItem(
                                              value: 1,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.edit),
                                                  SizedBox(width: 10),
                                                  Text("Chỉnh sửa"),
                                                ],
                                              ),
                                            ),
                                            const PopupMenuItem(
                                              value: 2,
                                              child: Row(
                                                children: [
                                                  Icon(Icons.delete),
                                                  SizedBox(width: 10),
                                                  Text(
                                                    "Xóa",
                                                    style: TextStyle(color: Colors.red),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                          onSelected: (value) {
                                            if (value == 1) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => CategoryFormScreen(
                                                    category: category,
                                                  ),
                                                ),
                                              ).then((_) => loadCategories());
                                            }

                                            if (value == 2) {
                                              confirmDelete(category);
                                            }
                                          },
                                          child: const Icon(Icons.more_vert),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                  if (!loading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: currentPage > 0
                                ? () {
                                    setState(() {
                                      currentPage--;
                                    });
                                  }
                                : null,
                          ),
                          Text(
                            "Trang ${currentPage + 1} / $totalPages",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: currentPage < totalPages - 1
                                ? () {
                                    setState(() {
                                      currentPage++;
                                    });
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: fabX,
            top: fabY,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  fabX += details.delta.dx;
                  fabY += details.delta.dy;
                });
              },
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CategoryFormScreen(),
                    ),
                  ).then((_) => loadCategories());
                },
                child: const Icon(
                  Icons.add_circle,
                  color: Color(0xFF00C569),
                  size: 50,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
