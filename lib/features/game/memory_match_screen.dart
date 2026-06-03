import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/word_model.dart';
import '../../data/models/score_model.dart';
import '../auth/auth_providers.dart';
import 'game_widgets.dart';

class _Card {
  final int pairId;
  final String text;
  final bool isEnglish;
  bool isFlipped;
  bool isMatched;

  _Card({
    required this.pairId,
    required this.text,
    required this.isEnglish,
  })  : isFlipped = false,
        isMatched = false;
}

// ─────────────────────────────────────────────────────────────────────────────

class MemoryMatchScreen extends ConsumerStatefulWidget {
  final String level;
  const MemoryMatchScreen({super.key, required this.level});

  @override
  ConsumerState<MemoryMatchScreen> createState() =>
      _MemoryMatchScreenState();
}

class _MemoryMatchScreenState
    extends ConsumerState<MemoryMatchScreen> {
  static const _pairsCount = 8;

  List<_Card> _cards = [];
  bool _loading = true;

  int _matchedPairs = 0;
  int _elapsedSeconds = 0;
  bool _finished = false;

  int? _firstIndex;
  int? _secondIndex;
  bool _isChecking = false;

  Timer? _elapsedTimer;

  @override
  void initState() {
    super.initState();
    _loadCards();
  }

  Future<void> _loadCards() async {
    final words =
        await ref.read(gameRepoProvider).getWordsForGame(widget.level);
    final picked = (List<WordModel>.from(words)..shuffle())
        .take(_pairsCount)
        .toList();

    final cards = <_Card>[];
    for (int i = 0; i < picked.length; i++) {
      cards.add(_Card(pairId: i, text: picked[i].word, isEnglish: true));
      cards.add(
          _Card(pairId: i, text: picked[i].meaning, isEnglish: false));
    }
    cards.shuffle();

    setState(() {
      _cards = cards;
      _loading = false;
    });

    _elapsedTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) { if (mounted) setState(() => _elapsedSeconds++); },
    );
  }

  void _onCardTap(int index) {
    if (_isChecking) return;
    final card = _cards[index];
    if (card.isFlipped || card.isMatched) return;

    if (_firstIndex == null) {
      setState(() {
        _cards[index].isFlipped = true;
        _firstIndex = index;
      });
      return;
    }

    // Second card
    setState(() {
      _cards[index].isFlipped = true;
      _secondIndex = index;
      _isChecking = true;
    });

    final first = _cards[_firstIndex!];
    final second = _cards[_secondIndex!];

    if (first.pairId == second.pairId) {
      // Match!
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _cards[_firstIndex!].isMatched = true;
          _cards[_secondIndex!].isMatched = true;
          _matchedPairs++;
          _firstIndex = null;
          _secondIndex = null;
          _isChecking = false;
        });
        if (_matchedPairs == _pairsCount) {
          _elapsedTimer?.cancel();
          _saveScore();
          setState(() => _finished = true);
        }
      });
    } else {
      // No match — úp lại sau 800ms
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _cards[_firstIndex!].isFlipped = false;
          _cards[_secondIndex!].isFlipped = false;
          _firstIndex = null;
          _secondIndex = null;
          _isChecking = false;
        });
      });
    }
  }

  int _calcStars() {
    if (_elapsedSeconds <= 60) return 3;
    if (_elapsedSeconds <= 120) return 2;
    return 1;
  }

  Future<void> _saveScore() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref.read(gameRepoProvider).saveScore(ScoreModel(
      userId: user.id,
      gameId: 'memory_match',
      gameTitle: 'Memory Match',
      level: widget.level.toUpperCase(),
      stars: _calcStars(),
      totalSeconds: _elapsedSeconds,
      correctCount: _pairsCount,
      playedAt: DateTime.now(),
    ));
    ref.read(scoreVersionProvider.notifier).update((v) => v + 1);
  }

  void _replay() {
    _elapsedTimer?.cancel();
    for (final c in _cards) {
      c.isFlipped = false;
      c.isMatched = false;
    }
    setState(() {
      _cards.shuffle();
      _matchedPairs = 0;
      _elapsedSeconds = 0;
      _finished = false;
      _firstIndex = null;
      _secondIndex = null;
      _isChecking = false;
    });
    _elapsedTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) { if (mounted) setState(() => _elapsedSeconds++); },
    );
  }

  String _formatTime(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
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
        correctCount: _pairsCount,
        totalCount: _pairsCount,
        totalSeconds: _elapsedSeconds,
        color: AppColors.primary,
        title: 'Memory Match',
        onReplay: _replay,
        onExit: () => Navigator.pop(context),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            GameHeader(
              title: 'Memory Match',
              level: widget.level,
              startColor: AppColors.primary,
              endColor: const Color(0xFF00AADD),
              onBack: () => Navigator.pop(context),
            ),

            // ── Timer + progress ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Pairs counter
                  Row(
                    children: [
                      const Icon(Icons.grid_view_rounded,
                          size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        '$_matchedPairs / $_pairsCount cặp',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Stopwatch
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_rounded,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(_elapsedSeconds),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Card grid 4×4 ──────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: _cards.length,
                  itemBuilder: (context, i) => _MemoryCard(
                    card: _cards[i],
                    onTap: () => _onCardTap(i),
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
// Memory card widget
// ─────────────────────────────────────────────────────────────────────────────

class _MemoryCard extends StatelessWidget {
  final _Card card;
  final VoidCallback onTap;

  const _MemoryCard({required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool show = card.isFlipped || card.isMatched;

    Color bg;
    Color textColor;
    BoxBorder? border;

    if (card.isMatched) {
      bg = AppColors.success.withValues(alpha: 0.15);
      textColor = AppColors.success;
      border = Border.all(color: AppColors.success, width: 1.5);
    } else if (show) {
      bg = Colors.white;
      textColor = card.isEnglish ? AppColors.primary : AppColors.textPrimary;
      border = Border.all(
        color: card.isEnglish ? AppColors.primary : AppColors.divider,
        width: 1.5,
      );
    } else {
      bg = AppColors.primary;
      textColor = Colors.white;
      border = null;
    }

    return GestureDetector(
      onTap: show ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: border,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: show
                ? Padding(
                    key: ValueKey(card.text),
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      card.text,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: card.isEnglish
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: textColor,
                        height: 1.3,
                      ),
                    ),
                  )
                : const Icon(
                    key: ValueKey('hidden'),
                    Icons.question_mark_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
          ),
        ),
      ),
    );
  }
}
