import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/word_model.dart';
import '../models/user_model.dart';
import '../models/score_model.dart';
import '../../core/constants/app_constants.dart';

/// LocalDataSource: Nguồn dữ liệu local
/// Sau này chỉ cần tạo ApiDataSource với interface tương tự là swap được
class LocalDataSource {
  // ─── WORDS (Foreign Language) ─────────────────────────────────────────────

  Future<List<WordModel>> getWords(String level) async {
    final String path =
        '${AppConstants.pathForeignLanguage}/level_${level.toLowerCase()}.json';
    final String jsonStr = await rootBundle.loadString(path);
    final List<dynamic> list = json.decode(jsonStr);
    return list.map((e) => WordModel.fromJson(e)).toList();
  }

  // ─── MATH QUESTIONS ────────────────────────────────────────────────────────

  Future<List<MathQuestionModel>> getMathQuestions(
      String type, String level) async {
    final String path =
        '${AppConstants.pathMath}/level_${level.toLowerCase()}.json';
    final String jsonStr = await rootBundle.loadString(path);
    final List<dynamic> list = json.decode(jsonStr);
    return list
        .map((e) => MathQuestionModel.fromJson(e))
        .where((q) => q.type == type)
        .toList();
  }

  // ─── AUTH ──────────────────────────────────────────────────────────────────

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.keyUserId);
    if (userId == null) return null;

    final users = await getAllUsers();
    try {
      return users.firstWhere((u) => u.id == userId);
    } catch (_) {
      return null;
    }
  }

  Future<List<UserModel>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? usersJson = prefs.getString(AppConstants.keyUsers);
    if (usersJson == null) return [];
    final List<dynamic> list = json.decode(usersJson);
    return list.map((e) => UserModel.fromJson(e)).toList();
  }

  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final users = await getAllUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index >= 0) {
      users[index] = user;
    } else {
      users.add(user);
    }
    await prefs.setString(
        AppConstants.keyUsers, json.encode(users.map((u) => u.toJson()).toList()));
  }

  Future<void> login(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    await prefs.setString(AppConstants.keyUserId, user.id);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyIsLoggedIn, false);
    await prefs.remove(AppConstants.keyUserId);
  }

  // ─── SCORES ────────────────────────────────────────────────────────────────

  Future<List<ScoreModel>> getAllScores() async {
    final prefs = await SharedPreferences.getInstance();
    final String? scoresJson = prefs.getString(AppConstants.keyScores);
    if (scoresJson == null) return [];
    final List<dynamic> list = json.decode(scoresJson);
    return list.map((e) => ScoreModel.fromJson(e)).toList();
  }

  Future<void> saveScore(ScoreModel score) async {
    final prefs = await SharedPreferences.getInstance();
    final scores = await getAllScores();
    scores.add(score);
    await prefs.setString(
        AppConstants.keyScores,
        json.encode(scores.map((s) => s.toJson()).toList()));
  }

  Future<List<ScoreModel>> getScoresByGame(String gameId) async {
    final all = await getAllScores();
    return all.where((s) => s.gameId == gameId).toList()
      ..sort((a, b) => b.stars.compareTo(a.stars));
  }

  Future<List<ScoreModel>> getScoresByMonth(DateTime month) async {
    final all = await getAllScores();
    return all
        .where((s) =>
            s.playedAt.year == month.year && s.playedAt.month == month.month)
        .toList()
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
  }

  Future<List<LeaderboardEntry>> getLeaderboardEntriesByGame(
      String gameId) async {
    final all = await getAllScores();
    final users = await getAllUsers();
    final byUser = <String, Map<String, int>>{};
    for (final s in all.where((s) => s.gameId == gameId)) {
      byUser.putIfAbsent(s.userId, () => {});
      final prev = byUser[s.userId]![s.level] ?? 0;
      if (s.stars > prev) byUser[s.userId]![s.level] = s.stars;
    }
    final entries = byUser.entries.map((e) {
      final user = users.firstWhere((u) => u.id == e.key,
          orElse: () => UserModel(
              id: e.key, name: '???', email: '', password: '', createdAt: DateTime(2000)));
      final totalStars = e.value.values.fold(0, (s, v) => s + v);
      return LeaderboardEntry(
        userId: e.key,
        userName: user.name,
        totalStars: totalStars,
        totalPoints: totalStars * 10,
        bestStarsByLevel: e.value,
      );
    }).toList()
      ..sort((a, b) => b.totalStars.compareTo(a.totalStars));
    return entries;
  }

  Future<List<LeaderboardEntry>> getLeaderboardEntriesByMonth(
      DateTime month) async {
    final all = await getAllScores();
    final users = await getAllUsers();
    final byUser = <String, int>{};
    for (final s in all.where((s) =>
        s.playedAt.year == month.year && s.playedAt.month == month.month)) {
      byUser[s.userId] = (byUser[s.userId] ?? 0) + s.totalPoints;
    }
    final entries = byUser.entries.map((e) {
      final user = users.firstWhere((u) => u.id == e.key,
          orElse: () => UserModel(
              id: e.key, name: '???', email: '', password: '', createdAt: DateTime(2000)));
      return LeaderboardEntry(
        userId: e.key,
        userName: user.name,
        totalStars: 0,
        totalPoints: e.value,
        bestStarsByLevel: {},
      );
    }).toList()
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    return entries;
  }

  Future<int> getTotalStarsByUser(String userId) async {
    final all = await getAllScores();
    final Map<String, int> best = {};
    for (final s in all.where((s) => s.userId == userId)) {
      final key = '${s.gameId}_${s.level}';
      if ((best[key] ?? 0) < s.stars) best[key] = s.stars;
    }
    return best.values.fold<int>(0, (sum, stars) => sum + stars);
  }
}
