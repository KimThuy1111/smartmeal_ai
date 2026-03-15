import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/User.dart';
import '../../utils/notifier.dart';

class UserDetailScreen extends StatefulWidget {

  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() =>
      _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {

  String role = "user";

  @override
  void initState() {
    super.initState();
    role = widget.user.role;
  }

  Future<void> updateRole() async {

    try {

      await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.user.uid)
          .update({
        "role": role
      });

      Notifier.showNotify(context, "Cập nhật role thành công");

      Navigator.pop(context);

    } catch (e) {

      Notifier.showError(context, "Cập nhật thất bại");

    }
  }

  Widget infoTile(String title, String value) {

    return Container(

      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),

      child: Row(

        children: [

          Text(
            title,
            style: const TextStyle(
                fontWeight: FontWeight.bold),
          ),

          const Spacer(),

          Text(value)

        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    final u = widget.user;

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
                          "Chi tiết người dùng",
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

              const SizedBox(height: 20),

              CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(u.avatar),
              ),

              const SizedBox(height: 10),

              Text(
                u.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                u.email,
                style: const TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              Expanded(

                child: SingleChildScrollView(

                  padding: const EdgeInsets.all(20),

                  child: Column(

                    children: [

                      infoTile("Age", u.age.toString()),
                      infoTile("Weight", "${u.weight} kg"),
                      infoTile("Height", "${u.height} cm"),
                      infoTile("Gender", u.gender),
                      infoTile("Activity", u.activity),
                      infoTile("Goal", u.goal),

                      const SizedBox(height: 10),

                      Container(

                        padding: const EdgeInsets.all(14),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),

                        child: Row(

                          children: [

                            const Text(
                              "Role",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold),
                            ),

                            const Spacer(),

                            DropdownButton<String>(

                              value: role,

                              items: const [

                                DropdownMenuItem(
                                  value: "user",
                                  child: Text("User"),
                                ),

                                DropdownMenuItem(
                                  value: "admin",
                                  child: Text("Admin"),
                                ),

                              ],

                              onChanged: (v) {

                                setState(() {
                                  role = v!;
                                });

                              },

                            ),

                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      GestureDetector(

                        onTap: updateRole,

                        child: Container(

                          height: 50,
                          width: double.infinity,

                          decoration: BoxDecoration(

                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF79EEF2),
                                Color(0xFF78F09C),
                              ],
                            ),

                            borderRadius:
                            BorderRadius.circular(25),

                          ),

                          alignment: Alignment.center,

                          child: const Text(

                            "CẬP NHẬT ",

                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )

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
}