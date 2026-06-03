class LeaderboardEntry {
  final String userId;
  final String userName;
  final int totalStars;
  final int totalPoints;
  final Map<String, int> bestStarsByLevel; // 'A'|'B'|'C' → 0-3

  const LeaderboardEntry({
    required this.userId,
    required this.userName,
    required this.totalStars,
    required this.totalPoints,
    required this.bestStarsByLevel,
  });
}

class ScoreModel {
  final String userId;
  final String gameId;     // vd: 'flashcard_speed_run'
  final String gameTitle;  // vd: 'Flashcard Speed Run'
  final String level;      // 'A' | 'B' | 'C'
  final int stars;         // 1 | 2 | 3
  final int totalSeconds;  // Thời gian hoàn thành
  final int correctCount;  // Số câu đúng
  final DateTime playedAt;

  const ScoreModel({
    required this.userId,
    required this.gameId,
    required this.gameTitle,
    required this.level,
    required this.stars,
    required this.totalSeconds,
    required this.correctCount,
    required this.playedAt,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'gameId': gameId,
        'gameTitle': gameTitle,
        'level': level,
        'stars': stars,
        'totalSeconds': totalSeconds,
        'correctCount': correctCount,
        'playedAt': playedAt.toIso8601String(),
      };

  factory ScoreModel.fromJson(Map<String, dynamic> json) => ScoreModel(
        userId: json['userId'],
        gameId: json['gameId'],
        gameTitle: json['gameTitle'],
        level: json['level'],
        stars: json['stars'],
        totalSeconds: json['totalSeconds'],
        correctCount: json['correctCount'],
        playedAt: DateTime.parse(json['playedAt']),
      );

  // Tổng điểm quy đổi
  int get totalPoints => stars * correctCount * 10;
}
