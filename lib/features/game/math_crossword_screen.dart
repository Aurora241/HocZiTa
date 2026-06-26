import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/score_model.dart';
import '../auth/auth_providers.dart';
import 'game_widgets.dart';

const _kStart = Color(0xFF7C3AED);
const _kEnd = Color(0xFF9F67FA);

class MathCrosswordScreen extends ConsumerStatefulWidget {
  final String level;
  const MathCrosswordScreen({super.key, required this.level});

  @override
  ConsumerState<MathCrosswordScreen> createState() =>
      _MathCrosswordScreenState();
}

class _MathCrosswordScreenState extends ConsumerState<MathCrosswordScreen> {
  late List<List<int>> _grid;
  late List<List<bool>> _blanks;
  late List<List<String>> _userInput;

  (int, int)? _selectedCell;
  int _totalElapsed = 0;
  Timer? _timer;
  bool _finished = false;
  bool _checked = false;
  int _correctCount = 0;
  int _totalBlanks = 0;

  @override
  void initState() {
    super.initState();
    _initPuzzle();
    _startTimer();
  }

  void _initPuzzle() {
    final rng = Random();
    _grid = _generateGrid(rng);
    _blanks = _blankPattern(widget.level);
    _userInput = List.generate(5, (_) => List.generate(5, (_) => ''));
    _totalBlanks = 0;
    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 5; c++) {
        if (_blanks[r][c]) _totalBlanks++;
      }
    }
  }

  // Sinh lưới 5×5 hợp lệ từ 9 tham số tự do (a,b,c,d,p,q,e,f,g).
  // Mọi ràng buộc hàng/cột tự động thỏa mãn.
  List<List<int>> _generateGrid(Random rng) {
    final max = switch (widget.level) {
      'b' => 8,
      'c' => 12,
      _ => 5,
    };
    int r(int m) => rng.nextInt(m) + 1;
    final a = r(max), b = r(max), c = r(max), d = r(max);
    final p = r(max), q = r(max);
    final e = r(max), f = r(max), g = r(max);

    return [
      [a,       b,       a + b,             p,       a + b + p],
      [c,       d,       c + d,             q,       c + d + q],
      [a + c,   b + d,   a + b + c + d,     p + q,   a + b + c + d + p + q],
      [e,       f,       e + f,             g,       e + f + g],
      [a+c+e,   b+d+f,   a+b+c+d+e+f,      p+q+g,   a+b+c+d+e+f+p+q+g],
    ];
  }

  // Vị trí ô trống theo cấp độ (thiết kế để giải được từ các ô hiện)
  List<List<bool>> _blankPattern(String level) {
    final b = List.generate(5, (_) => List.generate(5, (_) => false));
    final positions = switch (level) {
      'a' => [(0, 2), (1, 4), (2, 0), (3, 2), (4, 4)],
      'b' => [
          (0, 0), (0, 4),
          (1, 2), (1, 3),
          (2, 1), (2, 3),
          (3, 0), (4, 2),
        ],
      _ => [
          (0, 0), (0, 1), (0, 3),
          (1, 0), (1, 2), (1, 4),
          (2, 2), (2, 4),
          (3, 1), (3, 3),
          (4, 0), (4, 4),
        ],
    };
    for (final (r, c) in positions) {
      b[r][c] = true;
    }
    return b;
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _totalElapsed++);
    });
  }

  void _selectCell(int r, int c) {
    if (!_blanks[r][c]) return;
    setState(() {
      _selectedCell = (r, c);
      _checked = false;
    });
  }

  void _onNumpad(String key) {
    final sel = _selectedCell;
    if (key == '✓') {
      _checkAnswers();
      return;
    }
    if (sel == null) return;
    final (r, c) = sel;
    setState(() {
      if (key == '⌫') {
        final cur = _userInput[r][c];
        if (cur.isNotEmpty) _userInput[r][c] = cur.substring(0, cur.length - 1);
      } else {
        if (_userInput[r][c].length < 3) _userInput[r][c] += key;
      }
    });
  }

  void _checkAnswers() {
    bool allFilled = true;
    int correct = 0;

    for (var r = 0; r < 5; r++) {
      for (var c = 0; c < 5; c++) {
        if (!_blanks[r][c]) continue;
        if (_userInput[r][c].isEmpty) {
          allFilled = false;
        } else if (int.tryParse(_userInput[r][c]) == _grid[r][c]) {
          correct++;
        }
      }
    }

    if (!allFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy điền tất cả các ô trống trước nhé!'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    setState(() {
      _checked = true;
      _correctCount = correct;
      _selectedCell = null;
    });

    if (correct == _totalBlanks) {
      _timer?.cancel();
      _saveScore();
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) setState(() => _finished = true);
      });
    }
  }

  int _calcStars() {
    if (_correctCount < _totalBlanks) return 1;
    if (_totalElapsed <= 60) return 3;
    if (_totalElapsed <= 120) return 2;
    return 1;
  }

  Future<void> _saveScore() async {
    final user = await ref.read(currentUserProvider.future);
    if (user == null) return;
    await ref.read(gameRepoProvider).saveScore(ScoreModel(
      userId: user.id,
      gameId: 'math_crossword',
      gameTitle: 'Math Crossword',
      level: widget.level.toUpperCase(),
      stars: _calcStars(),
      totalSeconds: _totalElapsed,
      correctCount: _correctCount,
      playedAt: DateTime.now(),
    ));
    ref.read(scoreVersionProvider.notifier).update((v) => v + 1);
  }

  void _replay() {
    _timer?.cancel();
    setState(() {
      _totalElapsed = 0;
      _checked = false;
      _finished = false;
      _selectedCell = null;
      _initPuzzle();
    });
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_finished) {
      return ResultScreen(
        stars: _calcStars(),
        correctCount: _correctCount,
        totalCount: _totalBlanks,
        totalSeconds: _totalElapsed,
        color: _kStart,
        title: 'Math Crossword',
        onReplay: _replay,
        onExit: () => Navigator.pop(context),
      );
    }
    return _buildGame();
  }

  Widget _buildGame() {
    final mins = _totalElapsed ~/ 60;
    final secs = _totalElapsed % 60;
    final timeStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kStart, _kEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 4),
                  const Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Math Crossword',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        _GridIcon(),
                      ],
                    ),
                  ),
                  _Chip(
                      label: 'Cấp ${widget.level.toUpperCase()}',
                      opacity: 0.25),
                  const SizedBox(width: 8),
                  _Chip(
                    label: timeStr,
                    opacity: 0.2,
                    icon: Icons.timer_outlined,
                  ),
                ],
              ),
            ),

            // ── Puzzle area ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    const Text(
                      'Điền các chữ số còn thiếu sao cho các phép\ntính hàng ngang và hàng dọc đều đúng nhé!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGrid(),
                    if (_checked && _correctCount < _totalBlanks) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                color: AppColors.error, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Còn ${_totalBlanks - _correctCount} ô chưa đúng — thử lại nhé!',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // ── Numpad ───────────────────────────────────────────────
            _buildNumpad(),
          ],
        ),
      ),
    );
  }

  // ── Grid ──────────────────────────────────────────────────────────────────

  Widget _buildGrid() {
    const cardPad = 14.0;
    const opW = 22.0;

    return Container(
      padding: const EdgeInsets.all(cardPad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kStart.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (_, constraints) {
          // 5 number cells + 4 operator slots = available width
          final cellW =
              ((constraints.maxWidth - 4 * opW) / 5).clamp(28.0, 52.0);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var dr = 0; dr < 9; dr++)
                if (dr % 2 == 0)
                  _NumberRow(
                    row: dr ~/ 2,
                    grid: _grid,
                    blanks: _blanks,
                    userInput: _userInput,
                    selectedCell: _selectedCell,
                    checked: _checked,
                    onTap: _selectCell,
                    cellSize: cellW,
                    opSize: opW,
                  )
                else
                  _OperatorRow(
                    vertOp: (dr == 1 || dr == 5) ? '+' : '=',
                    cellSize: cellW,
                    opSize: opW,
                  ),
            ],
          );
        },
      ),
    );
  }

  // ── Numpad ────────────────────────────────────────────────────────────────

  Widget _buildNumpad() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NumRow(keys: const ['1', '2', '3'], onTap: _onNumpad),
          const SizedBox(height: 8),
          _NumRow(keys: const ['4', '5', '6'], onTap: _onNumpad),
          const SizedBox(height: 8),
          _NumRow(keys: const ['7', '8', '9'], onTap: _onNumpad),
          const SizedBox(height: 8),
          _NumRow(keys: const ['⌫', '0', '✓'], onTap: _onNumpad),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _NumberRow extends StatelessWidget {
  final int row;
  final List<List<int>> grid;
  final List<List<bool>> blanks;
  final List<List<String>> userInput;
  final (int, int)? selectedCell;
  final bool checked;
  final void Function(int r, int c) onTap;
  final double cellSize;
  final double opSize;

  const _NumberRow({
    required this.row,
    required this.grid,
    required this.blanks,
    required this.userInput,
    required this.selectedCell,
    required this.checked,
    required this.onTap,
    required this.cellSize,
    required this.opSize,
  });

  static const _hOps = ['+', '=', '+', '='];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var dc = 0; dc < 9; dc++)
            if (dc % 2 == 0)
              _NumCell(
                value: grid[row][dc ~/ 2],
                isBlank: blanks[row][dc ~/ 2],
                userText: userInput[row][dc ~/ 2],
                isSelected: selectedCell == (row, dc ~/ 2),
                isCorrect: checked && blanks[row][dc ~/ 2]
                    ? (userInput[row][dc ~/ 2].isNotEmpty &&
                        int.tryParse(userInput[row][dc ~/ 2]) ==
                            grid[row][dc ~/ 2])
                    : null,
                onTap: () => onTap(row, dc ~/ 2),
                size: cellSize,
              )
            else
              _OpLabel(label: _hOps[(dc - 1) ~/ 2], width: opSize),
        ],
      ),
    );
  }
}

