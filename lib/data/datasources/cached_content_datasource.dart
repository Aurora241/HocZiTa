import '../models/word_model.dart';
import '../services/cache_service.dart';
import 'content_datasource.dart';
import 'supabase_datasource.dart';

/// CachedContentDataSource: bọc SupabaseDataSource bằng cache layer.
///
/// Chiến lược:
///   1. Cache còn tươi (< 24h)  → trả cache, không gọi mạng
///   2. Cache hết hạn / trống   → fetch Supabase → lưu cache → trả data
///   3. Supabase lỗi (offline)  → trả cache cũ dù hết hạn
///   4. Cả hai đều lỗi          → trả danh sách rỗng
class CachedContentDataSource implements ContentDataSource {
  final SupabaseDataSource _remote;
  final CacheService _cache;

  CachedContentDataSource({
    SupabaseDataSource? remote,
    CacheService? cache,
  })  : _remote = remote ?? SupabaseDataSource(),
        _cache  = cache  ?? CacheService();

  // ─── Cache keys ───────────────────────────────────────────────────────────

  static String _keyWords(String level)     => 'words_$level';
  static String _keyWordsAll()              => 'words_all';
  static String _keyMath(String type, String level) => 'math_${type}_$level';
  static String _keyMathAll(String type)    => 'math_${type}_all';

  // ─── WORDS ────────────────────────────────────────────────────────────────

  @override
  Future<List<WordModel>> getWords(String level) async {
    return _fetchWords(
      cacheKey: _keyWords(level),
      fetchFn: () => _remote.getWords(level),
    );
  }

  @override
  Future<List<WordModel>> getAllWords() async {
    return _fetchWords(
      cacheKey: _keyWordsAll(),
      fetchFn: () => _remote.getAllWords(),
    );
  }

  // ─── MATH ─────────────────────────────────────────────────────────────────

  @override
  Future<List<MathQuestionModel>> getMathQuestions(
      String type, String level) async {
    return _fetchMath(
      cacheKey: _keyMath(type, level),
      fetchFn: () => _remote.getMathQuestions(type, level),
    );
  }

  @override
  Future<List<MathQuestionModel>> getAllMathQuestions(String type) async {
    return _fetchMath(
      cacheKey: _keyMathAll(type),
      fetchFn: () => _remote.getAllMathQuestions(type),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  Future<List<WordModel>> _fetchWords({
    required String cacheKey,
    required Future<List<WordModel>> Function() fetchFn,
  }) async {
    // 1. Cache tươi
    final cached = await _cache.load(cacheKey);
    if (cached != null) {
      return cached.map(WordModel.fromJson).toList();
    }

    // 2. Fetch remote
    try {
      final data = await fetchFn();
      await _cache.save(cacheKey, data.map((w) => w.toJson()).toList());
      return data;
    } catch (_) {
      // 3. Offline — dùng cache cũ dù hết hạn
      final stale = await _cache.load(cacheKey, ignoreExpiry: true);
      return stale?.map(WordModel.fromJson).toList() ?? [];
    }
  }

  Future<List<MathQuestionModel>> _fetchMath({
    required String cacheKey,
    required Future<List<MathQuestionModel>> Function() fetchFn,
  }) async {
    // 1. Cache tươi
    final cached = await _cache.load(cacheKey);
    if (cached != null) {
      return cached.map(MathQuestionModel.fromJson).toList();
    }

    // 2. Fetch remote
    try {
      final data = await fetchFn();
      await _cache.save(cacheKey, data.map((q) => q.toJson()).toList());
      return data;
    } catch (_) {
      // 3. Offline — dùng cache cũ dù hết hạn
      final stale = await _cache.load(cacheKey, ignoreExpiry: true);
      return stale?.map(MathQuestionModel.fromJson).toList() ?? [];
    }
  }
}
