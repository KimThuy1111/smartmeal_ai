import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import '../controllers/UserController.dart';
import '../utils/notifier.dart';
import '../widgets/BackgroundGradient.dart';
import '../widgets/Footer.dart';
import 'ChangePasswordScreen.dart';
import 'EditProfileScreen.dart';
import 'LoginScreen.dart';

class UserProfileScreen extends StatefulWidget {
  final bool showFooter;

  const UserProfileScreen({
    super.key,
    this.showFooter = true,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserController _controller = UserController();

  String name = 'Người dùng';
  String email = '';
  String avatarUrl = 'https://cdn-icons-png.flaticon.com/512/149/149071.png';
  bool _isAvatarHovered = false;
  bool _isUpdatingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Tải dữ liệu hồ sơ người dùng và cập nhật thông tin hiển thị.
  Future<void> _loadUserProfile() async {
    final data = await _controller.getUserProfile();

    if (data != null) {
      setState(() {
        name = data['name'] ?? 'Người dùng';
        email = data['email'] ?? '';
        avatarUrl =
            data['avatar'] ?? 'https://cdn-icons-png.flaticon.com/512/149/149071.png';
      });
    }
  }

  // Đăng xuất tài khoản hiện tại và quay về màn hình đăng nhập.
  Future<void> _logout() async {
    await _controller.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // Chọn ảnh từ thư viện và cập nhật avatar cho người dùng.
  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();

      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (picked == null) {
        return;
      }

      setState(() {
        _isUpdatingAvatar = true;
      });

      final url = await _controller.uploadAvatar(File(picked.path));

      if (!mounted) {
        return;
      }

      if (url != null) {
        setState(() {
          avatarUrl = url;
        });

        Notifier.showNotify(context, 'Đổi avatar thành công');
      } else {
        Notifier.showError(context, 'Đổi avatar thất bại');
      }
    } catch (e) {
      if (mounted) {
        final message = e.toString().replaceFirst('Exception: ', '');
        Notifier.showError(context, message);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingAvatar = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: widget.showFooter ? const Footer(currentIndex: 3) : null,
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
                                'Hồ sơ của bạn',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
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
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            MouseRegion(
                              onEnter: (_) {
                                setState(() {
                                  _isAvatarHovered = true;
                                });
                              },
                              onExit: (_) {
                                setState(() {
                                  _isAvatarHovered = false;
                                });
                              },
                              child: GestureDetector(
                                onTap: _isUpdatingAvatar ? null : _pickAndUploadAvatar,
                                child: SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      CircleAvatar(
                                        radius: 40,
                                        backgroundImage: NetworkImage(avatarUrl),
                                      ),
                                      if (_isUpdatingAvatar)
                                        Positioned.fill(
                                          child: ClipOval(
                                            child: Container(
                                              color: Colors.black.withOpacity(0.35),
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      if (_isAvatarHovered && !_isUpdatingAvatar)
                                        Positioned(
                                          right: -2,
                                          bottom: -2,
                                          child: Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: const BoxDecoration(
                                              color: Colors.black87,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
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
                          'Cài đặt chung',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildOptionItem(
                        icon: Icons.edit,
                        text: 'Chỉnh sửa thông tin ',
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const EditProfileScreen(),
                            ),
                          );

                          _loadUserProfile();
                        },
                      ),
                      _buildOptionItem(
                        icon: Icons.password,
                        text: 'Thay đổi mật khẩu',
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
                      _buildOptionItem(
                        icon: Icons.logout,
                        text: 'Đăng xuất',
                        color: Colors.red,
                        onTap: _logout,
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

  // Tạo item cài đặt dùng chung cho các thao tác trong hồ sơ người dùng.
  Widget _buildOptionItem({
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
                    fontWeight:
                        text == 'Đăng xuất' ? FontWeight.bold : FontWeight.normal,
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