class _OperatorRow extends StatelessWidget {
  final String vertOp;
  final double cellSize;
  final double opSize;
  const _OperatorRow({
    required this.vertOp,
    required this.cellSize,
    required this.opSize,
  });

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var dc = 0; dc < 9; dc++) {
      if (dc % 2 == 0) {
        items.add(SizedBox(
          width: cellSize,
          child: Center(
            child: Text(
              vertOp,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _kStart,
              ),
            ),
          ),
        ));
      } else {
        items.add(SizedBox(width: opSize));
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: items,
    );
  }
}

class _NumCell extends StatelessWidget {
  final int value;
  final bool isBlank;
  final String userText;
  final bool isSelected;
  final bool? isCorrect;
  final VoidCallback onTap;
  final double size;

  const _NumCell({
    required this.value,
    required this.isBlank,
    required this.userText,
    required this.isSelected,
    required this.isCorrect,
    required this.onTap,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg, border, fg;

    if (!isBlank) {
      bg = _kStart.withValues(alpha: 0.08);
      border = _kStart.withValues(alpha: 0.2);
      fg = AppColors.textPrimary;
    } else if (isSelected) {
      bg = _kStart.withValues(alpha: 0.1);
      border = _kStart;
      fg = _kStart;
    } else if (isCorrect == true) {
      bg = AppColors.success.withValues(alpha: 0.1);
      border = AppColors.success;
      fg = AppColors.success;
    } else if (isCorrect == false) {
      bg = AppColors.error.withValues(alpha: 0.1);
      border = AppColors.error;
      fg = AppColors.error;
    } else {
      bg = Colors.white;
      border = AppColors.divider;
      fg = AppColors.textPrimary;
    }

    final displayText = isBlank ? userText : '$value';
    final fontSize = displayText.length > 2 ? 11.0 : 14.0;

    return GestureDetector(
      onTap: isBlank ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: isSelected ? 2 : 1.5),
        ),
        child: Center(
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}

class _OpLabel extends StatelessWidget {
  final String label;
  final double width;
  const _OpLabel({required this.label, required this.width});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: _kStart,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Numpad sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _NumRow extends StatelessWidget {
  final List<String> keys;
  final void Function(String) onTap;
  const _NumRow({required this.keys, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: keys.map((k) {
        final Color bg, fg;
        if (k == '⌫') {
          bg = const Color(0xFFFFEBEB);
          fg = AppColors.error;
        } else if (k == '✓') {
          bg = const Color(0xFFE8F5E9);
          fg = AppColors.success;
        } else {
          bg = const Color(0xFFF5F5F5);
          fg = AppColors.textPrimary;
        }

        Widget child;
        if (k == '⌫') {
          child = Icon(Icons.backspace_outlined, color: fg, size: 22);
        } else if (k == '✓') {
          child = Icon(Icons.check_rounded, color: fg, size: 26);
        } else {
          child = Text(k,
              style: TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold, color: fg));
        }

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: GestureDetector(
              onTap: () => onTap(k),
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: child),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header helpers
// ─────────────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final double opacity;
  final IconData? icon;
  const _Chip({required this.label, required this.opacity, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 13),
            const SizedBox(width: 4),
          ],
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _GridIcon extends StatelessWidget {
  const _GridIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.grid_3x3_rounded, color: Colors.white, size: 16),
    );
  }
}
