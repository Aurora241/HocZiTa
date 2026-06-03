import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/word_model.dart';
import '../../data/models/score_model.dart';
import '../auth/auth_providers.dart';
import 'game_widgets.dart';

const _kStart = Color(0xFF7C3AED);
const _kEnd = Color(0xFF9F67FA);

class CompareGameScreen extends ConsumerStatefulWidget {
  final String level;
  const CompareGameScreen({super.key, required this.level});

  @override
  ConsumerState<CompareGameScreen> createState() => _CompareGameScreenState();
}

class _CompareGameScreenState extends ConsumerState<CompareGameScreen> {
  List<MathQuestionModel> _questions = [];
  bool _loading = true;

  int _currentIndex = 0;
  int _correctCount = 0;
  int _totalElapsed = 0;
  String? _selectedSymbol;
  bool _finished = false;

  // For each question: the number placed on the right side (non-answer choice)
  late List<int> _rightValues;
  // Whether the answer (larger-valued side) is on the left
  late List<bool> _answerOnLeft;

  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    final qs = await ref
        .read(gameRepoProvider)
        .getMathQuestions('compare', widget.level);
    final rng = Random();
    final shuffled = List<MathQuestionModel>.from(qs)..shuffle(rng);

    _rightValues = shuffled.map((q) {
      final others = q.choices.where((c) => c != q.answer).toList();
      return others[rng.nextInt(others.length)];
    }).toList();

    _answerOnLeft = List.generate(shuffled.length, (_) => rng.nextBool());

    setState(() {
      _questions = shuffled;
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

  int get _leftNum {
    final q = _questions[_currentIndex];
    return _answerOnLeft[_currentIndex] ? q.answer : _rightValues[_currentIndex];
  }

  int get _rightNum {
    final q = _questions[_currentIndex];
    return _answerOnLeft[_currentIndex] ? _rightValues[_currentIndex] : q.answer;
  }

  String get _correctSymbol {
    final l = _leftNum;
    final r = _rightNum;
    if (l > r) return '>';
    if (l < r) return '<';
    return '=';
  }

  void _onSymbol(String symbol) {
    if (_selectedSymbol != null) return;
    setState(() {
      _selectedSymbol = symbol;
      if (symbol == _correctSymbol) _correctCount++;
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
          _selectedSymbol = null;
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
      gameId: 'compare_game',
      gameTitle: 'So Sánh',
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
    final rng = Random();
    final shuffled = List<MathQuestionModel>.from(_questions)..shuffle(rng);
    final newRight = shuffled.map((q) {
      final others = q.choices.where((c) => c != q.answer).toList();
      return others[rng.nextInt(others.length)];
    }).toList();
    final newLeft = List.generate(shuffled.length, (_) => rng.nextBool());

    setState(() {
      _questions = shuffled;
      _rightValues = newRight;
      _answerOnLeft = newLeft;
      _currentIndex = 0;
      _correctCount = 0;
      _totalElapsed = 0;
      _selectedSymbol = null;
      _finished = false;
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
        title: 'So Sánh',
        onReplay: _replay,
        onExit: () => Navigator.pop(context),
      );
    }
    return _buildGame();
  }

  Widget _buildGame() {
    final progress = (_currentIndex + 1) / _questions.length;
    final left = _leftNum;
    final right = _rightNum;
    final answered = _selectedSymbol != null;
    final correct = _correctSymbol;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
              title: 'So Sánh',
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

            // Comparison display
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Chọn dấu so sánh đúng',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _NumberBox(value: left),
                          const SizedBox(width: 16),
                          _SymbolBox(
                            symbol: answered ? correct : '?',
                            isRevealed: answered,
                          ),
                          const SizedBox(width: 16),
                          _NumberBox(value: right),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3 symbol buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
              child: Row(
                children: [
                  for (final sym in ['<', '=', '>']) ...[
                    Expanded(
                      child: _SymbolBtn(
                        symbol: sym,
                        state: _btnState(sym, correct, answered),
                        onTap: answered ? null : () => _onSymbol(sym),
                      ),
                    ),
                    if (sym != '>') const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  _BtnState _btnState(String sym, String correct, bool answered) {
    if (!answered) return _BtnState.normal;
    if (sym == correct) return _BtnState.correct;
    if (sym == _selectedSymbol) return _BtnState.wrong;
    return _BtnState.dim;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _NumberBox extends StatelessWidget {
  final int value;
  const _NumberBox({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kStart, _kEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _kStart.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$value',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _SymbolBox extends StatelessWidget {
  final String symbol;
  final bool isRevealed;
  const _SymbolBox({required this.symbol, required this.isRevealed});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isRevealed
            ? AppColors.success.withValues(alpha: 0.12)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRevealed ? AppColors.success : AppColors.divider,
          width: 2,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        symbol,
        style: TextStyle(
          fontSize: 26,
          fontWeight: FontWeight.bold,
          color: isRevealed ? AppColors.success : AppColors.textSecondary,
        ),
      ),
    );
  }
}

enum _BtnState { normal, correct, wrong, dim }

class _SymbolBtn extends StatelessWidget {
  final String symbol;
  final _BtnState state;
  final VoidCallback? onTap;

  const _SymbolBtn({required this.symbol, required this.state, this.onTap});

  @override
  Widget build(BuildContext context) {
    final Color bg, border, fg;
    switch (state) {
      case _BtnState.correct:
        bg = AppColors.success.withValues(alpha: 0.12);
        border = AppColors.success;
        fg = AppColors.success;
      case _BtnState.wrong:
        bg = AppColors.error.withValues(alpha: 0.12);
        border = AppColors.error;
        fg = AppColors.error;
      case _BtnState.dim:
        bg = Colors.white;
        border = AppColors.divider;
        fg = AppColors.textHint;
      case _BtnState.normal:
        bg = Colors.white;
        border = _kStart.withValues(alpha: 0.4);
        fg = _kStart;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 64,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 2),
          boxShadow: state == _BtnState.normal
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
          symbol,
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: fg,
          ),
        ),
      ),
    );
  }
}
