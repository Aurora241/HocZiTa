import '../models/word_model.dart';

/// Interface chung cho nguồn dữ liệu nội dung (từ vựng, toán).
/// LocalDataSource và SupabaseDataSource đều implement interface này
/// → GameRepository / Learn screens không quan tâm data đến từ đâu.
abstract class ContentDataSource {
  Future<List<WordModel>> getWords(String level);
  Future<List<WordModel>> getAllWords();
  Future<List<MathQuestionModel>> getMathQuestions(String type, String level);
  Future<List<MathQuestionModel>> getAllMathQuestions(String type);
}
