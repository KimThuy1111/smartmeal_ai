import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/User.dart';
import '../../component/UserItemCard.dart';
import '../UserDetailScreen.dart';


class UserManagementScreen extends StatefulWidget {

  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState
    extends State<UserManagementScreen> {

  List<User> users = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {

    final snapshot =
    await FirebaseFirestore.instance.collection("users").get();

    users = snapshot.docs
        .map((e) => User.fromMap(e.data(), e.id))
        .toList();

    setState(() {
      loading = false;
    });
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

              /// USER LIST
              Expanded(

                child: loading
                    ? const Center(
                    child: CircularProgressIndicator())
                    : ListView.builder(

                  padding: const EdgeInsets.all(14),

                  itemCount: users.length,

                  itemBuilder: (context, index) {

                    final user = users[index];

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
                        ).then((_) => loadUsers());

                      },
                    );
                  },
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }
}