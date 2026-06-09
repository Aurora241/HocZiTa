import '../datasources/local_datasource.dart';
import '../datasources/content_datasource.dart';
import '../models/word_model.dart';
import '../models/score_model.dart';
export '../models/score_model.dart' show LeaderboardEntry;

class GameRepository {
  /// Nguồn nội dung: có thể là LocalDataSource hoặc SupabaseDataSource
  final ContentDataSource _content;

  /// Luôn dùng local cho scores / auth (không sync cloud ở giai đoạn này)
  final LocalDataSource _local;

  GameRepository({
    required ContentDataSource content,
    required LocalDataSource local,
  })  : _content = content,
        _local = local;

  // ─── Lấy dữ liệu game ──────────────────────────────────────────────────────

  Future<List<WordModel>> getWordsForGame(String level) =>
      _content.getWords(level);

  Future<List<MathQuestionModel>> getMathQuestions(
          String type, String level) =>
      _content.getMathQuestions(type, level);

  // ─── Lưu điểm ──────────────────────────────────────────────────────────────

  Future<void> saveScore(ScoreModel score) => _local.saveScore(score);

  // ─── Leaderboard ───────────────────────────────────────────────────────────

  Future<List<ScoreModel>> getLeaderboardByGame(String gameId) =>
      _local.getScoresByGame(gameId);

  Future<List<ScoreModel>> getLeaderboardByMonth(DateTime month) =>
      _local.getScoresByMonth(month);

  Future<List<LeaderboardEntry>> getLeaderboardEntriesByGame(String gameId) =>
      _local.getLeaderboardEntriesByGame(gameId);

  Future<List<LeaderboardEntry>> getLeaderboardEntriesByMonth(DateTime month) =>
      _local.getLeaderboardEntriesByMonth(month);

  Future<int> getTotalStars(String userId) =>
      _local.getTotalStarsByUser(userId);

  // ─── Tính sao ──────────────────────────────────────────────────────────────

  /// Tính số sao dựa trên thời gian hoàn thành và số câu đúng
  /// isMemoryMatch = true thì dùng mốc 60/40/20s, còn lại dùng 40/20s
  int calculateStars({
    required int totalSeconds,
    required int correctCount,
    required int totalQuestions,
    bool isMemoryMatch = false,
  }) {
    final bool allCorrect = correctCount == totalQuestions;
    if (!allCorrect) return 1;

    if (isMemoryMatch) {
      if (totalSeconds <= 20) return 3;
      if (totalSeconds <= 40) return 2;
      return 1;
    } else {
      if (totalSeconds <= 20) return 3;
      if (totalSeconds <= 40) return 2;
      return 1;
    }
  }
}
