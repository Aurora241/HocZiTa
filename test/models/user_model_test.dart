import 'package:flutter_test/flutter_test.dart';
import 'package:hoczita/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    final now = DateTime(2026, 6, 1);

    final user = UserModel(
      id: 'abc-123',
      name: 'Nguyen Van A',
      email: 'a@gmail.com',
      password: '123456',
      avatarPath: null,
      createdAt: now,
    );

    test('toJson trả về đúng Map', () {
      final json = user.toJson();
      expect(json['id'], 'abc-123');
      expect(json['name'], 'Nguyen Van A');
      expect(json['email'], 'a@gmail.com');
      expect(json['password'], '123456');
      expect(json['avatarPath'], isNull);
    });

    test('fromJson tạo đúng UserModel', () {
      final json = user.toJson();
      final restored = UserModel.fromJson(json);
      expect(restored.id, user.id);
      expect(restored.name, user.name);
      expect(restored.email, user.email);
      expect(restored.password, user.password);
      expect(restored.avatarPath, user.avatarPath);
    });

    test('fromJson -> toJson -> fromJson giữ nguyên dữ liệu (round-trip)', () {
      final json1 = user.toJson();
      final user2 = UserModel.fromJson(json1);
      final json2 = user2.toJson();
      expect(json1, json2);
    });

    test('copyWith chỉ thay đổi field được chỉ định', () {
      final updated = user.copyWith(name: 'Tran Thi B');
      expect(updated.name, 'Tran Thi B');
      expect(updated.email, user.email);   // không đổi
      expect(updated.id, user.id);         // không đổi
    });

    test('copyWith avatar cập nhật đúng', () {
      final updated = user.copyWith(avatarPath: '/path/to/avatar.jpg');
      expect(updated.avatarPath, '/path/to/avatar.jpg');
      expect(updated.name, user.name);
    });
  });
}
