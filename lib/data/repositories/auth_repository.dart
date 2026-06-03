import 'package:uuid/uuid.dart';
import '../datasources/local_datasource.dart';
import '../models/user_model.dart';

class AuthRepository {
  final LocalDataSource _local;
  final _uuid = const Uuid();

  AuthRepository(this._local);

  Future<bool> isLoggedIn() => _local.isLoggedIn();

  Future<UserModel?> getCurrentUser() => _local.getCurrentUser();

  /// Đăng ký tài khoản mới
  Future<String?> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final users = await _local.getAllUsers();

    // Kiểm tra email đã tồn tại chưa
    final exists = users.any((u) => u.email.toLowerCase() == email.toLowerCase());
    if (exists) return 'Email này đã được đăng ký';

    final newUser = UserModel(
      id: _uuid.v4(),
      name: name,
      email: email,
      password: password,
      createdAt: DateTime.now(),
    );

    await _local.saveUser(newUser);
    await _local.login(newUser);
    return null; // null = thành công
  }

  /// Đăng nhập
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final users = await _local.getAllUsers();
    try {
      final user = users.firstWhere(
        (u) =>
            u.email.toLowerCase() == email.toLowerCase() &&
            u.password == password,
      );
      await _local.login(user);
      return null; // null = thành công
    } catch (_) {
      return 'Email hoặc mật khẩu không đúng';
    }
  }

  Future<void> logout() => _local.logout();

  /// Cập nhật thông tin cá nhân
  Future<void> updateProfile({
    required String userId,
    String? name,
    String? avatarPath,
  }) async {
    final user = await _local.getCurrentUser();
    if (user == null) return;
    final updated = user.copyWith(name: name, avatarPath: avatarPath);
    await _local.saveUser(updated);
  }

  /// Đổi mật khẩu
  Future<String?> changePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    final user = await _local.getCurrentUser();
    if (user == null) return 'Không tìm thấy tài khoản';
    if (user.password != oldPassword) return 'Mật khẩu cũ không đúng';
    final updated = user.copyWith(password: newPassword);
    await _local.saveUser(updated);
    return null;
  }
}
