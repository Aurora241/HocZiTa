import 'package:flutter_test/flutter_test.dart';
import 'package:hoczita/data/datasources/local_datasource.dart';
import 'package:hoczita/data/repositories/game_repository.dart';

void main() {
  late GameRepository repo;

  setUp(() {
    repo = GameRepository(LocalDataSource());
  });

  group('calculateStars — game thông thường (40s / 20s)', () {
    test('3 sao: hoàn thành đúng hết trong 20s', () {
      final stars = repo.calculateStars(
        totalSeconds: 18,
        correctCount: 10,
        totalQuestions: 10,
      );
      expect(stars, 3);
    });

    test('3 sao: đúng hết, đúng bằng 20s', () {
      final stars = repo.calculateStars(
        totalSeconds: 20,
        correctCount: 10,
        totalQuestions: 10,
      );
      expect(stars, 3);
    });

    test('2 sao: đúng hết trong 21–40s', () {
      final stars = repo.calculateStars(
        totalSeconds: 35,
        correctCount: 10,
        totalQuestions: 10,
      );
      expect(stars, 2);
    });

    test('2 sao: đúng hết, đúng bằng 40s', () {
      final stars = repo.calculateStars(
        totalSeconds: 40,
        correctCount: 10,
        totalQuestions: 10,
      );
      expect(stars, 2);
    });

    test('1 sao: đúng hết nhưng quá 40s', () {
      final stars = repo.calculateStars(
        totalSeconds: 55,
        correctCount: 10,
        totalQuestions: 10,
      );
      expect(stars, 1);
    });

    test('1 sao: trả lời sai dù nhanh', () {
      final stars = repo.calculateStars(
        totalSeconds: 15,
        correctCount: 8,   // sai 2 câu
        totalQuestions: 10,
      );
      expect(stars, 1);
    });

    test('1 sao: không trả lời đúng câu nào', () {
      final stars = repo.calculateStars(
        totalSeconds: 60,
        correctCount: 0,
        totalQuestions: 10,
      );
      expect(stars, 1);
    });
  });

  group('calculateStars — Memory Match (60s / 40s / 20s)', () {
    test('3 sao: hoàn thành trong 20s', () {
      final stars = repo.calculateStars(
        totalSeconds: 15,
        correctCount: 8,
        totalQuestions: 8,
        isMemoryMatch: true,
      );
      expect(stars, 3);
    });

    test('2 sao: hoàn thành trong 40s', () {
      final stars = repo.calculateStars(
        totalSeconds: 38,
        correctCount: 8,
        totalQuestions: 8,
        isMemoryMatch: true,
      );
      expect(stars, 2);
    });

    test('1 sao: hoàn thành trong 60s', () {
      final stars = repo.calculateStars(
        totalSeconds: 55,
        correctCount: 8,
        totalQuestions: 8,
        isMemoryMatch: true,
      );
      expect(stars, 1);
    });
  });
}
