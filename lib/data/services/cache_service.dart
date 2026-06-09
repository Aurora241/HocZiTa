import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// CacheService: lưu/đọc JSON vào SharedPreferences kèm timestamp.
/// Mỗi entry có TTL — hết hạn vẫn đọc được (dùng khi offline).
class CacheService {
  static const Duration _defaultTtl = Duration(hours: 24);

  static const String _prefixData = 'cache_data_';
  static const String _prefixTs   = 'cache_ts_';

  // ─── Ghi ─────────────────────────────────────────────────────────────────

  Future<void> save(String key, List<Map<String, dynamic>> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefixData + key, json.encode(data));
    await prefs.setInt(_prefixTs + key, DateTime.now().millisecondsSinceEpoch);
  }

  // ─── Đọc ─────────────────────────────────────────────────────────────────

  /// Trả về data nếu còn trong TTL.
  /// [ignoreExpiry] = true → trả về dù đã hết hạn (dùng khi offline).
  Future<List<Map<String, dynamic>>?> load(
    String key, {
    Duration ttl = _defaultTtl,
    bool ignoreExpiry = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw  = prefs.getString(_prefixData + key);
    final tsMs = prefs.getInt(_prefixTs + key);

    if (raw == null || tsMs == null) return null;

    if (!ignoreExpiry) {
      final age = DateTime.now().millisecondsSinceEpoch - tsMs;
      if (age > ttl.inMilliseconds) return null; // hết hạn
    }

    final list = json.decode(raw) as List<dynamic>;
    return list.cast<Map<String, dynamic>>();
  }

  /// Xoá một entry
  Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefixData + key);
    await prefs.remove(_prefixTs + key);
  }

  /// Xoá toàn bộ cache nội dung
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys()
        .where((k) => k.startsWith(_prefixData) || k.startsWith(_prefixTs))
        .toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
  }
}
