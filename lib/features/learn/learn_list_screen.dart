import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
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
      description: 'Dịch từ EN→VN, 4 lựa chọn • 15 từ / cấp',
      levelCount: '3 cấp độ  A · B · C',
      screenBuilder: (level) => WordPracticeScreen(level: level),
    ),
  ];

  static final _mathItems = [
    _PracticeItem(
      icon: Icons.tag_rounded,
      color: const Color(0xFF0EA5E9),
      title: 'Đếm số',
      description: 'Đếm vật thể trong hình — nhận diện số',
      levelCount: '3 cấp độ  A · B · C',
      screenBuilder: (level) => MathPracticeScreen(type: 'count', level: level),
    ),
    _PracticeItem(
      icon: Icons.add_circle_outline_rounded,
      color: const Color(0xFF10B981),
      title: 'Thêm bớt',
      description: 'Phép tính cộng trừ cơ bản — luyện tính nhẩm',
      levelCount: '3 cấp độ  A · B · C',
      screenBuilder: (level) =>
          MathPracticeScreen(type: 'calculate', level: level),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              title: _title,
              startColor: _startColor,
              endColor: _endColor,
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                itemCount: _items.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _PracticeCard(
                  item: _items[i],
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PracticeItem {
  final IconData icon;
  final Color color;
  final String title;
  final String description;
  final String levelCount;
  final Widget Function(String level) screenBuilder;

  _PracticeItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
    required this.levelCount,
    required this.screenBuilder,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Header với back button
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
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(28)),
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
                'Chọn bài học và cấp độ',
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
// Practice card
// ─────────────────────────────────────────────────────────────────────────────

class _PracticeCard extends StatelessWidget {
  final _PracticeItem item;
  final void Function(String level) onSelect;

  const _PracticeCard({required this.item, required this.onSelect});

  void _showLevelPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LevelPickerSheet(
        title: item.title,
        color: item.color,
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
              color: item.color.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      item.levelCount,
                      style: TextStyle(
                        fontSize: 11,
                        color: item.color,
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Level picker sheet
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
            'Chọn cấp độ phù hợp với bạn',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          _LevelBtn(
            level: 'A',
            label: 'Cấp A  —  Cơ bản',
            color: AppColors.levelA,
            onTap: () {
              Navigator.pop(context);
              onSelect('a');
            },
          ),
          const SizedBox(height: 12),
          _LevelBtn(
            level: 'B',
            label: 'Cấp B  —  Trung cấp',
            color: AppColors.levelB,
            onTap: () {
              Navigator.pop(context);
              onSelect('b');
            },
          ),
          const SizedBox(height: 12),
          _LevelBtn(
            level: 'C',
            label: 'Cấp C  —  Nâng cao',
            color: AppColors.levelC,
            onTap: () {
              Navigator.pop(context);
              onSelect('c');
            },
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
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
