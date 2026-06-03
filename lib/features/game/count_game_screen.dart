import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/word_model.dart';
import '../../data/models/score_model.dart';
import '../auth/auth_providers.dart';
import 'game_widgets.dart';

const _kStart = Color(0xFF7C3AED);
const _kEnd = Color(0xFF9F67FA);

enum _CS { normal, correct, wrong, dim }

class CountGameScreen extends ConsumerStatefulWidget {
  final String level;
  const CountGameScreen({super.key, required this.level});

  @override
  ConsumerState<CountGameScreen> createState() => _CountGameScreenState();
}

class _CountGameScreenState extends ConsumerState<CountGameScreen> {
  List<MathQuestionModel> _questions = [];
  bool _loading = true;

  int _currentIndex = 0;
  int _correctCount = 0;
  int _totalElapsed = 0;
  int? _selectedIdx;
  bool _finished = false;

  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final qs = await ref
        .read(gameRepoProvider)
        .getMathQuestions('count', widget.level);
    setState(() {
      _questions = List.from(qs)..shuffle();
      _loading = false;
    });
    _startTimer();
  }

  void _startTimer() {
    _elapsedTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() => _totalElapsed++);
      },
    );
  }

  void _onAnswered(int idx) {
    if (_selectedIdx != null) return;
    final q = _questions[_currentIndex];
    setState(() {
      _selectedIdx = idx;
      if (q.choices[idx] == q.answer) _correctCount++;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_currentIndex >= _questions.length - 1) {
        _elapsedTimer?.cancel();
        _saveScore();
        setState(() => _finished = true);
      } else {
        setState(() {
          _currentIndex++;
          _selectedIdx = null;
        });
      }
    });
  }

  int _calcStars() {
    if (_correctCount < _questions.length) return 1;
    if (_totalElapsed <= 40) return 3;
    if (_totalElapsed <= 80) return 2;
    return 1;
  }

  Future<void> _saveScore() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref.read(gameRepoProvider).saveScore(ScoreModel(
      userId: user.id,
      gameId: 'count_game',
      gameTitle: 'Đếm Số',
      level: widget.level.toUpperCase(),
      stars: _calcStars(),
      totalSeconds: _totalElapsed,
      correctCount: _correctCount,
      playedAt: DateTime.now(),
    ));
    ref.read(scoreVersionProvider.notifier).update((v) => v + 1);
  }

  void _replay() {
    _elapsedTimer?.cancel();
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _totalElapsed = 0;
      _selectedIdx = null;
      _finished = false;
      _questions.shuffle();
    });
    _startTimer();
  }

  @override
  void dispose() {
    _elapsedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_finished) {
      return ResultScreen(
        stars: _calcStars(),
        correctCount: _correctCount,
        totalCount: _questions.length,
        totalSeconds: _totalElapsed,
        color: _kStart,
        title: 'Đếm Số',
        onReplay: _replay,
        onExit: () => Navigator.pop(context),
      );
    }
    return _buildGame();
  }

  Widget _buildGame() {
    final q = _questions[_currentIndex];
    final progress = (_currentIndex + 1) / _questions.length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
              title: 'Đếm Số',
              level: widget.level,
              startColor: _kStart,
              endColor: _kEnd,
              onBack: () => Navigator.pop(context),
            ),

            // Progress
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    '${_currentIndex + 1} / ${_questions.length}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: AppColors.divider,
                        color: _kStart,
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Dots card
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Đếm và chọn số đúng',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _DotsGrid(count: q.answer),
                    ],
                  ),
                ),
              ),
            ),

            // 4 choices
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(q.choices.length, (i) {
                  return _ChoiceBtn(
                    label: '${q.choices[i]}',
                    state: _choiceState(i, q.answer),
                    onTap: _selectedIdx == null ? () => _onAnswered(i) : null,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _CS _choiceState(int idx, int correct) {
    if (_selectedIdx == null) return _CS.normal;
    if (_questions[_currentIndex].choices[idx] == correct) return _CS.correct;
    if (idx == _selectedIdx) return _CS.wrong;
    return _CS.dim;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Dots display — adapts size based on count
// ─────────────────────────────────────────────────────────────────────────────

class _DotsGrid extends StatelessWidget {
  final int count;
  const _DotsGrid({required this.count});

  @override
  Widget build(BuildContext context) {
    final double size = count <= 5
        ? 42
        : count <= 10
            ? 34
            : count <= 20
                ? 24
                : 18;
    final double gap = count <= 5
        ? 12
        : count <= 10
            ? 10
            : count <= 20
                ? 7
                : 5;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      alignment: WrapAlignment.center,
      children: List.generate(
        count,
        (i) => Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: _kStart,
            shape: BoxShape.circle,
          ),
          child: count <= 5
              ? const Icon(Icons.star_rounded, color: Colors.white, size: 22)
              : null,
        ),
      ),
    );
  }
}

class _ChoiceBtn extends StatelessWidget {
  final String label;
  final _CS state;
  final VoidCallback? onTap;

  const _ChoiceBtn({required this.label, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color bg, border, fg;
    switch (state) {
      case _CS.correct:
        bg = AppColors.success.withValues(alpha: 0.12);
        border = AppColors.success;
        fg = AppColors.success;
      case _CS.wrong:
        bg = AppColors.error.withValues(alpha: 0.12);
        border = AppColors.error;
        fg = AppColors.error;
      case _CS.dim:
        bg = Colors.white;
        border = AppColors.divider;
        fg = AppColors.textHint;
      case _CS.normal:
        bg = Colors.white;
        border = AppColors.divider;
        fg = AppColors.textPrimary;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.5),
          boxShadow: state == _CS.normal
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ),
    );
  }
}
