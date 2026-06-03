import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/word_model.dart';
import '../../data/models/score_model.dart';
import '../auth/auth_providers.dart';
import 'game_widgets.dart';

class FlashcardSpeedRunScreen extends ConsumerStatefulWidget {
  final String level;
  const FlashcardSpeedRunScreen({super.key, required this.level});

  @override
  ConsumerState<FlashcardSpeedRunScreen> createState() =>
      _FlashcardSpeedRunScreenState();
}

class _FlashcardSpeedRunScreenState
    extends ConsumerState<FlashcardSpeedRunScreen> {
  static const _questionSeconds = 6;

  List<WordModel> _words = [];
  bool _loading = true;

  int _currentIndex = 0;
  int _correctCount = 0;
  int _totalElapsed = 0;
  int _questionTimer = _questionSeconds;
  int? _selectedChoice; // index trong _choices, -1 = hết giờ
  bool _finished = false;
  List<String> _choices = [];

  Timer? _qTimer;
  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  Future<void> _loadWords() async {
    final words =
        await ref.read(gameRepoProvider).getWordsForGame(widget.level);
    setState(() {
      _words = List.from(words)..shuffle();
      _loading = false;
    });
    _startQuestion();
  }

  void _startQuestion() {
    _elapsedTimer ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) { if (mounted) setState(() => _totalElapsed++); },
    );

    final correct = _words[_currentIndex].meaning;
    final distractors = _words
        .where((w) => w.meaning != correct)
        .map((w) => w.meaning)
        .toList()
      ..shuffle();

    setState(() {
      _choices = ([correct] + distractors.take(3).toList())..shuffle();
      _selectedChoice = null;
      _questionTimer = _questionSeconds;
    });

    _qTimer?.cancel();
    _qTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_questionTimer <= 1) {
        t.cancel();
        _onAnswered(-1);
      } else {
        setState(() => _questionTimer--);
      }
    });
  }

  void _onAnswered(int idx) {
    if (_selectedChoice != null) return;
    _qTimer?.cancel();

    final correct = _words[_currentIndex].meaning;
    final hit = idx >= 0 && _choices[idx] == correct;

    setState(() {
      _selectedChoice = idx;
      if (hit) _correctCount++;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_currentIndex >= _words.length - 1) {
        _elapsedTimer?.cancel();
        _saveScore();
        setState(() => _finished = true);
      } else {
        setState(() => _currentIndex++);
        _startQuestion();
      }
    });
  }

  int _calcStars() {
    final allCorrect = _correctCount == _words.length;
    if (!allCorrect) return 1;
    if (_totalElapsed <= 20) return 3;
    if (_totalElapsed <= 40) return 2;
    return 1;
  }

  Future<void> _saveScore() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref.read(gameRepoProvider).saveScore(ScoreModel(
      userId: user.id,
      gameId: 'flashcard_speed_run',
      gameTitle: 'Flashcard Speed Run',
      level: widget.level.toUpperCase(),
      stars: _calcStars(),
      totalSeconds: _totalElapsed,
      correctCount: _correctCount,
      playedAt: DateTime.now(),
    ));
    ref.read(scoreVersionProvider.notifier).update((v) => v + 1);
  }

  void _replay() {
    _qTimer?.cancel();
    _elapsedTimer?.cancel();
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _totalElapsed = 0;
      _questionTimer = _questionSeconds;
      _selectedChoice = null;
      _finished = false;
      _elapsedTimer = null;
      _words.shuffle();
    });
    _startQuestion();
  }

  @override
  void dispose() {
    _qTimer?.cancel();
    _elapsedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }
    if (_finished) {
      return ResultScreen(
        stars: _calcStars(),
        correctCount: _correctCount,
        totalCount: _words.length,
        totalSeconds: _totalElapsed,
        color: AppColors.primary,
        title: 'Flashcard Speed Run',
        onReplay: _replay,
        onExit: () => Navigator.pop(context),
      );
    }

    return _buildGame();
  }

  Widget _buildGame() {
    final word = _words[_currentIndex];
    final progress = (_currentIndex + 1) / _words.length;
    final timerRatio = _questionTimer / _questionSeconds;
    final timerColor = timerRatio > 0.5
        ? AppColors.success
        : timerRatio > 0.25
            ? AppColors.warning
            : AppColors.error;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
              title: 'Flashcard Speed Run',
              level: widget.level,
              startColor: AppColors.primary,
              endColor: const Color(0xFF00AADD),
              onBack: () => Navigator.pop(context),
            ),

            // ── Progress ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    '${_currentIndex + 1} / ${_words.length}',
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
                        color: AppColors.primary,
                        minHeight: 6,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Countdown timer ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Icon(Icons.timer_rounded, size: 16, color: timerColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: timerRatio,
                        backgroundColor: AppColors.divider,
                        color: timerColor,
                        minHeight: 7,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 18,
                    child: Text(
                      '$_questionTimer',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: timerColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Word card ──────────────────────────────────────────────
            Expanded(
              child: Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 28),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 36),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0077BB), Color(0xFF00AADD)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Từ tiếng Anh',
                        style: TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        word.word,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 44,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── 4 choices ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.6,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(_choices.length, (i) {
                  return _ChoiceButton(
                    text: _choices[i],
                    state: _choiceState(i, word.meaning),
                    onTap: _selectedChoice == null
                        ? () => _onAnswered(i)
                        : null,
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _ChoiceState _choiceState(int idx, String correctMeaning) {
    if (_selectedChoice == null) return _ChoiceState.normal;
    if (_choices[idx] == correctMeaning) return _ChoiceState.correct;
    if (idx == _selectedChoice) return _ChoiceState.wrong;
    return _ChoiceState.dim;
  }
}

// ─────────────────────────────────────────────────────────────────────────────

enum _ChoiceState { normal, correct, wrong, dim }

class _ChoiceButton extends StatelessWidget {
  final String text;
  final _ChoiceState state;
  final VoidCallback? onTap;

  const _ChoiceButton({
    required this.text,
    required this.state,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color border;
    final Color textColor;

    switch (state) {
      case _ChoiceState.correct:
        bg = AppColors.success.withValues(alpha: 0.12);
        border = AppColors.success;
        textColor = AppColors.success;
      case _ChoiceState.wrong:
        bg = AppColors.error.withValues(alpha: 0.12);
        border = AppColors.error;
        textColor = AppColors.error;
      case _ChoiceState.dim:
        bg = Colors.white;
        border = AppColors.divider;
        textColor = AppColors.textHint;
      case _ChoiceState.normal:
        bg = Colors.white;
        border = AppColors.divider;
        textColor = AppColors.textPrimary;
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 1.5),
          boxShadow: state == _ChoiceState.normal
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
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
