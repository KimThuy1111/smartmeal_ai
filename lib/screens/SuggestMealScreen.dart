import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../controllers/SuggestController.dart';
import '../controllers/UserController.dart';
import '../models/SuggestedMenu.dart';
import '../utils/notifier.dart';
import '../widgets/BackgroundGradient.dart';
import '../widgets/FoodItemCard.dart';
import '../widgets/Footer.dart';
import 'FoodDetailScreen.dart';

class SuggestMealScreen extends StatefulWidget {
  final String? addedFoodId;

  const SuggestMealScreen({super.key, this.addedFoodId});

  @override
  State<SuggestMealScreen> createState() => _SuggestMealScreenState();
}

class _SuggestMealScreenState extends State<SuggestMealScreen> {
  final SuggestController _controller = SuggestController();
  final UserController _userController = UserController();

  Map<String, List<Map<String, dynamic>>>? menu;
  Map<String, dynamic>? nutrition;

  bool isLoading = false;
  bool? liked;
  String? currentMenuDocId;

  Map<int, Map<String, dynamic>> foodCache = {};
  late DateTime selectedDate;
  late String today;
  
  // FIX: Track actual calorie intake to properly detect "enough calories"
  double totalCalories = 0;
  double targetCalories = 0;

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    today = selectedDate.toString().substring(0, 10);
    // 1. Mở màn hình gợi ý thực đơn
    _initData();
  }

  // 2.1 Lấy calories, chỉ số dinh dưỡng, lịch sử ăn / 2.3 Lấy calories, lịch sử món đã ăn
  // Khởi tạo dữ liệu thực đơn từ cache, Firestore hoặc gọi API khi cần.
  Future<void> _initData() async {
    // FIX: Load today's actual calorie intake first
    await _loadTodayCalories();
    
    if (_controller.isCacheValid(today)) {
      setState(() {
        menu = _controller.cachedMenu;
      });
      return;
    }

    await _loadMenuFromFirestore();

    if (menu == null) {
      await _fetchMenu();
      return;
    }

    if (widget.addedFoodId != null && menu != null) {
      if (!_isFoodInMenu(widget.addedFoodId!)) {
        await _fetchMenu();
      }
    }
  }

  // 2.3 Lấy calories, lịch sử món đã ăn
  // FIX: Load today's actual calorie intake from food diary
  Future<void> _loadTodayCalories() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final db = FirebaseFirestore.instance;
      
      // 7.2 So sánh với lượng calo khuyến nghị
      // Lấy mục tiêu calories của người dùng
      final userDoc = await db.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      if (userData != null && userData['nutrition'] != null) {
        final nutrition = userData['nutrition'];
        targetCalories = (nutrition['Calories'] ?? 0).toDouble();
      }

      // 7.1 Tính tổng calo tiêu thụ
      // Lấy lượng calories đã tiêu thụ vào nhật ký món ăn hôm nay
      final snapshot = await db
          .collection('food_diary')
          .where('userId', isEqualTo: user.uid)
          .where('date', isEqualTo: today)
          .get();

      totalCalories = 0;
      for (var doc in snapshot.docs) {
        final foodId = doc['foodId'];
        final foodDoc = await db.collection('food').doc(foodId).get();
        if (foodDoc.exists) {
          final calories = (foodDoc.data()?['calories'] ?? 0).toDouble();
          totalCalories += calories;
        }
      }

      setState(() {});
    } catch (e) {
      print('Error loading today calories: $e');
    }
  }

  // 2.2 Lấy dữ liệu từ Firebase Storage
  // Tải thực đơn gần nhất trong ngày của người dùng từ Firestore.
  Future<void> _loadMenuFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    setState(() => isLoading = true);

    final snapshot = await FirebaseFirestore.instance
        .collection('suggested_menus')
        .where('userId', isEqualTo: user.uid)
        .where('date', isEqualTo: today)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      setState(() {
        isLoading = false;
        liked = null;
        currentMenuDocId = null;
      });
      return;
    }

    final doc = snapshot.docs.first;
    currentMenuDocId = doc.id;
    
    final Map<String, List<Map<String, dynamic>>> loadedMenu = {
      'Breakfast': [],
      'Lunch': [],
      'Dinner': [],
    };

    final suggested = SuggestedMenu.fromMap(doc.data());

    for (final String meal in suggested.menu.keys) {
      final futures = suggested.menu[meal]!.map((id) {
        return FirebaseFirestore.instance.collection('food').doc(id).get();
      }).toList();

      final docs = await Future.wait(futures);

      for (final d in docs) {
        if (!d.exists) {
          continue;
        }

        final data = d.data()!;
        data['id'] = d.id;
        loadedMenu[meal]!.add(data);
      }
    }

    _controller.setCache(loadedMenu, today);

    if (!mounted) {
      return;
    }

    setState(() {
      menu = loadedMenu;
      liked = suggested.liked;
      isLoading = false;
    });
  }

  // 3. Kiểm tra lượng calo đã ăn trong ngày / 4. Gọi API gợi ý thực đơn mới, map dữ liệu đầy đủ và lưu lại.
  Future<void> _fetchMenu() async {
    setState(() => isLoading = true);

    // 4.1 Lấy calories đã tiêu thụ trong từng bữa
    final calories = await _controller.loadTodayCalories();
    // Lấy danh sách STT các món đã ăn trong 3 ngày qua
    final recentHistory = await _controller.loadRecentFoodHistory();
    final userData = await _userController.getUserData();
    final excludedFoods = await _controller.getExcludedFoods();

    // 4.2 Gửi yêu cầu đến API
    final data = await _controller.fetchMenu(
      userData!,
      calories['breakfast'] ?? 0,
      calories['lunch'] ?? 0,
      calories['dinner'] ?? 0,
      recentHistory, // Gửi lịch sử ăn uống thực tế
      excludedFoods,
    );

    if (data.isEmpty) {
      // 3a. Hiển thị "Lỗi kết nối"
      setState(() => isLoading = false);
      return;
    }

    // 5. Phân tích dữ liệu dinh dưỡng và lịch sử ăn uống để tạo thực đơn phù hợp
    // 6. Nhận thực đơn từ API
    final aiMenu = data['menu'];
    final Map<String, List<Map<String, dynamic>>> fullMenu = {};

    for (final String meal in ['Breakfast', 'Lunch', 'Dinner']) {
      final List items = aiMenu[meal] ?? [];
      final List<Map<String, dynamic>> foods = [];

      for (final item in items) {
        final snapshot = await FirebaseFirestore.instance
            .collection('food')
            .where('stt', isEqualTo: item['stt'])
            .limit(1)
            .get();

        if (snapshot.docs.isEmpty) {
          continue;
        }

        final doc = snapshot.docs.first;
        final data = doc.data();
        data['id'] = doc.id;
        foods.add(data);
      }

      fullMenu[meal] = foods;
    }

    // 7.1 Tạo instance để lưu trữ
    // 7.2 Trả về instance / 7.3 Lưu dữ liệu
    final docId = await _controller.saveMenu(fullMenu);
    if (docId != null) {
      _controller.setCache(fullMenu, today);
    } else {
      // 7a. Hiển thị "Lưu thất bại"
      Notifier.showError(context, 'Lưu thất bại');
    }

    if (!mounted) {
      return;
    }

    // 8. Hiển thị danh sách thực đơn
    setState(() {
      menu = fullMenu;
      currentMenuDocId = docId;
      liked = null;
      isLoading = false;
    });
  }

  // Kiểm tra thực đơn hiện tại có đủ 3 bữa hay không.
  bool _hasFullMeal() {
    return menu != null &&
        menu!['Breakfast']!.isNotEmpty &&
        menu!['Lunch']!.isNotEmpty &&
        menu!['Dinner']!.isNotEmpty;
  }

  // Kiểm tra thực đơn có ít nhất một món ăn.
  bool _hasMenuFood() {
    return menu != null && menu!.values.any((m) => m.isNotEmpty);
  }

  // Kiểm tra món ăn vừa thêm đã xuất hiện trong thực đơn hay chưa.
  bool _isFoodInMenu(String id) {
    return menu != null && menu!.values.any((m) => m.any((f) => f['id'] == id));
  }

  // Gửi đánh giá thích/không thích cho thực đơn đang hiển thị.
  Future<void> _rateMenu(bool like) async {
    if (currentMenuDocId == null) {
      Notifier.showNotify(context, 'Không tìm thấy thực đơn để đánh giá');
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('suggested_menus')
          .doc(currentMenuDocId)
          .update({'liked': like});

      setState(() => liked = like);
      Notifier.showNotify(context, 'Đã gửi đánh giá');
    } catch (_) {
      Notifier.showNotify(context, 'Gửi đánh giá thất bại');
    }
  }

  // 3a.2 Thêm món vào bữa được gợi ý
  Future<void> _addFood(String id, String meal) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    // 5.1 Lưu món ăn vào nhật ký
    // 5.2 Ghi dữ liệu món ăn
    await FirebaseFirestore.instance.collection('food_diary').add({
      'userId': user.uid,
      'foodId': id,
      'meal': meal,
      'date': today,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // 6. Thông báo "Thêm món ăn thành công"
    Notifier.showNotify(context, 'Đã thêm vào nhật ký');
  }

  // Điều hướng đến ngày trước đó
  void _goToPreviousDay() {
    setState(() {
      selectedDate = selectedDate.subtract(const Duration(days: 1));
      today = selectedDate.toString().substring(0, 10);
      menu = null;
      liked = null;
      currentMenuDocId = null;
    });
    _loadMenuFromFirestore();
  }

  // Điều hướng đến ngày sau đó
  void _goToNextDay() {
    final now = DateTime.now();
    if (selectedDate.isBefore(DateTime(now.year, now.month, now.day))) {
      setState(() {
        selectedDate = selectedDate.add(const Duration(days: 1));
        today = selectedDate.toString().substring(0, 10);
        menu = null;
        liked = null;
        currentMenuDocId = null;
      });
      _loadMenuFromFirestore();
    }
  }

  // Kiểm tra xem có thể chuyển sang ngày sau không
  bool _canGoToNextDay() {
    final now = DateTime.now();
    return selectedDate.isBefore(DateTime(now.year, now.month, now.day));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const Footer(currentIndex: 2),
      body: BackgroundGradient(
        child: SafeArea(
          child: Column(
            children: [
              // Header với nút điều hướng
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 20),
                      onPressed: _goToPreviousDay,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Text(
                            'Gợi ý thực đơn',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _formatDate(selectedDate),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios, size: 20),
                      onPressed: _canGoToNextDay() ? _goToNextDay : null,
                    ),
                  ],
                ),
              ),
              // Refresh button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.sync),
                      onPressed: _fetchMenu,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : menu == null
                        ? const Center(child: Text('Không có dữ liệu'))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                const Text(
                                  'Các món chỉ mang tính tham khảo',
                                  style: TextStyle(color: Colors.red),
                                ),
                                _buildMeal('Bữa sáng', menu!['Breakfast']!, 'breakfast'),
                                _buildMeal('Bữa trưa', menu!['Lunch']!, 'lunch'),
                                _buildMeal('Bữa tối', menu!['Dinner']!, 'dinner'),
                                if (!_hasMenuFood())
                                  const Padding(
                                    padding: EdgeInsets.only(top: 40),
                                    child: Text('Bạn đã ăn đủ calo 🎉'),
                                  ),
                                if (_hasFullMeal())
                                  Padding(
                                    padding: const EdgeInsets.only(top: 32, bottom: 16),
                                    child: _buildRatingButtons(),
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

  // Định dạng ngày
  String _formatDate(DateTime date) {
    final months = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12'
    ];
    final days = ['Thứ 2', 'Thứ 3', 'Thứ 4', 'Thứ 5', 'Thứ 6', 'Thứ 7', 'Chủ nhật'];
    return '${date.day} ${months[date.month - 1]}, ${days[date.weekday - 1]}';
  }

  // Xây dựng nút đánh giá thích/không thích
  Widget _buildRatingButtons() {
    if (liked != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: liked! ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
          border: Border.all(
            color: liked! ? Colors.green : Colors.red,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              liked! ? Icons.favorite : Icons.thumb_down,
              color: liked! ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              liked! ? 'Thực đơn này phù hợp với bạn' : 'Thực đơn này thực sự phù hợp với bạn',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: liked! ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Nút Thích
          InkWell(
            onTap: () => _rateMenu(true),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0x9979EEF2), Color(0x9978F09C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.cyan.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Phù hợp',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Nút Không thích
          InkWell(
            onTap: () => _rateMenu(false),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[400]!, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.thumb_down_outlined, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Không phù hợp',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Hiển thị danh sách món ăn cho từng bữa trong thực đơn gợi ý.
  Widget _buildMeal(String title, List foods, String meal) {
    if (foods.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        ...foods.map((f) {
          return FoodItemCard(
            id: f['id'],
            name: f['name'],
            image: f['image'],
            calories: f['calories'].toDouble(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FoodDetailScreen(foodId: f['id']),
                ),
              );
            },
            trailing: IconButton(
              icon: const Icon(Icons.add_circle, color: Colors.green),
              onPressed: () => _addFood(f['id'], meal),
            ),
          );
        }),
      ],
    );
  }
}