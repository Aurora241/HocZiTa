import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/datasources/local_datasource.dart';
import '../../data/models/word_model.dart';

class MathPracticeScreen extends StatefulWidget {
  final String type;  // 'count' | 'calculate'
  final String level; // 'a' | 'b' | 'c'

  const MathPracticeScreen({
    super.key,
    required this.type,
    required this.level,
  });

  @override
  State<MathPracticeScreen> createState() => _MathPracticeScreenState();
}

class _MathPracticeScreenState extends State<MathPracticeScreen> {
  final _ds = LocalDataSource();
  List<MathQuestionModel> _questions = [];
  bool _loading = true;

  int _current = 0;
  int _correctCount = 0;
  int? _selectedChoice; // giá trị đã chọn, null = chưa chọn
  bool _isDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final all = await _ds.getMathQuestions(widget.type, widget.level);
    setState(() {
      _questions = all;
      _loading = false;
    });
  }

  void _onChoiceTap(int value) {
    if (_selectedChoice != null) return;
    setState(() {
      _selectedChoice = value;
      if (value == _questions[_current].answer) _correctCount++;
    });
  }

  void _next() {
    if (_current + 1 >= _questions.length) {
      setState(() => _isDone = true);
    } else {
      setState(() {
        _current++;
        _selectedChoice = null;
      });
    }
  }

  void _restart() {
    setState(() {
      _current = 0;
      _correctCount = 0;
      _selectedChoice = null;
      _isDone = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final typeLabel = widget.type == 'count' ? 'Đếm số' : 'Thêm bớt';
    final levelLabel = widget.level.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$typeLabel  •  Cấp $levelLabel'),
        leading: const BackButton(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _questions.isEmpty
              ? const Center(child: Text('Không có câu hỏi nào'))
              : _isDone
                  ? _SummaryView(
                      correct: _correctCount,
                      total: _questions.length,
                      onRestart: _restart,
                      onBack: () => Navigator.pop(context),
                    )
                  : _QuizView(
                      question: _questions[_current],
                      type: widget.type,
                      current: _current,
                      total: _questions.length,
                      selectedChoice: _selectedChoice,
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
  final MathQuestionModel question;
  final String type;
  final int current;
  final int total;
  final int? selectedChoice;
  final void Function(int) onChoiceTap;
  final VoidCallback onNext;

  const _QuizView({
    required this.question,
    required this.type,
    required this.current,
    required this.total,
    required this.selectedChoice,
    required this.onChoiceTap,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final answered = selectedChoice != null;

    return Column(
      children: [
        _ProgressBar(current: current + 1, total: total),

        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Thẻ câu hỏi
                _QuestionCard(question: question, type: type),
                const SizedBox(height: 24),

                // 4 đáp án (2x2)
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.4,
                  children: question.choices.map((val) {
                    return _ChoiceButton(
                      value: val,
                      state: _choiceState(val, answered),
                      onTap: () => onChoiceTap(val),
                    );
                  }).toList(),
                ),

                // Feedback + nút tiếp
                if (answered) ...[
                  const SizedBox(height: 20),
                  _FeedbackRow(
                    isCorrect: selectedChoice == question.answer,
                    correctAnswer: question.answer,
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

  _BtnState _choiceState(int val, bool answered) {
    if (!answered) return _BtnState.normal;
    if (val == question.answer) return _BtnState.correct;
    if (val == selectedChoice) return _BtnState.wrong;
    return _BtnState.dimmed;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Question card — khác nhau cho count vs calculate
// ─────────────────────────────────────────────────────────────────────────────

class _QuestionCard extends StatelessWidget {
  final MathQuestionModel question;
  final String type;

  const _QuestionCard({required this.question, required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF9F67FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: type == 'count'
          ? _CountDisplay(count: question.answer)
          : _CalculateDisplay(expression: question.expression ?? '?'),
    );
  }
}

class _CountDisplay extends StatelessWidget {
  final int count;
  const _CountDisplay({required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Có bao nhiêu hình tròn?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(
            count,
            (_) => Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.6), width: 2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Đếm và chọn số đúng!',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
  }
}

class _CalculateDisplay extends StatelessWidget {
  final String expression;
  const _CalculateDisplay({required this.expression});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Kết quả phép tính là?',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 20),
        Text(
          '$expression = ?',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Điền kết quả phép tính!',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
      ],
    );
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
                    fontWeight: FontWeight.w500),
              ),
              Text(
                '${((current / total) * 100).round()}%',
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold),
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
  final int value;
  final _BtnState state;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.value,
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
            '$value',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackRow extends StatelessWidget {
  final bool isCorrect;
  final int correctAnswer;
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
            isCorrect ? Icons.check_circle_rounded : Icons.cancel_rounded,
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
    final msg =
        pct >= 80 ? 'Xuất sắc!' : pct >= 50 ? 'Khá tốt!' : 'Cố lên nha!';

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
                  fontSize: 18, color: AppColors.textSecondary),
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
