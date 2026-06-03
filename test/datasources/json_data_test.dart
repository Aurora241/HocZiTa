import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:hoczita/data/models/word_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Helper đọc JSON từ assets
  Future<List<dynamic>> loadJson(String path) async {
    final str = await rootBundle.loadString(path);
    return json.decode(str);
  }

  group('Foreign Language JSON', () {
    for (final level in ['a', 'b', 'c']) {
      test('level_$level.json parse được thành List<WordModel>', () async {
        final raw = await loadJson(
            'assets/data/foreign_language/level_$level.json');

        expect(raw, isNotEmpty);
        expect(raw.length, greaterThanOrEqualTo(10)); // ít nhất 10 từ

        final words = raw.map((e) => WordModel.fromJson(e)).toList();

        for (final w in words) {
          expect(w.word, isNotEmpty);
          expect(w.meaning, isNotEmpty);
          expect(w.id, isNonZero);
        }
      });
    }

    test('Không có từ nào bị trùng id trong level_a', () async {
      final raw = await loadJson(
          'assets/data/foreign_language/level_a.json');
      final ids = raw.map((e) => e['id']).toList();
      final uniqueIds = ids.toSet();
      expect(ids.length, uniqueIds.length); // không trùng
    });
  });

  group('Math JSON', () {
    for (final level in ['a', 'b', 'c']) {
      test('level_$level.json parse được và có đủ 3 loại', () async {
        final raw = await loadJson('assets/data/math/level_$level.json');

        expect(raw, isNotEmpty);

        final questions = raw.map((e) => MathQuestionModel.fromJson(e)).toList();
        final types = questions.map((q) => q.type).toSet();

        // Phải có đủ 3 loại
        expect(types.contains('count'), isTrue);
        expect(types.contains('calculate'), isTrue);
        expect(types.contains('compare'), isTrue);

        // Mỗi câu phải có 4 lựa chọn
        for (final q in questions) {
          expect(q.choices.length, 4, reason: 'Câu id=${q.id} phải có 4 choices');
          // Đáp án đúng phải nằm trong choices
          expect(q.choices.contains(q.answer), isTrue,
              reason: 'Câu id=${q.id}: answer=${q.answer} phải nằm trong choices');
        }
      });
    }
  });
}
