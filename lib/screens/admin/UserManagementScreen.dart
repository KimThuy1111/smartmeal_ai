import 'package:flutter/material.dart';

import '../../models/User.dart';
import '../../widgets/UserItemCard.dart';
import '../UserDetailScreen.dart';
import '../../controllers/UserController.dart';
import 'UserManagementStatsScreen.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState
    extends State<UserManagementScreen> {

  final UserController _controller = UserController();
  final int itemsPerPage = 10;

  List<User> allUsers = [];
  bool loading = true;
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadAllUsers();
  }

  // Tải tất cả người dùng từ hệ thống
  Future<void> _loadAllUsers() async {
    try {
      final users = await _controller.getAllUsers();
      setState(() {
        allUsers = users;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  // Tính tổng số trang
  int get totalPages {
    if (allUsers.isEmpty) return 1;
    return (allUsers.length + itemsPerPage - 1) ~/ itemsPerPage;
  }

  // Lấy danh sách người dùng của trang hiện tại
  List<User> get currentPageUsers {
    final startIndex = currentPage * itemsPerPage;
    final endIndex = (startIndex + itemsPerPage > allUsers.length)
        ? allUsers.length
        : startIndex + itemsPerPage;
    return allUsers.sublist(startIndex, endIndex);
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

              // Thanh tiêu đề
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
                          "Quản lý người dùng",
                          style: TextStyle(
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

              const SizedBox(height: 10),

              // Nút xem thống kê
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                ),

                child: Align(

                  alignment: Alignment.centerRight,

                  child: GestureDetector(

                    onTap: () {

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                          const UserManagementStatsScreen(),
                        ),
                      );
                    },

                    child: const Row(

                      mainAxisSize: MainAxisSize.min,

                      children: [

                        Text(
                          'Xem thống kê',

                          style: TextStyle(
                            color: Color(0xFF00A86B),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        SizedBox(width: 4),

                        Icon(
                          Icons.arrow_forward_ios,
                          size: 13,
                          color: Color(0xFF00A86B),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              const SizedBox(height: 10),

              // Danh sách người dùng
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : allUsers.isEmpty
                    ? const Center(
                  child: Text('Không có người dùng nào'),
                )
                    : ListView.builder(
                  padding: const EdgeInsets.all(14),
                  itemCount: currentPageUsers.length,
                  itemBuilder: (context, index) {
                    final user = currentPageUsers[index];

                    return UserItemCard(
                      avatar: user.avatar,
                      name: user.name,
                      email: user.email,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UserDetailScreen(user: user),
                          ),
                        ).then((_) => _loadAllUsers());
                      },
                    );
                  },
                ),
              ),

              // Phân trang
              if (allUsers.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Nút trang trước
                      GestureDetector(
                        onTap: currentPage > 0
                            ? () {
                          setState(() => currentPage--);
                        }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: currentPage > 0
                                ? Colors.green
                                : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Trước',
                            style: TextStyle(
                              color: currentPage > 0
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),

                      // Thông tin trang
                      Text(
                        'Trang ${currentPage + 1} / $totalPages',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      // Nút trang sau
                      GestureDetector(
                        onTap: currentPage < totalPages - 1
                            ? () {
                          setState(() => currentPage++);
                        }
                            : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: currentPage < totalPages - 1
                                ? Colors.green
                                : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Sau',
                            style: TextStyle(
                              color: currentPage < totalPages - 1
                                  ? Colors.white
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
