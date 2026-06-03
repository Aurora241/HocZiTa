import 'package:flutter_test/flutter_test.dart';
import 'package:hoczita/data/models/score_model.dart';

void main() {
  group('ScoreModel', () {
    final score = ScoreModel(
      userId: 'user-1',
      gameId: 'flashcard_speed_run',
      gameTitle: 'Flashcard Speed Run',
      level: 'A',
      stars: 3,
      totalSeconds: 18,
      correctCount: 10,
      playedAt: DateTime(2026, 6, 1, 10, 0),
    );

    test('toJson -> fromJson giữ nguyên dữ liệu', () {
      final json = score.toJson();
      final restored = ScoreModel.fromJson(json);
      expect(restored.userId, score.userId);
      expect(restored.gameId, score.gameId);
      expect(restored.stars, score.stars);
      expect(restored.totalSeconds, score.totalSeconds);
      expect(restored.correctCount, score.correctCount);
      expect(restored.level, score.level);
    });

    test('totalPoints tính đúng: stars * correctCount * 10', () {
      // 3 sao * 10 câu đúng * 10 = 300
      expect(score.totalPoints, 300);
    });

    test('totalPoints với 1 sao', () {
      final lowScore = ScoreModel(
        userId: 'user-1',
        gameId: 'memory_match',
        gameTitle: 'Memory Match',
        level: 'B',
        stars: 1,
        totalSeconds: 55,
        correctCount: 8,
        playedAt: DateTime(2026, 6, 1),
      );
      // 1 * 8 * 10 = 80
      expect(lowScore.totalPoints, 80);
    });

    test('totalPoints với 2 sao', () {
      final midScore = ScoreModel(
        userId: 'user-1',
        gameId: 'picture_guess',
        gameTitle: 'Picture Guess',
        level: 'A',
        stars: 2,
        totalSeconds: 35,
        correctCount: 10,
        playedAt: DateTime(2026, 6, 1),
      );
      // 2 * 10 * 10 = 200
      expect(midScore.totalPoints, 200);
    });
  });
}
