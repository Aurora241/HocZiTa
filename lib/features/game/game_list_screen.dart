import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_background.dart';
import 'flashcard_speed_run_screen.dart';
import 'memory_match_screen.dart';
import 'picture_guess_screen.dart';
import 'count_game_screen.dart';
import 'calculate_game_screen.dart';
import 'compare_game_screen.dart';

class GameListScreen extends StatelessWidget {
  final String category; // 'language' | 'math'
  const GameListScreen({super.key, required this.category});

  bool get _isLanguage => category == 'language';
  Color get _startColor =>
      _isLanguage ? const Color(0xFF0077BB) : const Color(0xFF7C3AED);
  Color get _endColor =>
      _isLanguage ? const Color(0xFF00AADD) : const Color(0xFF9F67FA);
  String get _title => _isLanguage ? 'Foreign Language' : 'Toán học';

  List<_GameItem> get _items => _isLanguage ? _languageGames : _mathGames;

  static final _languageGames = [
    _GameItem(
      icon: Icons.style_rounded,
      title: 'Flashcard Speed Run',
      description: 'Lật thẻ từ vựng — đúng càng nhanh càng nhiều sao',
      screenBuilder: (level) => FlashcardSpeedRunScreen(level: level),
    ),
    _GameItem(
      icon: Icons.grid_view_rounded,
      title: 'Memory Match',
      description: 'Ghép đôi từ và nghĩa — lật ít lần nhất',
      screenBuilder: (level) => MemoryMatchScreen(level: level),
    ),
    _GameItem(
      icon: Icons.image_rounded,
      title: 'Picture Guess',
      description: 'Nhìn hình đoán từ — thử thách trực giác',
      screenBuilder: (level) => PictureGuessScreen(level: level),
    ),
  ];

  static final _mathGames = [
    _GameItem(
      icon: Icons.tag_rounded,
      title: 'Đếm số',
      description: 'Đếm vật thể trong hình — luyện phản xạ số',
      screenBuilder: (level) => CountGameScreen(level: level),
    ),
    _GameItem(
      icon: Icons.add_circle_outline_rounded,
      title: 'Thêm bớt',
      description: 'Giải phép tính nhanh — đua với đồng hồ',
      screenBuilder: (level) => CalculateGameScreen(level: level),
    ),
    _GameItem(
      icon: Icons.balance_rounded,
      title: 'So sánh',
      description: 'Chọn số lớn hơn / nhỏ hơn — phán đoán nhanh',
      screenBuilder: (level) => CompareGameScreen(level: level),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppAuroraBackground(),
          SafeArea(
            child: Column(
              children: [
            _Header(
              title: _title,
              startColor: _startColor,
              endColor: _endColor,
            )
                .animate()
                .slideY(
                  begin: -1,
                  end: 0,
                  duration: 500.ms,
                  curve: Curves.easeOutCubic,
                )
                .fadeIn(duration: 400.ms),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                itemCount: _items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _GameCard(
                  item: _items[i],
                  color: _startColor,
                  animationDelay: Duration(milliseconds: 150 + i * 80),
                  onSelect: (level) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _items[i].screenBuilder(level),
                    ),
                  ),
                ),
              ),
            ),
          ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GameItem {
  final IconData icon;
  final String title;
  final String description;
  final Widget Function(String level) screenBuilder;

  _GameItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.screenBuilder,
  });
}

// ─────────────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final String title;
  final Color startColor;
  final Color endColor;

  const _Header({
    required this.title,
    required this.startColor,
    required this.endColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 24, 24),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Chọn game và cấp độ',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _GameCard extends StatelessWidget {
  final _GameItem item;
  final Color color;
  final Duration animationDelay;
  final void Function(String level) onSelect;

  const _GameCard({
    required this.item,
    required this.color,
    required this.animationDelay,
    required this.onSelect,
  });

  void _showLevelPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LevelPickerSheet(
        title: item.title,
        color: color,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLevelPicker(context),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '3 cấp độ  A · B · C',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textSecondary),
          ],
        ),
      ),
    )
        .animate()
        .slideX(
          begin: -0.3,
          end: 0,
          delay: animationDelay,
          duration: 450.ms,
          curve: Curves.easeOutCubic,
        )
        .fadeIn(delay: animationDelay, duration: 400.ms);
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _LevelPickerSheet extends StatelessWidget {
  final String title;
  final Color color;
  final void Function(String level) onSelect;

  const _LevelPickerSheet({
    required this.title,
    required this.color,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chọn cấp độ để bắt đầu',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _LevelBtn(
            level: 'A',
            label: 'Cấp A  —  Cơ bản',
            color: AppColors.levelA,
            onTap: () { Navigator.pop(context); onSelect('a'); },
          ),
          const SizedBox(height: 12),
          _LevelBtn(
            level: 'B',
            label: 'Cấp B  —  Trung cấp',
            color: AppColors.levelB,
            onTap: () { Navigator.pop(context); onSelect('b'); },
          ),
          const SizedBox(height: 12),
          _LevelBtn(
            level: 'C',
            label: 'Cấp C  —  Nâng cao',
            color: AppColors.levelC,
            onTap: () { Navigator.pop(context); onSelect('c'); },
          ),
        ],
      ),
    );
  }
}

class _LevelBtn extends StatelessWidget {
  final String level;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _LevelBtn({
    required this.level,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  level,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(label,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
