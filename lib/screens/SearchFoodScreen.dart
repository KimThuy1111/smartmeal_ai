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
    // 1. Mở giao diện trang tra cứu món ăn
    _loadTopFoods();
  }

  @override
  void dispose() {
    searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // 2a.1 Yêu cầu lấy danh sách món ăn nổi bật
  // 2a.2 Xử lý yêu cầu
  Future<void> _loadTopFoods() async {
    setState(() => isLoading = true);

    // 2a.3 Truy vấn dữ liệu món ăn
    final result = await _controller.getTopFoods(10);

    setState(() {
      foods = result;
      currentPage = 0;
      isLoading = false;
    });
  }

  // 3.1 Yêu cầu tìm kiếm món ăn
  void _searchFood(String keyword) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    // 3.2 Xử lí yêu cầu tìm kiếm
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      final value = keyword.trim();

      if (value.isEmpty) {
        _loadTopFoods();
        return;
      }

      setState(() => isLoading = true);

      // 3.3 Truy vấn dữ liệu món ăn
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

  // 4.3 Thêm món vào bữa đã chọn / 3a.2 Thêm món vào bữa được gợi ý
  Future<void> _addFoodToDiary(Food food, String meal) async {
    try {
      // 5.1 Lưu món ăn vào nhật ký
      await _controller.addFoodToDiary(
        foodId: food.id,
        meal: meal,
      );

      // 6. Thông báo "Thêm món ăn thành công"
      Notifier.showNotify(context, 'Thêm thành công');
      // Chuyển sang màn hình gợi ý thực đơn
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuggestMealScreen(addedFoodId: food.id),
        ),
      );
    } catch (e) {
      // 5a. Hiển thị lỗi hệ thống
      Notifier.showError(context, 'Lỗi khi thêm món ăn');
    }
  }

  // 4.1 Hiển thị cửa sổ chọn bữa ăn
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

  // 4.2 Chọn bữa ăn và 4.3 Thêm món vào bữa đã chọn
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
            // 2. Nhập từ khóa tìm kiếm
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
                // 3a. Hiển thị không tìm thấy món phù hợp
                : foods.isEmpty
                ? const Center(child: Text('Không có dữ liệu'))
                // 4. Hiển thị danh sách món ăn
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
      // 5.1 Chọn món cần xem
      onTap: () {
        // 5.2 Chuyển sang màn hình chi tiết
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodDetailScreen(foodId: food.id),
          ),
        );
      },
      trailing: IconButton(
        icon: const Icon(Icons.add_circle, color: Colors.green),
        // 3. Chọn icon (+) của món cần thêm vào nhật ký / 3a Chọn icon (+) của món cần thêm vào nhật ký
        onPressed: () => _showMealPickerDialog(food),
      ),
    );
  }
}