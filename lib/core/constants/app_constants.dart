class AppConstants {
  AppConstants._();

  // App info
  static const String appName = 'HocZiTa';

  // SharedPreferences keys
  static const String keyIsLoggedIn = 'is_logged_in';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyUserEmail = 'user_email';
  static const String keyUserAvatar = 'user_avatar';
  static const String keyScores = 'user_scores';
  static const String keyUsers = 'registered_users';

  // Game config
  static const int secondsPerQuestion = 6;    // 6s/câu
  static const int questionsPerRound = 10;    // 10 câu/lượt
  static const int memoryMatchCards = 16;     // 16 thẻ Memory Match

  // Thời gian giới hạn để đạt sao (giây)
  static const int star3Time = 20;   // 3 sao: 20s
  static const int star2Time = 40;   // 2 sao: 40s
  static const int memoryMatchStar3Time = 20;  // Memory Match 3 sao
  static const int memoryMatchStar2Time = 40;  // Memory Match 2 sao
  static const int memoryMatchStar1Time = 60;  // Memory Match 1 sao

  // Asset paths
  static const String pathForeignLanguage = 'assets/data/foreign_language';
  static const String pathMath = 'assets/data/math';

  // Levels
  static const List<String> levels = ['A', 'B', 'C'];
}
