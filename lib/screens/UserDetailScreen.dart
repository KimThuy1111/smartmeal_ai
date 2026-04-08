import 'package:flutter/material.dart';

import '../../controllers/UserController.dart';
import '../../models/User.dart';
import '../../utils/notifier.dart';

class UserDetailScreen extends StatefulWidget {
  final User user;

  const UserDetailScreen({super.key, required this.user});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  final UserController _controller = UserController();

  String role = 'user';

  @override
  void initState() {
    super.initState();
    role = widget.user.role;
  }

  // Cập nhật role người dùng trên hệ thống và quay lại màn trước khi thành công.
  Future<void> _updateRole() async {
    try {
      await _controller.updateUserRole(
        uid: widget.user.uid,
        role: role,
      );

      Notifier.showNotify(context, 'Cập nhật role thành công');
      Navigator.pop(context);
    } catch (e) {
      Notifier.showError(context, 'Cập nhật thất bại');
    }
  }

  // Hiển thị một dòng thông tin người dùng theo dạng nhãn - giá trị.
  Widget _infoTile(String title, String value) {
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          Text(value),
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
                          'Chi tiết người dùng',
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
                      _infoTile('Age', u.age.toString()),
                      _infoTile('Weight', '${u.weight} kg'),
                      _infoTile('Height', '${u.height} cm'),
                      _infoTile('Gender', u.gender),
                      _infoTile('Activity', u.activity),
                      _infoTile('Goal', u.goal),
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
                              'Role',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            DropdownButton<String>(
                              value: role,
                              items: const [
                                DropdownMenuItem(
                                  value: 'user',
                                  child: Text('User'),
                                ),
                                DropdownMenuItem(
                                  value: 'admin',
                                  child: Text('Admin'),
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
                        onTap: _updateRole,
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
                            'CẬP NHẬT ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
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
}