// Model cho Foreign Language
class WordModel {
  final int id;
  final String word;       // Từ tiếng Anh
  final String meaning;    // Nghĩa tiếng Việt
  final String? imagePath; // Local asset path (JSON cũ)
  final String? imageUrl;  // Supabase Storage URL
  final String? emoji;     // Fallback khi chưa có ảnh

  const WordModel({
    required this.id,
    required this.word,
    required this.meaning,
    this.imagePath,
    this.imageUrl,
    this.emoji,
  });

  /// Hỗ trợ cả JSON local (image_path) lẫn Supabase (image_url, emoji)
  factory WordModel.fromJson(Map<String, dynamic> json) => WordModel(
        id: json['id'] as int,
        word: json['word'] as String,
        meaning: json['meaning'] as String,
        imagePath: json['image_path'] as String?,
        imageUrl: json['image_url'] as String?,
        emoji: json['emoji'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'meaning': meaning,
        'image_path': imagePath,
        'image_url': imageUrl,
        'emoji': emoji,
      };
}

// Model cho Math
class MathQuestionModel {
  final int id;
  final String type;        // 'count' | 'calculate' | 'compare'
  final String? difficulty; // 'a' | 'b' | 'c' (có từ Supabase, null từ local JSON)
  final String? imagePath;  // Local asset path (JSON cũ)
  final String? expression; // Phép tính (dùng cho thêm bớt)
  final String? imagePathB; // Ảnh thứ 2 (dùng cho so sánh)
  final int answer;         // Đáp án đúng
  final List<int> choices;  // 4 lựa chọn

  const MathQuestionModel({
    required this.id,
    required this.type,
    this.difficulty,
    this.imagePath,
    this.expression,
    this.imagePathB,
    required this.answer,
    required this.choices,
  });

  factory MathQuestionModel.fromJson(Map<String, dynamic> json) =>
      MathQuestionModel(
        id: json['id'] as int,
        type: json['type'] as String,
        difficulty: json['difficulty'] as String?,
        imagePath: json['image_path'] as String?,
        expression: json['expression'] as String?,
        imagePathB: json['image_path_b'] as String?,
        answer: json['answer'] as int,
        choices: List<int>.from(json['choices'] as List),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'difficulty': difficulty,
        'image_path': imagePath,
        'expression': expression,
        'image_path_b': imagePathB,
        'answer': answer,
        'choices': choices,
      };
}
