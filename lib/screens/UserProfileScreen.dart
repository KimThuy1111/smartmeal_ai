import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../component/BackgroundGradient.dart';
import '../component/Footer.dart';
import 'ChangePasswordScreen.dart';
import 'EditProfileScreen.dart';
import 'LoginScreen.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String name = "Người dùng";
  String email = "";
  String avatarUrl =
      "https://cdn-icons-png.flaticon.com/512/149/149071.png";
  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }
  // Load dữ liệu user từ Firestore
  Future<void> loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final doc = await _db.collection("users").doc(user.uid).get();
    if (doc.exists) {
      setState(() {
        name = doc.data()?["name"] ?? "Người dùng";
        email = doc.data()?["email"] ?? "";
        avatarUrl = doc.data()?["avatar"] ??
            "https://cdn-icons-png.flaticon.com/512/149/149071.png";
      });
    }
  }

  //UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: const Footer(currentIndex: 3),

      body: BackgroundGradient(
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Row(
                        children: [

                          /// BACK BUTTON
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(context);
                            },
                            child: const Icon(
                              Icons.chevron_left,
                              size: 28,
                            ),
                          ),

                          const Expanded(
                            child: Center(
                              child: Text(
                                "Hồ sơ của bạn",
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          /// để cân layout
                          const SizedBox(width: 28),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(avatarUrl),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    email,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Cài đặt chung",
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      buildOptionItem(
                        icon: Icons.edit,
                        text: "Chỉnh sửa thông tin ",
                        onTap: () async {

                          // mở màn hình chỉnh sửa
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );

                          // reload lại dữ liệu sau khi chỉnh sửa
                          loadUserProfile();
                        },
                      ),
                      buildOptionItem(
                        icon: Icons.password,
                        text: "Thay đổi mật khẩu",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ChangePasswordScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                      buildOptionItem(
                        icon: Icons.logout,
                        text: "Đăng xuất",
                        color: Colors.red,
                        onTap: () async {

                          await _auth.signOut();

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                                (route) => false,
                          );

                        },
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
  // Tạo item trong danh sách cài đặt
  Widget buildOptionItem({
    required IconData icon,
    required String text,
    Color color = Colors.black,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,

        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Row(
            children: [

              Icon(icon, color: color),

              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: text == "Đăng xuất"
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: color,
                  ),
                ),
              ),

              const Icon(
                Icons.chevron_right,
                size: 20,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}