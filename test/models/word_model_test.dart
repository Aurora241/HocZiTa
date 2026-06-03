import 'package:flutter_test/flutter_test.dart';
import 'package:hoczita/data/models/word_model.dart';

void main() {
  group('WordModel', () {
    test('fromJson parse đúng từ JSON', () {
      final json = {
        'id': 1,
        'word': 'Apple',
        'meaning': 'Quả táo',
        'image_path': null,
      };
      final word = WordModel.fromJson(json);
      expect(word.id, 1);
      expect(word.word, 'Apple');
      expect(word.meaning, 'Quả táo');
      expect(word.imagePath, isNull);
    });

    test('fromJson với image_path có giá trị', () {
      final json = {
        'id': 2,
        'word': 'Dog',
        'meaning': 'Con chó',
        'image_path': 'assets/images/dog.png',
      };
      final word = WordModel.fromJson(json);
      expect(word.imagePath, 'assets/images/dog.png');
    });

    test('toJson trả về đúng Map', () {
      const word = WordModel(id: 3, word: 'Cat', meaning: 'Con mèo');
      final json = word.toJson();
      expect(json['id'], 3);
      expect(json['word'], 'Cat');
      expect(json['meaning'], 'Con mèo');
      expect(json['image_path'], isNull);
    });
  });

  group('MathQuestionModel', () {
    test('fromJson parse câu hỏi loại calculate', () {
      final json = {
        'id': 1,
        'type': 'calculate',
        'image_path': null,
        'expression': '5 + 3',
        'image_path_b': null,
        'answer': 8,
        'choices': [6, 7, 8, 9],
      };
      final q = MathQuestionModel.fromJson(json);
      expect(q.type, 'calculate');
      expect(q.expression, '5 + 3');
      expect(q.answer, 8);
      expect(q.choices, [6, 7, 8, 9]);
      expect(q.choices.length, 4);
    });

    test('fromJson parse câu hỏi loại count', () {
      final json = {
        'id': 2,
        'type': 'count',
        'image_path': 'assets/images/3apples.png',
        'expression': null,
        'image_path_b': null,
        'answer': 3,
        'choices': [2, 3, 4, 5],
      };
      final q = MathQuestionModel.fromJson(json);
      expect(q.type, 'count');
      expect(q.imagePath, 'assets/images/3apples.png');
      expect(q.answer, 3);
    });

    test('choices luôn có 4 lựa chọn', () {
      final json = {
        'id': 3,
        'type': 'compare',
        'image_path': null,
        'expression': null,
        'image_path_b': null,
        'answer': 5,
        'choices': [3, 4, 5, 6],
      };
      final q = MathQuestionModel.fromJson(json);
      expect(q.choices.length, 4);
    });

    test('đáp án đúng nằm trong choices', () {
      final json = {
        'id': 4,
        'type': 'calculate',
        'image_path': null,
        'expression': '10 - 4',
        'image_path_b': null,
        'answer': 6,
        'choices': [4, 5, 6, 7],
      };
      final q = MathQuestionModel.fromJson(json);
      expect(q.choices.contains(q.answer), isTrue);
    });
  });
}
