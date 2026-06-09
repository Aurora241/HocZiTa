import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/datasources/cached_content_datasource.dart';
import '../../data/datasources/content_datasource.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/game_repository.dart';

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
final authProvider = FutureProvider<bool>((ref) async {
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
