// Model cho Foreign Language
class WordModel {
  final int id;
  final String word;       // Từ tiếng Anh
  final String meaning;    // Nghĩa tiếng Việt
  final String? imagePath; // Hình ảnh minh họa

  const WordModel({
    required this.id,
    required this.word,
    required this.meaning,
    this.imagePath,
  });

  factory WordModel.fromJson(Map<String, dynamic> json) => WordModel(
        id: json['id'],
        word: json['word'],
        meaning: json['meaning'],
        imagePath: json['image_path'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'meaning': meaning,
        'image_path': imagePath,
      };
}

// Model cho Math
class MathQuestionModel {
  final int id;
  final String type;       // 'count' | 'calculate' | 'compare'
  final String? imagePath; // Hình ảnh (dùng cho đếm số, so sánh)
  final String? expression;// Phép tính (dùng cho thêm bớt)
  final String? imagePathB;// Hình ảnh thứ 2 (dùng cho so sánh)
  final int answer;        // Đáp án đúng
  final List<int> choices; // 4 lựa chọn

  const MathQuestionModel({
    required this.id,
    required this.type,
    this.imagePath,
    this.expression,
    this.imagePathB,
    required this.answer,
    required this.choices,
  });

  factory MathQuestionModel.fromJson(Map<String, dynamic> json) =>
      MathQuestionModel(
        id: json['id'],
        type: json['type'],
        imagePath: json['image_path'],
        expression: json['expression'],
        imagePathB: json['image_path_b'],
        answer: json['answer'],
        choices: List<int>.from(json['choices']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'image_path': imagePath,
        'expression': expression,
        'image_path_b': imagePathB,
        'answer': answer,
        'choices': choices,
      };
}
