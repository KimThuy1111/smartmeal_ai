import 'dart:async';

import 'package:flutter/material.dart';
import 'package:smartmeal_ai/controllers/FoodController.dart';

import '../models/Food.dart';
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

  // Tải danh sách món ăn phổ biến để hiển thị mặc định.
  Future<void> _loadTopFoods() async {
    setState(() => isLoading = true);

    final result = await _controller.getTopFoods(10);

    setState(() {
      foods = result;
      currentPage = 0;
      isLoading = false;
    });
  }

  // Tìm món ăn theo từ khóa với debounce để giảm số lần gọi API.
  void _searchFood(String keyword) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final value = keyword.trim();

      if (value.isEmpty) {
        _loadTopFoods();
        return;
      }

      setState(() => isLoading = true);

      final result = await _controller.searchFood(value);

      setState(() {
        foods = result;
        currentPage = 0;
        isLoading = false;
      });
    });
  }

  // Lấy danh sách món ăn theo trang hiện tại.
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

  // Thêm món ăn vào nhật ký theo buổi ăn đã chọn và điều hướng sang gợi ý món.
  Future<void> _addFoodToDiary(Food food, String meal) async {
    try {
      await _controller.addFoodToDiary(
        foodId: food.id,
        meal: meal,
      );

      Notifier.showNotify(context, 'Thêm thành công');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuggestMealScreen(addedFoodId: food.id),
        ),
      );
    } catch (e) {
      Notifier.showError(context, 'Lỗi khi thêm món ăn');
    }
  }

  // Hiển thị hộp thoại cho người dùng chọn buổi ăn.
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

  // Tạo một lựa chọn buổi ăn trong hộp thoại và gọi hàm lưu nhật ký.
  Widget _mealButton(String title, String value, Food food) {
    return ListTile(
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
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
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : foods.isEmpty
                ? const Center(child: Text('Không có dữ liệu'))
                : ListView.builder(
                    itemCount: _paginatedFoods.length,
                    itemBuilder: (_, i) => _buildFoodItem(_paginatedFoods[i]),
                  ),
          ),
        ],
      ),
    );
  }

  // Hiển thị item món ăn và các thao tác xem chi tiết/thêm vào nhật ký.
  Widget _buildFoodItem(Food food) {
    return FoodItemCard(
      id: food.id,
      name: food.name,
      image: food.image,
      calories: food.calories,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodDetailScreen(foodId: food.id),
          ),
        );
      },
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: Colors.green),
        onPressed: () => _showMealPickerDialog(food),
      ),
    );
  }
}