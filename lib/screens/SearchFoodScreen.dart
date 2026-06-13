import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smartmeal_ai/controllers/FoodController.dart';
import 'package:smartmeal_ai/screens/FoodDiaryScreen.dart';

import '../models/Food.dart';
import '../models/FoodCategory.dart';
import '../utils/notifier.dart';
import '../widgets/FoodItemCard.dart';
import 'FoodDetailScreen.dart';
import 'SuggestMealScreen.dart';

class SearchFoodScreen extends StatefulWidget {
  const SearchFoodScreen({super.key});

  @override
  State<SearchFoodScreen> createState() => _SearchFoodScreenState();
}

class _SearchFoodScreenState extends State<SearchFoodScreen> {
  final FoodController _controller = FoodController();
  final TextEditingController searchController = TextEditingController();

  List<Food> foods = [];
  int currentPage = 0;
  final int pageSize = 10;
  bool isLoading = true;
  Timer? _debounce;
  int get totalPages => (foods.length / pageSize).ceil();

  @override
  void initState() {
    super.initState();
    _loadTopFoods();
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Tải danh sách món ăn nổi bật khi vừa mở trang
  Future<void> _loadTopFoods() async {
    setState(() => isLoading = true);

    // Truy vấn dữ liệu món ăn nổi bật
    final result = await _controller.getTopFoods(15);

    setState(() {
      foods = result;
      isLoading = false;
    });
  }

  //Tìm kiếm món ăn theo từ khóa
  void _searchFood(String keyword) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    // Đợi 400ms sau khi người dùng ngừng gõ mới query
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final value = keyword.trim();

      if (value.isEmpty) {
        // Nếu xóa từ khóa, tải lại danh sách nổi bật
        _loadTopFoods();
        return;
      }
      setState(() => isLoading = true);

      // Truy vấn tìm kiếm từ khóa
      final result = await _controller.searchFood(value);

      setState(() {
        foods = result;
        isLoading = false;
      });
    });
  }

  // Lấy danh sách món ăn của trang hiện tại dựa trên kích thước trang
  List<Food> get _paginatedFoods {
    final int start = currentPage * pageSize;
    int end = start + pageSize;

    if (start >= foods.length) {
      return [];
    }

    if (end > foods.length) {
      end = foods.length;
    }

    return foods.sublist(start, end);
  }

  // Thêm món vào bữa đã chọn
  Future<void> _addFoodToDiary(Food food, String meal) async {
    try {
      // Lưu món ăn vào nhật ký
      await _controller.addFoodToDiary(foodId: food.id, meal: meal);

      // Thông báo "Thêm món ăn thành công"
      Notifier.showNotify(context, 'Thêm thành công');

      // Chuyển sang màn hình nhật ký ăn uống
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => FoodDiaryScreen(),
        ),
      );
    } catch (e) {
      // Hiển thị lỗi hệ thống
      Notifier.showError(context, 'Lỗi khi thêm món ăn');
    }
  }

  // Hiển thị cửa sổ chọn bữa ăn
  void _showMealPickerDialog(Food food) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Chọn buổi ăn'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _mealButton('Bữa sáng', 'breakfast', food),
            _mealButton('Bữa trưa', 'lunch', food),
            _mealButton('Bữa tối', 'dinner', food),
          ],
        ),
      ),
    );
  }

  // Chọn bữa ăn
  Widget _mealButton(String title, String value, Food food) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        // Gọi hàm thêm vào nhật ký
        _addFoodToDiary(food, value);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE4FFE4),
      body: Column(
        children: [
          const SizedBox(height: 24),
          // Header: Nút quay lại + Tiêu đề
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.chevron_left),
              ),
              const Expanded(
                child: Center(
                  child: Text(
                    'Tra cứu món ăn',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
          // Search textfield
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: _searchFood,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm món ăn...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Danh sách món ăn
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : foods.isEmpty
                ? const Center(child: Text('Không có dữ liệu'))
                : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _paginatedFoods.length,
                    itemBuilder: (_, i) =>
                        _buildFoodItem(_paginatedFoods[i]),
                  ),
                ),

                // Thanh phân trang
                if (totalPages > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                    ),
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
                          'Trang ${currentPage + 1}/$totalPages',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed:
                          currentPage < totalPages - 1
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
        ],
      ),
    );
  }

  // Hiển thị item món ăn
  Widget _buildFoodItem(Food food) {
    return FoodItemCard(
      id: food.id,
      name: food.name,
      image: food.image,
      calories: food.calories,
      // Chọn món cần xem
      onTap: () {
        // Chuyển sang màn hình chi tiết
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodDetailScreen(foodId: food.id),
          ),
        );
      },
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: Colors.green),
        // Chọn icon (+) của món cần thêm vào nhật ký
        onPressed: () => _showMealPickerDialog(food),
      ),
    );
  }
}