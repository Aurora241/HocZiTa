import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_background.dart';
import 'word_practice_screen.dart';
import 'math_practice_screen.dart';

class LearnListScreen extends StatelessWidget {
  final String category; // 'language' | 'math'
  const LearnListScreen({super.key, required this.category});

  bool get _isLanguage => category == 'language';
  Color get _startColor =>
      _isLanguage ? const Color(0xFF0077BB) : const Color(0xFF7C3AED);
  Color get _endColor =>
      _isLanguage ? const Color(0xFF00AADD) : const Color(0xFF9F67FA);
  String get _title => _isLanguage ? 'Foreign Language' : 'Toán học';

  List<_PracticeItem> get _items =>
      _isLanguage ? _languageItems : _mathItems;

  static final _languageItems = [
    _PracticeItem(
      icon: Icons.translate_rounded,
      color: const Color(0xFF0077BB),
      title: 'Từ vựng tiếng Anh',
      description: 'Dịch từ EN→VN, 4 lựa chọn — học bao nhiêu tuỳ thích',
      screenBuilder: () => const WordPracticeScreen(),
    ),
  ];

  static final _mathItems = [
    _PracticeItem(
      icon: Icons.tag_rounded,
      color: const Color(0xFF0EA5E9),
      title: 'Đếm số',
      description: 'Đếm vật thể trong hình — nhận diện số',
      screenBuilder: () => const MathPracticeScreen(type: 'count'),
    ),
    _PracticeItem(
      icon: Icons.add_circle_outline_rounded,
      color: const Color(0xFF10B981),
      title: 'Thêm bớt',
      description: 'Phép tính cộng trừ cơ bản — luyện tính nhẩm',
      screenBuilder: () => const MathPracticeScreen(type: 'calculate'),
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
                itemBuilder: (context, i) => _PracticeCard(
                  item: _items[i],
                  animationDelay: Duration(milliseconds: 150 + i * 80),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _items[i].screenBuilder(),
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

class _PracticeItem {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final Widget Function() screenBuilder;

  _PracticeItem({
    required this.icon,
    required this.color,
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
                'Chọn bài học',
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

class _PracticeCard extends StatelessWidget {
  final _PracticeItem item;
  final Duration animationDelay;
  final VoidCallback onTap;

  const _PracticeCard({
    required this.item,
    required this.animationDelay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: 0.12),
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
                color: item.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 28),
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

