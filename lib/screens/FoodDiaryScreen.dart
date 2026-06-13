import 'package:flutter/material.dart';

import '../controllers/FoodDiaryController.dart';
import '../models/FoodDiary.dart';
import '../widgets/BackgroundGradient.dart';
import '../widgets/Footer.dart';
import 'FoodDetailScreen.dart';
import 'FoodDiaryStatsScreen.dart';
import 'SearchFoodScreen.dart';

class FoodDiaryScreen extends StatefulWidget {
  const FoodDiaryScreen({super.key});

  @override
  State<FoodDiaryScreen> createState() => _FoodDiaryScreenState();
}

class _FoodDiaryScreenState extends State<FoodDiaryScreen> {
  final FoodDiaryController _controller = FoodDiaryController();

  List<FoodDiary> breakfast = [];
  List<FoodDiary> lunch = [];
  List<FoodDiary> dinner = [];

  bool isOver = false;
  double totalCalories = 0;
  double targetCalories = 0;

  double fabX = 300;
  double fabY = 480;

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDiary();
  }
  // Tải dữ liệu nhật ký ăn uống theo ngày đang được chọn.
  Future<void> _loadDiary() async {
    final result = await _controller.loadDiary(selectedDate);
    setState(() {
      breakfast = result['breakfast'];
      lunch = result['lunch'];
      dinner = result['dinner'];
      totalCalories = result['totalCalories'];
      targetCalories = result['targetCalories'];
      isOver = result['isOver'];
    });
  }
  // Định dạng ngày hiển thị theo kiểu dd/mm/yyyy.
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // Mở bộ chọn ngày và tải lại nhật ký nếu người dùng chọn ngày mới.
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });

      _loadDiary();
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const Footer(currentIndex: 1),
      body: BackgroundGradient(
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Nhật ký ăn uống',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_month),
                          onPressed: _pickDate,
                        ),
                      ],
                    ),
                    Center(
                      child: Text(
                        _formatDate(selectedDate),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Container(
                        width: 165,
                        height: 165,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFF2FDF7),
                          border: Border.all(
                            color:
                                isOver ? Colors.red : const Color(0xFFC7EEDB),
                            width: 3,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              totalCalories.toStringAsFixed(0),
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('kcal consumed'),
                            const SizedBox(height: 6),
                            Text(
                              'Target: ${targetCalories.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    _buildMealSection('Bữa sáng', breakfast),
                    _buildMealSection('Bữa trưa', lunch),
                    _buildMealSection('Bữa tối', dinner),

                    const SizedBox(height: 12),

                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FoodDiaryStatsScreen(
                              initialDate: selectedDate,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        height: 50,
                        width: double.infinity,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF79EEF2), Color(0xFF78F09C)],
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Text(
                          'XEM THỐNG KÊ',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 120),
                  ],
                ),
              ),
              Positioned(
                left: fabX,
                top: fabY,
                child: GestureDetector(
                  // Cho phép kéo thả vị trí nút thêm món ăn trên màn hình.
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
                          builder: (_) => const SearchFoodScreen(),
                        ),
                      ).then((_) => _loadDiary());
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
        ),
      ),
    );
  }

  // Hiển thị danh sách món ăn cho một bữa cụ thể.
  Widget _buildMealSection(String title, List<FoodDiary> list) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        ...list.map((e) => _buildFoodItem(e)).toList(),
      ],
    );
  }

  // Tạo item món ăn và điều hướng sang màn hình chi tiết khi nhấn vào.
  Widget _buildFoodItem(FoodDiary item) {
    return GestureDetector(
      onLongPress: () => _showDeleteConfirmDialog(item),
      onSecondaryTap: () => _showFoodOptionsDialog(item),
      child: Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          leading: item.image != null && item.image!.isNotEmpty
              ? Image.network(
                  item.image!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.fastfood),
                )
              : const Icon(Icons.fastfood),
          title: Text(item.name),
          subtitle: Text('${item.calories.toStringAsFixed(0)} cal'),
          trailing: PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => _showFoodOptionsDialog(item),
                child: const Row(
                  children: [
                    Icon(Icons.edit, size: 18),
                    SizedBox(width: 8),
                    Text('Cập nhật'),
                  ],
                ),
              ),
              PopupMenuItem(
                onTap: () => _showDeleteConfirmDialog(item),
                child: const Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FoodDetailScreen(foodId: item.foodId),
              ),
            );
          },
        ),
      ),
    );
  }

  // Hiển thị hộp thoại xác nhận xóa món ăn
  void _showDeleteConfirmDialog(FoodDiary item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Xóa món ăn'),
          content: Text('Bạn có chắc muốn xóa ${item.name} khỏi nhật ký?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            TextButton(
              onPressed: () {
                _deleteFood(item);
                Navigator.pop(context);
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Xóa một món ăn khỏi nhật ký
  Future<void> _deleteFood(FoodDiary item) async {
    final dateString = selectedDate.toString().substring(0, 10);
    final success = await _controller.deleteFoodFromDiary(
      foodId: item.foodId,
      dateString: dateString,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa ${item.name} khỏi nhật ký'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadDiary();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Xóa thất bại'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Cho phép người dùng chọn thao tác muốn thực hiện
  void _showFoodOptionsDialog(FoodDiary item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('${item.name}'),
          children: [
            // Đổi bữa ăn (sáng/trưa/tối)
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _showUpdateMealDialog(item);
              },
              child: const Row(
                children: [
                  Icon(Icons.restaurant),
                  SizedBox(width: 12),
                  Text('Cập nhật bữa ăn'),
                ],
              ),
            ),
            // Đổi ngày ăn
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context);
                _showUpdateDateDialog(item);
              },
              child: const Row(
                children: [
                  Icon(Icons.calendar_today),
                  SizedBox(width: 12),
                  Text('Cập nhật ngày'),
                ],
              ),
            ),

            // Hủy
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  // Hiển thị hộp thoại chọn Bữa sáng, Bữa trưa, hoặc Bữa tối
  void _showUpdateMealDialog(FoodDiary item) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Đổi bữa ăn - ${item.name}'),
          children: [
            SimpleDialogOption(
              onPressed: () {
                _updateFoodMeal(item, 'breakfast');
                Navigator.pop(context);
              },
              child: const Text('Bữa sáng'),
            ),
            SimpleDialogOption(
              onPressed: () {
                _updateFoodMeal(item, 'lunch');
                Navigator.pop(context);
              },
              child: const Text('Bữa trưa'),
            ),
            SimpleDialogOption(
              onPressed: () {
                _updateFoodMeal(item, 'dinner');
                Navigator.pop(context);
              },
              child: const Text('Bữa tối'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  // Hiển thị bộ chọn ngày để cập nhật ngày ăn của món
  Future<void> _showUpdateDateDialog(FoodDiary item) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      // Người dùng chọn ngày mới khác với ngày hiện tại
      final oldDateString = selectedDate.toString().substring(0, 10);
      final newDateString = picked.toString().substring(0, 10);

      _updateFoodDate(item, oldDateString, newDateString);
    }
  }

  // Cập nhật bữa ăn của một món ăn
  Future<void> _updateFoodMeal(FoodDiary item, String newMeal) async {
    // Kiểm tra nếu bữa ăn mới trùng với bữa ăn hiện tại, không cần cập nhật
    if (newMeal == item.meal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã là bữa ăn hiện tại'), backgroundColor: Colors.orange, duration: Duration(seconds: 2)),
      );
      return;
    }
    final dateString = selectedDate.toString().substring(0, 10);
    final success = await _controller.updateFoodMeal(foodId: item.foodId, dateString: dateString, newMeal: newMeal);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã cập nhật bữa ăn ${item.name}'), backgroundColor: Colors.green, duration: const Duration(seconds: 2)),
      );
      _loadDiary();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật bữa ăn thất bại'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // Cập nhật ngày ăn của một món ăn
  Future<void> _updateFoodDate(FoodDiary item, String oldDateString, String newDateString) async {
    final success = await _controller.updateFoodDate(foodId: item.foodId, oldDateString: oldDateString, newDateString: newDateString);
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chuyển ${item.name} sang ngày ${newDateString.split('-')[2]}/${newDateString.split('-')[1]}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadDiary();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật ngày ăn thất bại'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}