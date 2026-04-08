import '../services/UserService.dart';
import '../models/User.dart';
import 'dart:io';

class UserController {

  final UserService _service = UserService();

  // Lấy dữ liệu người dùng
  Future<Map<String, dynamic>?> getUserData() async {
    return await _service.getUserData();
  }

  // Cập nhật hồ sơ người dùng
  Future<void> updateUser({
    required String name,
    required String age,
    required String weight,
    required String height,
    required String gender,
    required String activity,
    required String goal,
  }) async {

    if (name.isEmpty) {
      throw Exception("Tên không được để trống");
    }

    if (age.isEmpty || weight.isEmpty || height.isEmpty) {
      throw Exception("Thiếu thông tin cơ bản");
    }

    int ageInt = int.parse(age);
    double weightDouble = double.parse(weight);
    double heightDouble = double.parse(height);

    if (ageInt <= 0 || weightDouble <= 0 || heightDouble <= 0) {
      throw Exception("Dữ liệu không hợp lệ");
    }

    await _service.updateUser(
      name: name,
      age: ageInt,
      weight: weightDouble,
      height: heightDouble,
      gender: gender,
      activity: activity,
      goal: goal,
    );
  }

  // Tạo hồ sơ người dùng
  Future<void> createUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    await _service.createUserProfile(uid: uid, data: data);
  }

  // Cập nhật vai trò người dùng
  Future<void> updateUserRole({
    required String uid,
    required String role,
  }) async {
    await _service.updateUserRole(uid: uid, role: role);
  }

  // Tải ảnh đại diện mới và cập nhật hồ sơ người dùng.
  Future<String?> uploadAvatar(File file) async {
    return await _service.uploadAvatar(file);
  }

  // Lấy hồ sơ người dùng
  Future<Map<String, dynamic>?> getUserProfile() async {
    return await _service.getUserProfile();
  }

  // Đăng xuất
  Future<void> logout() async {
    await _service.logout();
  }

  // Lấy tất cả người dùng
  Future<List<User>> getAllUsers() async {
    return await _service.getAllUsers();
  }

  // Lấy thống kê người dùng
  Future<Map<String, dynamic>> getUserStats({
    required String type,
    required int month,
    required int year,
  }) async {

    return await _service.getUserStats(
      type: type,
      month: month,
      year: year,
    );
  }

  // Lấy danh sách người dùng theo thời gian
  Future<List<User>> getUsersByTime({
    required String type,
    required int month,
    required int year,
  }) async {

    return await _service.getUsersByTime(
      type: type,
      month: month,
      year: year,
    );
  }

}