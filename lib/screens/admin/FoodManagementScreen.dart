import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/Food.dart';
import '../../component/FoodItemCard.dart';
import '../FoodDetailScreen.dart';
import 'FoodFormScreen.dart';

class FoodManagementScreen extends StatefulWidget {
  const FoodManagementScreen({super.key});

  @override
  State<FoodManagementScreen> createState() => _FoodManagementScreenState();
}

class _FoodManagementScreenState extends State<FoodManagementScreen> {

  List<Food> foods = [];
  bool loading = true;

  int currentPage = 0;
  final int pageSize = 10;

  double fabX = 300;
  double fabY = 450;

  /// FIX: biến search
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<Food> filteredFoods = [];

  @override
  void initState() {
    super.initState();
    loadFoods();
  }

  Future<void> loadFoods() async {

    final snapshot =
    await FirebaseFirestore.instance.collection("food").get();

    foods = snapshot.docs
        .map((e) => Food.fromMap(e.data(), e.id))
        .toList();

    /// FIX: ban đầu hiển thị toàn bộ
    filteredFoods = foods;

    setState(() {
      loading = false;
    });
  }

  Future<void> deleteFood(String id) async {

    await FirebaseFirestore.instance
        .collection("food")
        .doc(id)
        .delete();

    loadFoods();
  }

  /// FIX: search trong danh sách
  void searchFood(String keyword) {

    final value = keyword.toLowerCase();

    setState(() {

      filteredFoods = foods.where((food) {

        return food.name.toLowerCase().contains(value) ||
            (food.englishName ?? "").toLowerCase().contains(value);

      }).toList();

      currentPage = 0;

    });
  }

  List<Food> get paginatedFoods {

    int start = currentPage * pageSize;
    int end = start + pageSize;

    if (start >= filteredFoods.length) return [];

    if (end > filteredFoods.length) end = filteredFoods.length;

    return filteredFoods.sublist(start, end);
  }

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

                  /// HEADER
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),

                    child: Row(
                      children: [

                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: const Icon(Icons.chevron_left, size: 28),
                        ),

                        const SizedBox(width: 10),

                        /// FIX: khi search thì hiện input
                        Expanded(
                          child: isSearching
                              ? TextField(

                            controller: searchController,
                            autofocus: true,
                            onChanged: searchFood,

                            decoration: InputDecoration(
                              hintText: "Tìm món ăn...",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                            ),
                          )
                              : const Center(
                            child: Text(
                              "Quản lý món ăn",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        /// FIX: icon search toggle
                        GestureDetector(

                          onTap: () {

                            setState(() {

                              if (isSearching) {

                                isSearching = false;
                                searchController.clear();
                                filteredFoods = foods;

                              } else {

                                isSearching = true;

                              }

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

                  /// LIST FOOD
                  Expanded(
                    child: loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: paginatedFoods.length,

                      itemBuilder: (context, index) {

                        final food = paginatedFoods[index];

                        return FoodItemCard(

                          id: food.id,
                          name: food.name,
                          image: food.image,
                          calories: food.calories,

                          /// mở trang chi tiết
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => FoodDetailScreen(foodId: food.id),
                              ),
                            );
                          },

                          /// menu edit / delete
                          trailing: PopupMenuButton<int>(

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
                                    builder: (_) => FoodFormScreen(food: food),
                                  ),
                                ).then((_) => loadFoods());

                              }

                              if (value == 2) {

                                deleteFood(food.id);

                              }

                            },

                            child: const Icon(Icons.more_vert),

                          ),
                        );
                      },
                    ),
                  ),

                  /// PAGINATION
                  if (!loading)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),

                      child: Row(
                        mainAxisAlignment:
                        MainAxisAlignment.center,

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
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
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

          /// FLOAT BUTTON
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
                      builder: (_) => const FoodFormScreen(),
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