import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/datasources/cached_content_datasource.dart';
import '../../data/datasources/content_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/models/nks_user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/game_repository.dart';
import '../../data/services/nks_api_service.dart';

// ─── NKS Auth ─────────────────────────────────────────────────────────────────

class NKSAuthState {
  final NKSUserModel? user;
  final bool isLoading;
  final String? error;

  const NKSAuthState({this.user, this.isLoading = false, this.error});

  bool get isLoggedIn => user != null;
}

class NKSAuthNotifier extends StateNotifier<NKSAuthState> {
  final NKSApiService _api;

  static const tokenKey = 'nks_access_token';
  static const _userCacheKey = 'nks_user_cache';

  // Bắt đầu ở isLoading=true để UI biết đang restore session
  NKSAuthNotifier(this._api) : super(const NKSAuthState(isLoading: true)) {
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    if (token == null) {
      if (mounted) state = const NKSAuthState();
      return;
    }

    // Bước 1: Restore từ cache ngay lập tức (không cần mạng)
    final cachedJson = prefs.getString(_userCacheKey);
    if (cachedJson != null) {
      try {
        final cached = NKSUserModel.fromJson(
          Map<String, dynamic>.from(jsonDecode(cachedJson) as Map),
          token: token,
        );
        if (mounted) state = NKSAuthState(user: cached);
      } catch (_) {}
    }

    // Bước 2: Refresh từ API trong nền
    try {
      final user = await _api.getUserInfo(token: token);
      await prefs.setString(_userCacheKey, jsonEncode(user.toJson()));
      if (mounted) state = NKSAuthState(user: user);
    } on NKSApiException catch (e) {
      // Chỉ đăng xuất khi server từ chối token (401) — không đăng xuất khi mất mạng
      if (e.statusCode == 401) {
        await prefs.remove(tokenKey);
        await prefs.remove(_userCacheKey);
        if (mounted) state = const NKSAuthState();
      } else if (mounted && state.user == null) {
        state = const NKSAuthState();
      }
    } catch (_) {
      if (mounted && state.user == null) {
        state = const NKSAuthState();
      }
    }
  }

  Future<String?> login(String username, String password) async {
    state = const NKSAuthState(isLoading: true);
    try {
      final user = await _api.login(username: username, password: password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(tokenKey, user.accessToken!);
      await prefs.setString(_userCacheKey, jsonEncode(user.toJson()));
      if (mounted) state = NKSAuthState(user: user);
      return null;
    } on NKSApiException catch (e) {
      if (mounted) state = NKSAuthState(error: e.message);
      return e.message;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(_userCacheKey);
    if (mounted) state = const NKSAuthState();
  }

  void updateUser(NKSUserModel user) {
    if (mounted) {
      state = NKSAuthState(user: user);
      SharedPreferences.getInstance().then(
        (prefs) => prefs.setString(_userCacheKey, jsonEncode(user.toJson())),
      );
    }
  }
}

final nksApiServiceProvider = Provider<NKSApiService>((_) => NKSApiService());

final nksAuthProvider =
    StateNotifierProvider<NKSAuthNotifier, NKSAuthState>((ref) {
  return NKSAuthNotifier(ref.watch(nksApiServiceProvider));
});

final currentNKSUserProvider = Provider<NKSUserModel?>((ref) {
  return ref.watch(nksAuthProvider).user;
});

// ─── Content / Game ───────────────────────────────────────────────────────────

/// Supabase + cache 24h + fallback offline.
/// Đổi thành LocalDataSource() nếu muốn dùng JSON local hoàn toàn.
final contentDataSourceProvider = Provider<ContentDataSource>((ref) {
  return CachedContentDataSource();
});

final authRepoProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(LocalDataSource());
});

final gameRepoProvider = Provider<GameRepository>((ref) {
  return GameRepository(
    content: ref.watch(contentDataSourceProvider),
    local: LocalDataSource(),
  );
});

/// Nguồn sự thật duy nhất cho trạng thái đăng nhập — dùng ở HomeScreen,
/// LoginScreen, RegisterScreen.
/// Watch nksAuthProvider để tự động cập nhật khi session thay đổi.
final authProvider = FutureProvider<bool>((ref) async {
  final nksState = ref.watch(nksAuthProvider);

  // Đang restore session — kiểm tra prefs offline để tránh flash "chưa đăng nhập"
  if (nksState.isLoading) {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(NKSAuthNotifier.tokenKey) != null;
  }

  if (nksState.isLoggedIn) return true;
  // Fallback: local auth (tài khoản đã tạo trước khi tích hợp NKS)
  return ref.read(authRepoProvider).isLoggedIn();
});

final authLoadingProvider = StateProvider<bool>((ref) => false);
final authErrorProvider = StateProvider<String?>((ref) => null);

/// Tăng lên 1 sau mỗi lần lưu score — dùng để trigger rebuild _statsProvider.
final scoreVersionProvider = StateProvider<int>((ref) => 0);

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final isLoggedIn = await ref.watch(authProvider.future);
  if (!isLoggedIn) return null;
  return ref.read(authRepoProvider).getCurrentUser();
});

/// Map<'gameId_level', bestStars> cho user hiện tại.
final myProgressProvider =
    FutureProvider.autoDispose<Map<String, int>>((ref) async {
  ref.watch(scoreVersionProvider);
  final user = await ref.watch(currentUserProvider.future);
  if (user == null) return {};
  final all = await LocalDataSource().getAllScores();
  final best = <String, int>{};
  for (final s in all.where((s) => s.userId == user.id)) {
    final key = '${s.gameId}_${s.level}';
    if ((best[key] ?? 0) < s.stars) best[key] = s.stars;
  }
  return best;
});

final leaderboardByGameProvider =
    FutureProvider.autoDispose.family<List<LeaderboardEntry>, String>(
  (ref, gameId) => LocalDataSource().getLeaderboardEntriesByGame(gameId),
);

final leaderboardByMonthProvider =
    FutureProvider.autoDispose.family<List<LeaderboardEntry>, DateTime>(
  (ref, month) => LocalDataSource().getLeaderboardEntriesByMonth(month),
);
