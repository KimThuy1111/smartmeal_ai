import 'package:flutter/material.dart';
import '../../models/Food.dart';
import '../../widgets/FoodItemCard.dart';
import '../FoodDetailScreen.dart';
import 'FoodFormScreen.dart';
import '../../controllers/FoodController.dart';
import '../../controllers/FoodCategoryController.dart';
import '../../models/FoodCategory.dart';

class FoodManagementScreen extends StatefulWidget {
  const FoodManagementScreen({super.key});

  @override
  State<FoodManagementScreen> createState() =>
      _FoodManagementScreenState();
}

class _FoodManagementScreenState
    extends State<FoodManagementScreen> {

  final FoodController _controller = FoodController();
  final FoodCategoryController _categoryController =
  FoodCategoryController();

  List<Food> foods = [];
  bool loading = true;
  List<FoodCategory> categories = [];
  bool loadingCategories = true;

  int currentPage = 0;
  final int pageSize = 10;

  double fabX = 300;
  double fabY = 450;

  bool isSearching = false;
  TextEditingController searchController =
  TextEditingController();
  List<Food> filteredFoods = [];
  String selectedCategoryId = "all";

  @override
  void initState() {
    super.initState();
    loadCategories();
    loadFoods();
  }

  Future<void> loadCategories() async {
    final list = await _categoryController.getAllCategories();
    if (!mounted) return;

    setState(() {
      categories = list;
      loadingCategories = false;
    });
    applyFilters();
  }

  // Tải toàn bộ danh sách món ăn từ hệ thống
  Future<void> loadFoods() async {
    foods = await _controller.getAllFoods();
    if (!mounted) return;

    setState(() {
      loading = false;
    });
    applyFilters();
  }

  void applyFilters() {
    final keyword = searchController.text.trim().toLowerCase();

    setState(() {
      filteredFoods = foods.where((food) {
        final matchesSearch = food.name.toLowerCase().contains(keyword) ||
            (food.englishName ?? "").toLowerCase().contains(keyword);

        final matchesCategory = selectedCategoryId == "all" ||
            food.categoryId == selectedCategoryId;

        return matchesSearch && matchesCategory;
      }).toList();

      currentPage = 0;
    });
  }

  /// Hiển thị hộp thoại xác nhận xóa
  Future<bool> showDeleteConfirmDialog() async {

    final result = await showDialog<bool>(

      context: context,

      builder: (context) {

        return AlertDialog(

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Row(
            children: [

              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red,
              ),

              SizedBox(width: 10),

              Text("Xác nhận xóa"),
            ],
          ),

          content: const Text(
            "Bạn có chắc muốn xóa món ăn này không?",
            style: TextStyle(fontSize: 15),
          ),

          actions: [

            /// Nút hủy
            TextButton(

              onPressed: () {

                Navigator.pop(context, false);
              },

              child: const Text(
                "Hủy",
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

            /// Nút xóa
            ElevatedButton(

              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

              onPressed: () {

                Navigator.pop(context, true);
              },

              child: const Text(
                "Xóa",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // Xóa một món ăn theo ID
  Future<void> deleteFood(String id) async {
    await _controller.deleteFood(id);
    loadFoods();
  }

  // Lọc món ăn theo từ khóa tìm kiếm
  void searchFood(String keyword) {
    applyFilters();
  }

  // Danh sách món ăn của trang hiện tại
  List<Food> get paginatedFoods {
    int start = currentPage * pageSize;
    int end = start + pageSize;

    if (start >= filteredFoods.length) return [];
    if (end > filteredFoods.length)
      end = filteredFoods.length;

    return filteredFoods.sublist(start, end);
  }

  // Tổng số trang hiện có
  int get totalPages =>
      (filteredFoods.length / pageSize).ceil();

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

                  // Thanh tiêu đề và ô tìm kiếm
                  Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 16),

                    child: Row(
                      children: [

                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.chevron_left,
                              size: 28),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: isSearching
                              ? TextField(
                            controller: searchController,
                            autofocus: true,
                            onChanged: searchFood,
                            decoration: InputDecoration(
                              hintText: "Tìm món ăn...",
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                              const EdgeInsets.symmetric(
                                  horizontal: 16),
                            ),
                          )
                              : const Center(
                            child: Text(
                              "Quản lý món ăn",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight:
                                FontWeight.bold,
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
                                applyFilters();

                              } else {

                                isSearching = true;

                              }

                            });

                          },

                          child: Icon(
                            isSearching
                                ? Icons.close
                                : Icons.search,
                            size: 26,
                          ),
                        ),

                        const SizedBox(width: 8),

                        GestureDetector(
                          onTap: loadingCategories
                              ? null
                              : () async {
                                  final value = await showModalBottomSheet<String>(
                                    context: context,
                                    backgroundColor: Colors.transparent,
                                    isScrollControlled: false,
                                    builder: (context) {
                                      return Container(
                                        margin: const EdgeInsets.all(12),
                                        padding: const EdgeInsets.only(top: 12, bottom: 20),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(24),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade300,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            const Text(
                                              "Chọn phân loại",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Flexible(
                                              child: ListView(
                                                shrinkWrap: true,
                                                children: [
                                                  ListTile(
                                                    title: const Text("Tất cả "),
                                                    onTap: () => Navigator.pop(context, "all"),
                                                  ),
                                                  ...categories.map((category) {
                                                    return ListTile(
                                                      title: Text(category.name),
                                                      onTap: () => Navigator.pop(context, category.id),
                                                    );
                                                  }),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  );

                                  if (value != null) {
                                    setState(() {
                                      selectedCategoryId = value;
                                    });
                                    applyFilters();
                                  }
                                },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              selectedCategoryId == "all"
                                  ? Icons.filter_list
                                  : Icons.filter_alt,
                              size: 26,
                              color: selectedCategoryId == "all"
                                  ? Colors.black87
                                  : const Color(0xFF00C569),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Danh sách món ăn
                  Expanded(
                    child: loading
                        ? const Center(
                        child:
                        CircularProgressIndicator())
                        : filteredFoods.isEmpty
                        ? const Center(
                      child: Text("Không có món ăn phù hợp"),
                    )
                        : ListView.builder(
                      padding:
                      const EdgeInsets.all(12),
                      itemCount:
                      paginatedFoods.length,

                      itemBuilder: (context, index) {

                        final food =
                        paginatedFoods[index];

                        return FoodItemCard(

                          id: food.id,
                          name: food.name,
                          image: food.image,
                          calories: food.calories,

                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FoodDetailScreen(
                                        foodId:
                                        food.id),
                              ),
                            );
                          },

                          trailing:
                          PopupMenuButton<int>(

                            shape:
                            RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  12),
                            ),

                            itemBuilder:
                                (context) => [

                              const PopupMenuItem(
                                value: 1,
                                child: Row(
                                  children: [
                                    Icon(Icons.edit),
                                    SizedBox(width: 10),
                                    Text(
                                        "Chỉnh sửa"),
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
                                      style: TextStyle(
                                          color:
                                          Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            onSelected: (value) async {

                              if (value == 1) {

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        FoodFormScreen(
                                            food:
                                            food),
                                  ),
                                ).then(
                                        (_) =>
                                        loadFoods());

                              }

                              if (value == 2)  {

                                /// Hiện hộp thoại xác nhận
                                final confirm =
                                    await showDeleteConfirmDialog();

                                /// Nếu người dùng bấm Hủy
                                if (!confirm) return;

                                /// Nếu đồng ý thì mới xóa
                                deleteFood(food.id);
                              }

                            },

                            child:
                            const Icon(Icons.more_vert),
                          ),
                        );
                      },
                    ),
                  ),

                  // Phân trang danh sách
                  if (!loading)
                    Padding(
                      padding:
                      const EdgeInsets.only(bottom: 10),

                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,

                        children: [

                          IconButton(
                            icon: const Icon(
                                Icons.chevron_left),
                            onPressed:
                            currentPage > 0
                                ? () {
                              setState(() {
                                currentPage--;
                              });
                            }
                                : null,
                          ),

                          Text(
                            "Trang ${currentPage + 1} / $totalPages",
                            style: const TextStyle(
                                fontWeight:
                                FontWeight.bold),
                          ),

                          IconButton(
                            icon: const Icon(
                                Icons.chevron_right),
                            onPressed:
                            currentPage <
                                totalPages - 1
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

          // Nút thêm món ăn
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
                      builder: (_) =>
                      const FoodFormScreen(),
                    ),
                  ).then((_) => loadFoods());

                },

                child: const Icon(
                  Icons.add_circle,
                  color: Color(0xFF00C569),
                  size: 50,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}