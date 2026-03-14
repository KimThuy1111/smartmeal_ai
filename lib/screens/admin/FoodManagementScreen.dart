import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/Food.dart';
import 'FoodFormScreen.dart';
import '../../screens/SearchFoodScreen.dart';

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

  List<Food> get paginatedFoods {

    int start = currentPage * pageSize;
    int end = start + pageSize;

    if (start >= foods.length) return [];

    if (end > foods.length) end = foods.length;

    return foods.sublist(start, end);
  }

  int get totalPages =>
      (foods.length / pageSize).ceil();

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

                        const Expanded(
                          child: Center(
                            child: Text(
                              "Quản lý món ăn",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        /// SEARCH BUTTON
                        GestureDetector(
                          onTap: () {

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SearchFoodScreen(),
                              ),
                            );

                          },
                          child: const Icon(Icons.search, size: 26),
                        ),

                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  /// LIST FOOD
                  Expanded(
                    child: loading
                        ? const Center(
                        child: CircularProgressIndicator())
                        : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: paginatedFoods.length,
                      itemBuilder: (context, index) {

                        final food = paginatedFoods[index];

                        return Card(
                          elevation: 3,
                          margin:
                          const EdgeInsets.only(bottom: 12),

                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),

                          child: ListTile(

                            leading: ClipRRect(
                              borderRadius:
                              BorderRadius.circular(8),

                              child: SizedBox(
                                width: 60,
                                height: 60,
                                child: food.image != null
                                    ? Image.network(
                                  food.image!,
                                  fit: BoxFit.cover,
                                )
                                    : const Icon(Icons.fastfood),
                              ),
                            ),

                            title: Text(
                              food.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),

                            subtitle: Text(
                                "${food.calories.toStringAsFixed(0)} cal"),

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

          /// FLOAT BUTTON giống Home
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