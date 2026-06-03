import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/score_model.dart';
import '../auth/auth_providers.dart';

const _kGames = [
  ('flashcard_speed_run', 'Flashcard Speed Run'),
  ('memory_match', 'Memory Match'),
  ('picture_guess', 'Picture Guess'),
  ('count_game', 'Đếm Số'),
  ('calculate_game', 'Thêm Bớt'),
  ('compare_game', 'So Sánh'),
];

// ── selected game cho tab "Theo Game" ─────────────────────────────────────
final _selectedGameProvider = StateProvider<String>((ref) => _kGames[0].$1);

// ─────────────────────────────────────────────────────────────────────────────

class LeaderboardScreen extends ConsumerStatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  ConsumerState<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends ConsumerState<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header gradient ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0077BB), Color(0xFF00AADD)],
              ),
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(0)),
            ),
            child: Column(
              children: [
                Padding(
                  padding:
                      EdgeInsets.fromLTRB(24, topPad + 12, 24, 0),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
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
                      const Icon(Icons.emoji_events_rounded,
                          color: AppColors.star, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Bảng xếp hạng',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tab,
                  indicatorColor: AppColors.star,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14),
                  tabs: const [
                    Tab(text: 'Theo Game'),
                    Tab(text: 'Theo Tháng'),
                  ],
                ),
              ],
            ),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: const [
                _ByGameTab(),
                _ByMonthTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 — Theo Game
// ─────────────────────────────────────────────────────────────────────────────

class _ByGameTab extends ConsumerWidget {
  const _ByGameTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedId = ref.watch(_selectedGameProvider);
    final boardAsync = ref.watch(leaderboardByGameProvider(selectedId));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    return Column(
      children: [
        // Dropdown chọn game
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedId,
                items: _kGames
                    .map((g) => DropdownMenuItem(
                          value: g.$1,
                          child: Text(g.$2,
                              style: const TextStyle(fontSize: 14)),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(_selectedGameProvider.notifier).state = v;
                  }
                },
              ),
            ),
          ),
        ),

        // Header cột
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              const SizedBox(width: 36),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Người chơi',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
              ),
              _colHeader('Lv A'),
              _colHeader('Lv B'),
              _colHeader('Lv C'),
              _colHeader('Tổng'),
            ],
          ),
        ),

        // List
        Expanded(
          child: boardAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                const Center(child: Text('Có lỗi xảy ra')),
            data: (entries) {
              if (entries.isEmpty) {
                return const _EmptyState(
                    message: 'Chưa có ai chơi game này');
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: entries.length,
                itemBuilder: (ctx, i) => _GameEntry(
                  rank: i + 1,
                  entry: entries[i],
                  isCurrentUser:
                      currentUser?.id == entries[i].userId,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _colHeader(String text) => SizedBox(
        width: 38,
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _GameEntry extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _GameEntry({
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = isCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFFFF8E1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: AppColors.star.withValues(alpha: 0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: 12),
          _Avatar(name: entry.userName),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.userName,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isCurrentUser
                    ? FontWeight.bold
                    : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          ...['A', 'B', 'C'].map((l) {
            final s = entry.bestStarsByLevel[l] ?? 0;
            return SizedBox(
              width: 38,
              child: Text(
                s > 0 ? '$s★' : '—',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: s > 0 ? AppColors.star : Colors.grey[400],
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
          SizedBox(
            width: 38,
            child: Text(
              '${entry.totalStars}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 — Theo Tháng
// ─────────────────────────────────────────────────────────────────────────────

class _ByMonthTab extends ConsumerWidget {
  const _ByMonthTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month);
    final boardAsync = ref.watch(leaderboardByMonthProvider(month));
    final currentUser = ref.watch(currentUserProvider).valueOrNull;

    final monthLabel = _monthName(now.month);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded,
                  color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'Tháng $monthLabel ${now.year}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              const SizedBox(width: 36 + 12 + 36 + 8),
              const Expanded(
                child: Text('Người chơi',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(
                width: 70,
                child: Text('Điểm',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        Expanded(
          child: boardAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                const Center(child: Text('Có lỗi xảy ra')),
            data: (entries) {
              if (entries.isEmpty) {
                return const _EmptyState(
                    message: 'Chưa có kết quả trong tháng này');
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                itemCount: entries.length,
                itemBuilder: (ctx, i) => _MonthEntry(
                  rank: i + 1,
                  entry: entries[i],
                  isCurrentUser:
                      currentUser?.id == entries[i].userId,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _monthName(int m) {
    const names = [
      '', 'Một', 'Hai', 'Ba', 'Tư', 'Năm', 'Sáu',
      'Bảy', 'Tám', 'Chín', 'Mười', 'Mười Một', 'Mười Hai',
    ];
    return names[m];
  }
}

class _MonthEntry extends StatelessWidget {
  final int rank;
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const _MonthEntry({
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrentUser ? const Color(0xFFFFF8E1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(color: AppColors.star.withValues(alpha: 0.5))
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          _RankBadge(rank: rank),
          const SizedBox(width: 12),
          _Avatar(name: entry.userName),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              entry.userName,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    isCurrentUser ? FontWeight.bold : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 70,
            child: Text(
              '${entry.totalPoints} đ',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _RankBadge extends StatelessWidget {
  final int rank;
  const _RankBadge({required this.rank});

  @override
  Widget build(BuildContext context) {
    if (rank <= 3) {
      const colors = [
        Color(0xFFFFD700), // gold
        Color(0xFFC0C0C0), // silver
        Color(0xFFCD7F32), // bronze
      ];
      return Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: colors[rank - 1],
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            '$rank',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      width: 30,
      child: Text(
        '$rank',
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String name;
  const _Avatar({required this.name});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events_outlined,
              size: 56, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
