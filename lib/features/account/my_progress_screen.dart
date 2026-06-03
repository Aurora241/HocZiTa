import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../auth/auth_providers.dart';

// gameId, title, category (language | math)
const _kGames = [
  ('flashcard_speed_run', 'Flashcard Speed Run', 'language'),
  ('memory_match', 'Memory Match', 'language'),
  ('picture_guess', 'Picture Guess', 'language'),
  ('count_game', 'Đếm Số', 'math'),
  ('calculate_game', 'Thêm Bớt', 'math'),
  ('compare_game', 'So Sánh', 'math'),
];

final _kMaxStars = _kGames.length * 3 * 3; // 6 game × 3 level × 3 sao = 54

class MyProgressScreen extends ConsumerWidget {
  const MyProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(myProgressProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: progressAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(child: Text('Có lỗi xảy ra')),
        data: (progress) {
          final totalEarned =
              progress.values.fold<int>(0, (s, v) => s + v);
          return Column(
            children: [
              _Header(
                context: context,
                totalEarned: totalEarned,
                totalPossible: _kMaxStars,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                        label: 'Ngoại ngữ',
                        icon: Icons.language_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: 12),
                      ..._kGames
                          .where((g) => g.$3 == 'language')
                          .map((g) => _GameRow(
                                gameId: g.$1,
                                title: g.$2,
                                progress: progress,
                              )),
                      const SizedBox(height: 24),
                      _SectionLabel(
                        label: 'Toán học',
                        icon: Icons.calculate_rounded,
                        color: const Color(0xFF7C3AED),
                      ),
                      const SizedBox(height: 12),
                      ..._kGames
                          .where((g) => g.$3 == 'math')
                          .map((g) => _GameRow(
                                gameId: g.$1,
                                title: g.$2,
                                progress: progress,
                              )),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final BuildContext context;
  final int totalEarned;
  final int totalPossible;

  const _Header({
    required this.context,
    required this.totalEarned,
    required this.totalPossible,
  });

  @override
  Widget build(BuildContext ctx) {
    final topPad = MediaQuery.of(ctx).padding.top;
    final pct = totalPossible == 0 ? 0.0 : totalEarned / totalPossible;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0077BB), Color(0xFF00AADD)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(24, topPad + 12, 24, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(ctx),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Tiến độ của tôi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.star, size: 36),
              const SizedBox(width: 8),
              Text(
                '$totalEarned',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
              ),
              Text(
                ' / $totalPossible sao',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.star),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${(pct * 100).round()}% hoàn thành',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;

  const _SectionLabel(
      {required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Game row — 1 game × 3 level badges
// ─────────────────────────────────────────────────────────────────────────────

class _GameRow extends StatelessWidget {
  final String gameId;
  final String title;
  final Map<String, int> progress;

  const _GameRow({
    required this.gameId,
    required this.title,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: ['A', 'B', 'C'].map((level) {
              final stars = progress['${gameId}_$level'] ?? 0;
              return _LevelBadge(level: level, stars: stars);
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final String level;
  final int stars;

  const _LevelBadge({required this.level, required this.stars});

  @override
  Widget build(BuildContext context) {
    final played = stars > 0;

    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: played
            ? AppColors.primary.withValues(alpha: 0.08)
            : Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: played
              ? AppColors.primary.withValues(alpha: 0.2)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            level,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: played ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (i) {
              return Icon(
                i < stars ? Icons.star_rounded : Icons.star_border_rounded,
                size: 11,
                color: i < stars ? AppColors.star : Colors.grey[400],
              );
            }),
          ),
        ],
      ),
    );
  }
}
