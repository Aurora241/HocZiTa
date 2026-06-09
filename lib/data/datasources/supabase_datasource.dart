import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/word_model.dart';
import 'content_datasource.dart';

/// SupabaseDataSource: Nguồn dữ liệu từ Supabase
/// Fetch words và math questions từ cloud — không cần build lại app khi
/// thêm mới categories / câu hỏi / ảnh.
class SupabaseDataSource implements ContentDataSource {
  SupabaseClient get _db => Supabase.instance.client;

  // ─── WORDS ────────────────────────────────────────────────────────────────

  @override
  Future<List<WordModel>> getWords(String level) async {
    final data = await _db
        .from('words')
        .select()
        .eq('difficulty', level.toLowerCase())
        .eq('is_active', true)
        .order('id');
    return (data as List<dynamic>)
        .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<WordModel>> getAllWords() async {
    final data = await _db
        .from('words')
        .select()
        .eq('is_active', true)
        .order('difficulty')
        .order('id');
    return (data as List<dynamic>)
        .map((e) => WordModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ─── MATH QUESTIONS ───────────────────────────────────────────────────────

  @override
  Future<List<MathQuestionModel>> getMathQuestions(
      String type, String level) async {
    final data = await _db
        .from('math_questions')
        .select()
        .eq('type', type)
        .eq('difficulty', level.toLowerCase())
        .eq('is_active', true)
        .order('id');
    return (data as List<dynamic>)
        .map((e) => _mathFromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<MathQuestionModel>> getAllMathQuestions(String type) async {
    final data = await _db
        .from('math_questions')
        .select()
        .eq('type', type)
        .eq('is_active', true)
        .order('difficulty')
        .order('id');
    return (data as List<dynamic>)
        .map((e) => _mathFromSupabase(e as Map<String, dynamic>))
        .toList();
  }

  /// Supabase lưu choices là JSONB array, parse sang List of int
  MathQuestionModel _mathFromSupabase(Map<String, dynamic> json) {
    final choices = (json['choices'] as List<dynamic>)
        .map((e) => e as int)
        .toList();
    return MathQuestionModel(
      id: json['id'] as int,
      type: json['type'] as String,
      difficulty: json['difficulty'] as String,
      expression: json['expression'] as String?,
      imagePath: json['image_url'] as String?,
      imagePathB: json['image_url_b'] as String?,
      answer: json['answer'] as int,
      choices: choices,
    );
  }
}
