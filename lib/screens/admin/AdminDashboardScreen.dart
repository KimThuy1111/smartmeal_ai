import 'package:flutter/material.dart';
import '../../controllers/AdminController.dart';
import '../../controllers/UserController.dart';
import 'UserManagementScreen.dart';
import '../UserProfileScreen.dart';
import 'FoodManagementScreen.dart';
import '../LoginScreen.dart';
import 'MenuFeedbackScreen.dart';
import 'CategoryManagementScreen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {

  final AdminController _controller = AdminController();
  final UserController _userController = UserController();

  int totalFoods = 0;
  int totalUsers = 0;
  int totalCategories = 0;

  String avatarUrl =
      "https://cdn-icons-png.flaticon.com/512/149/149071.png";
  String name = "Admin";
  String email = "";

  @override
  void initState() {
    super.initState();
    loadStats();
    loadAdminProfile();
  }

  Future<void> loadStats() async {

    final result = await _controller.loadStats();

    setState(() {
      totalFoods = result["totalFoods"] ?? 0;
      totalUsers = result["totalUsers"] ?? 0;
      totalCategories = result["totalCategories"] ?? 0;
    });
  }

  Future<void> loadAdminProfile() async {

    final data = await _controller.getAdminProfile();

    if (data != null) {
      setState(() {
        name = data["name"] ?? "Admin";
        email = data["email"] ?? "";
        avatarUrl = data["avatar"] ??
            "https://cdn-icons-png.flaticon.com/512/149/149071.png";
      });
    }
  }

  Future<void> logout() async {
    await _userController.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
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
          child: SingleChildScrollView(
            child: Column(
              children: [

                const SizedBox(height: 10),

                // Phần tiêu đề
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                  children: [

                    const Expanded(
                      child: Text(
                        "Admin Dashboard",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    PopupMenuButton<int>(

                      offset: const Offset(0, 45),

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),

                      itemBuilder: (context) => [

                        PopupMenuItem(
                          enabled: false,
                          child: Row(
                            children: [

                              CircleAvatar(
                                radius: 18,
                                backgroundImage:
                                NetworkImage(avatarUrl),
                              ),

                              const SizedBox(width: 10),

                              Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),

                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),

                        const PopupMenuDivider(),

                        const PopupMenuItem(
                          value: 1,
                          child: Row(
                            children: [
                              Icon(Icons.person),
                              SizedBox(width: 10),
                              Text("Thông tin tài khoản"),
                            ],
                          ),
                        ),

                        const PopupMenuItem(
                          value: 2,
                          child: Row(
                            children: [
                              Icon(Icons.logout,
                                  color: Colors.red),
                              SizedBox(width: 10),
                              Text(
                                "Đăng xuất",
                                style:
                                TextStyle(color: Colors.red),
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
                              builder: (_) =>
                              const UserProfileScreen(
                                  showFooter: false),
                            ),
                          );
                        }

                        if (value == 2) {
                          logout();
                        }
                      },

                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage:
                        NetworkImage(avatarUrl),
                      ),
                    )

                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Các thống kê nhanh
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly,
                  children: [

                    statCard(
                      title: "Món ăn",
                      value: totalFoods.toString(),
                      icon: Icons.restaurant,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const FoodManagementScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 16),

                    statCard(
                      title: "Người dùng",
                      value: totalUsers.toString(),
                      icon: Icons.people,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const UserManagementScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 16),

                    statCard(
                      title: "Phân loại",
                      value: totalCategories.toString(),
                      icon: Icons.category,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const CategoryManagementScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Các mục quản lý chính
              menuCard(
                title: "Quản lý món ăn",
                icon: Icons.fastfood,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const FoodManagementScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              menuCard(
                title: "Quản lý phân loại món ăn",
                icon: Icons.category,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const CategoryManagementScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              menuCard(
                title: "Quản lý người dùng",
                icon: Icons.people,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const UserManagementScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

                menuCard(
                  title: "Đánh giá thực đơn AI",
                  icon: Icons.analytics,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const MenuFeedbackScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
  }) {

    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: 150,
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6)
          ],
        ),

        child: Column(
          children: [

            Icon(icon,
                size: 40,
                color: const Color(0xFF00C569)),

            const SizedBox(height: 10),

            Text(
              value,
              style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold),
            ),

            Text(title),
          ],
        ),
      ),
    );
  }

  Widget menuCard({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {

    return GestureDetector(
      onTap: onTap,

      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 6)
          ],
        ),

        child: Row(
          children: [

            Icon(icon,
                color: const Color(0xFF00C569),
                size: 30),

            const SizedBox(width: 16),

            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 16)
          ],
        ),
      ),
    );
  }
}