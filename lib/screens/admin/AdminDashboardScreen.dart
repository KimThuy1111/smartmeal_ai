import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../UserProfileScreen.dart';
import 'FoodManagementScreen.dart';
import '../LoginScreen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {

  int totalFoods = 0;
  int totalUsers = 0;

  String avatarUrl =
      "https://cdn-icons-png.flaticon.com/512/149/149071.png";
  String name = "Admin";
  String email = "";

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    loadStats();
    loadAdminProfile();
  }

  Future<void> loadStats() async {

    final foodSnap =
    await FirebaseFirestore.instance.collection("food").get();

    final userSnap =
    await FirebaseFirestore.instance.collection("users").get();

    setState(() {
      totalFoods = foodSnap.docs.length;
      totalUsers = userSnap.docs.length;
    });
  }

  Future<void> loadAdminProfile() async {

    final user = _auth.currentUser;

    if (user == null) return;

    final doc = await _db.collection("users").doc(user.uid).get();

    if (doc.exists) {
      setState(() {
        name = doc["name"] ?? "Admin";
        email = doc["email"] ?? "";
        avatarUrl = doc["avatar"] ??
            "https://cdn-icons-png.flaticon.com/512/149/149071.png";
      });
    }
  }

  void showAccountMenu() {

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),

      builder: (context) {

        return Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisSize: MainAxisSize.min,

            children: [

              CircleAvatar(
                radius: 40,
                backgroundImage: NetworkImage(avatarUrl),
              ),

              const SizedBox(height: 10),

              Text(
                name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),

              Text(
                email,
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  "Đăng xuất",
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () async {

                  await _auth.signOut();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                },
              ),

            ],
          ),
        );
      },
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

          child: Column(

            children: [

              const SizedBox(height: 10),

              /// HEADER
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
                                backgroundImage: NetworkImage(avatarUrl),
                              ),

                              const SizedBox(width: 10),

                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [

                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
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
                              Icon(Icons.logout, color: Colors.red),
                              SizedBox(width: 10),
                              Text(
                                "Đăng xuất",
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),

                      ],

                      onSelected: (value) async {

                        if (value == 1) {

                          // mở trang profile
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const UserProfileScreen(),
                            ),
                          );

                        }

                        if (value == 2) {

                          await FirebaseAuth.instance.signOut();

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                                (route) => false,
                          );
                        }
                      },

                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(avatarUrl),
                      ),
                    )

                  ],
                ),
              ),

              const SizedBox(height: 30),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [

                  statCard(
                    title: "Món ăn",
                    value: totalFoods.toString(),
                    icon: Icons.restaurant,
                  ),

                  statCard(
                    title: "Người dùng",
                    value: totalUsers.toString(),
                    icon: Icons.people,
                  ),
                ],
              ),

              const SizedBox(height: 30),

              menuCard(
                title: "Quản lý món ăn",
                icon: Icons.fastfood,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FoodManagementScreen(),
                    ),
                  );
                },
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget statCard({
    required String title,
    required String value,
    required IconData icon,
  }) {

    return Container(
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

          Icon(icon, size: 40, color: const Color(0xFF00C569)),

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