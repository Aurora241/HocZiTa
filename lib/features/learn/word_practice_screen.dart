import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/models/word_model.dart';

class WordPracticeScreen extends StatefulWidget {
  final String level; // 'a' | 'b' | 'c'
  const WordPracticeScreen({super.key, required this.level});

  @override
  State<WordPracticeScreen> createState() => _WordPracticeScreenState();
}

class _WordPracticeScreenState extends State<WordPracticeScreen> {
  final _ds = LocalDataSource();
  List<_Question> _questions = [];
  bool _loading = true;

  int _current = 0;
  int _correctCount = 0;
  int? _selectedIndex;   // index đáp án đã chọn, null = chưa chọn
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final words = await _ds.getWords(widget.level);
    final rng = Random();
    final questions = words.map((w) {
      // 3 đáp án sai lấy ngẫu nhiên từ các từ khác
      final others = words.where((x) => x.id != w.id).toList()..shuffle(rng);
      final choices = [w.meaning, ...others.take(3).map((x) => x.meaning)]
        ..shuffle(rng);
      final correctIdx = choices.indexOf(w.meaning);
      return _Question(word: w, choices: choices, correctIndex: correctIdx);
    }).toList();

    setState(() {
      _questions = questions;
      _loading = false;
    });
  }

  void _onChoiceTap(int idx) {
    if (_selectedIndex != null) return; // đã chọn rồi
    setState(() {
      _selectedIndex = idx;
      if (idx == _questions[_current].correctIndex) _correctCount++;
    });
  }

  void _next() {
    if (_current + 1 >= _questions.length) {
      setState(() => _isDone = true);
    } else {
      setState(() {
        _current++;
        _selectedIndex = null;
      });
    }
  }

  void _restart() {
    setState(() {
      _current = 0;
      _correctCount = 0;
      _selectedIndex = null;
      _isDone = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final levelLabel = widget.level.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Foreign Language  •  Cấp $levelLabel'),
        leading: const BackButton(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _isDone
              ? _SummaryView(
                  correct: _correctCount,
                  total: _questions.length,
                  onRestart: _restart,
                  onBack: () => Navigator.pop(context),
                )
              : _QuizView(
                  question: _questions[_current],
                  current: _current,
                  total: _questions.length,
                  selectedIndex: _selectedIndex,
                  onChoiceTap: _onChoiceTap,
                  onNext: _next,
                ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quiz view
// ─────────────────────────────────────────────────────────────────────────────

class _QuizView extends StatelessWidget {
  final _Question question;
  final int current;
  final int total;
  final int? selectedIndex;
  final void Function(int) onChoiceTap;
  final VoidCallback onNext;

  const _QuizView({
    required this.question,
    required this.current,
    required this.total,
    required this.selectedIndex,
    required this.onChoiceTap,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final answered = selectedIndex != null;

    return Column(
      children: [
        // Progress bar
        _ProgressBar(current: current + 1, total: total),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Thẻ từ
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 28),
                  padding: const EdgeInsets.symmetric(
                      vertical: 48, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0077BB), Color(0xFF00AADD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        question.word.word,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Nghĩa tiếng Việt là gì?',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                // 4 đáp án (2 cột)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.4,
                  children: List.generate(
                    question.choices.length,
                    (i) => _ChoiceButton(
                      label: question.choices[i],
                      state: _choiceState(i, answered),
                      onTap: () => onChoiceTap(i),
                    ),
                  ),
                ),

                // Feedback + nút tiếp
                if (answered) ...[
                  const SizedBox(height: 20),
                  _FeedbackRow(
                    isCorrect: selectedIndex == question.correctIndex,
                    correctAnswer: question.choices[question.correctIndex],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onNext,
                      child: const Text('Tiếp theo  →'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  _BtnState _choiceState(int idx, bool answered) {
    if (!answered) return _BtnState.normal;
    if (idx == question.correctIndex) return _BtnState.correct;
    if (idx == selectedIndex) return _BtnState.wrong;
    return _BtnState.dimmed;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const _ProgressBar({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Câu $current / $total',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${((current / total) * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: current / total,
              minHeight: 6,
              backgroundColor: AppColors.divider,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

enum _BtnState { normal, correct, wrong, dimmed }

class _ChoiceButton extends StatelessWidget {
  final String label;
  final _BtnState state;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color bg, border, textColor;
    switch (state) {
      case _BtnState.correct:
        bg = AppColors.success.withValues(alpha: 0.15);
        border = AppColors.success;
        textColor = AppColors.success;
      case _BtnState.wrong:
        bg = AppColors.error.withValues(alpha: 0.12);
        border = AppColors.error;
        textColor = AppColors.error;
      case _BtnState.dimmed:
        bg = Colors.grey[100]!;
        border = AppColors.divider;
        textColor = AppColors.textHint;
      case _BtnState.normal:
        bg = Colors.white;
        border = AppColors.divider;
        textColor = AppColors.textPrimary;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  final bool isCorrect;
  final String correctAnswer;
  const _FeedbackRow({required this.isCorrect, required this.correctAnswer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.success.withValues(alpha: 0.1)
            : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCorrect
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.error.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isCorrect
                ? Icons.check_circle_rounded
                : Icons.cancel_rounded,
            color: isCorrect ? AppColors.success : AppColors.error,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              isCorrect
                  ? 'Chính xác! 🎉'
                  : 'Sai rồi! Đáp án đúng: $correctAnswer',
              style: TextStyle(
                color: isCorrect ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary view
// ─────────────────────────────────────────────────────────────────────────────

class _SummaryView extends StatelessWidget {
  final int correct;
  final int total;
  final VoidCallback onRestart;
  final VoidCallback onBack;

  const _SummaryView({
    required this.correct,
    required this.total,
    required this.onRestart,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (correct / total * 100).round();
    final emoji = pct >= 80 ? '🎉' : pct >= 50 ? '👍' : '💪';
    final msg = pct >= 80 ? 'Xuất sắc!' : pct >= 50 ? 'Khá tốt!' : 'Cố lên nha!';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              msg,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '$correct / $total câu đúng  ($pct%)',
              style: const TextStyle(
                fontSize: 18,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Làm lại'),
                onPressed: onRestart,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Về trang học'),
                onPressed: onBack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _Question {
  final WordModel word;
  final List<String> choices;
  final int correctIndex;

  const _Question({
    required this.word,
    required this.choices,
    required this.correctIndex,
  });
}
