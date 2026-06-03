import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hoczita/data/datasources/local_datasource.dart';
import 'package:hoczita/data/repositories/auth_repository.dart';

void main() {
  late AuthRepository repo;

  setUp(() {
    // Dùng SharedPreferences giả lập (in-memory) cho test
    SharedPreferences.setMockInitialValues({});
    repo = AuthRepository(LocalDataSource());
  });

  group('AuthRepository — Đăng ký', () {
    test('đăng ký thành công trả về null (không có lỗi)', () async {
      final error = await repo.register(
        name: 'Nguyen Van A',
        email: 'a@gmail.com',
        password: '123456',
      );
      expect(error, isNull);
    });

    test('đăng ký trùng email trả về thông báo lỗi', () async {
      // Đăng ký lần 1
      await repo.register(
        name: 'Nguyen Van A',
        email: 'a@gmail.com',
        password: '123456',
      );
      // Đăng ký lại cùng email
      final error = await repo.register(
        name: 'Tran Thi B',
        email: 'a@gmail.com',
        password: 'abcdef',
      );
      expect(error, isNotNull);
      expect(error, contains('đã được đăng ký'));
    });

    test('đăng ký trùng email không phân biệt hoa thường', () async {
      await repo.register(
        name: 'User A',
        email: 'test@gmail.com',
        password: '123456',
      );
      final error = await repo.register(
        name: 'User B',
        email: 'TEST@GMAIL.COM',
        password: 'abcdef',
      );
      expect(error, isNotNull);
    });
  });

  group('AuthRepository — Đăng nhập', () {
    setUp(() async {
      // Tạo tài khoản trước
      await repo.register(
        name: 'Test User',
        email: 'user@test.com',
        password: 'password123',
      );
      // Logout để test login
      await repo.logout();
    });

    test('đăng nhập đúng email/password trả về null', () async {
      final error = await repo.login(
        email: 'user@test.com',
        password: 'password123',
      );
      expect(error, isNull);
    });

    test('đăng nhập sai password trả về thông báo lỗi', () async {
      final error = await repo.login(
        email: 'user@test.com',
        password: 'wrongpassword',
      );
      expect(error, isNotNull);
      expect(error, contains('không đúng'));
    });

    test('đăng nhập email không tồn tại trả về lỗi', () async {
      final error = await repo.login(
        email: 'notexist@test.com',
        password: '123456',
      );
      expect(error, isNotNull);
    });

    test('sau đăng nhập isLoggedIn() trả về true', () async {
      await repo.login(email: 'user@test.com', password: 'password123');
      final loggedIn = await repo.isLoggedIn();
      expect(loggedIn, isTrue);
    });

    test('sau logout isLoggedIn() trả về false', () async {
      await repo.login(email: 'user@test.com', password: 'password123');
      await repo.logout();
      final loggedIn = await repo.isLoggedIn();
      expect(loggedIn, isFalse);
    });
  });

  group('AuthRepository — Đổi mật khẩu', () {
    setUp(() async {
      await repo.register(
        name: 'Test User',
        email: 'user@test.com',
        password: 'oldpass',
      );
    });

    test('đổi mật khẩu đúng mật khẩu cũ thành công', () async {
      final user = await repo.getCurrentUser();
      final error = await repo.changePassword(
        userId: user!.id,
        oldPassword: 'oldpass',
        newPassword: 'newpass',
      );
      expect(error, isNull);
    });

    test('đổi mật khẩu sai mật khẩu cũ trả về lỗi', () async {
      final user = await repo.getCurrentUser();
      final error = await repo.changePassword(
        userId: user!.id,
        oldPassword: 'wrongold',
        newPassword: 'newpass',
      );
      expect(error, isNotNull);
      expect(error, contains('không đúng'));
    });

    test('sau đổi mật khẩu, đăng nhập bằng mật khẩu mới thành công', () async {
      final user = await repo.getCurrentUser();
      await repo.changePassword(
        userId: user!.id,
        oldPassword: 'oldpass',
        newPassword: 'newpass123',
      );
      await repo.logout();
      final error = await repo.login(
        email: 'user@test.com',
        password: 'newpass123',
      );
      expect(error, isNull);
    });
  });
}
