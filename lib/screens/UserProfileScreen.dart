import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../component/Footer.dart';

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

  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }

  Future<void> loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc = await _db.collection("users").doc(user.uid).get();

    if (doc.exists) {
      setState(() {
        name = doc.data()?["name"] ?? "Người dùng";
        email = doc.data()?["email"] ?? "";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F6),
      bottomNavigationBar: const Footer(currentIndex: 3),

      body: SafeArea(
        child: Column(
          children: [

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [

                    const SizedBox(height: 20),

                    const Text(
                      "Hồ sơ của bạn",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 24),

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

                          const CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.grey,
                            child: Icon(Icons.person, size: 40, color: Colors.white),
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

                          const Icon(Icons.edit),
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
                      icon: Icons.flag,
                      text: "Mục tiêu sức khỏe",
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Chưa làm")),
                        );
                      },
                    ),

                    buildOptionItem(
                      icon: Icons.settings,
                      text: "Cài đặt ứng dụng",
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Chưa làm")),
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
                        Navigator.pop(context);
                      },
                    ),

                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget buildOptionItem({
    required IconData icon,
    required String text,
    Color color = Colors.black,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                      fontWeight: text == "Đăng xuất" ? FontWeight.bold : FontWeight.normal,
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
      ),
    );
  }
}