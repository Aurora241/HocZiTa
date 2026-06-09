import 'dart:math';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Header dùng chung cho tất cả game screens
// ─────────────────────────────────────────────────────────────────────────────

class GameHeader extends StatelessWidget {
  final String title;
  final String level;
  final Color startColor;
  final Color endColor;
  final VoidCallback onBack;

  const GameHeader({
    super.key,
    required this.title,
    required this.level,
    required this.startColor,
    required this.endColor,
    required this.onBack,
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
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 20),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Cấp ${level.toUpperCase()}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Màn hình kết quả dùng chung
// ─────────────────────────────────────────────────────────────────────────────

class ResultScreen extends StatefulWidget {
  final int stars;
  final int correctCount;
  final int totalCount;
  final int totalSeconds;
  final Color color;
  final String title;
  final VoidCallback onReplay;
  final VoidCallback onExit;

  const ResultScreen({
    super.key,
    required this.stars,
    required this.correctCount,
    required this.totalCount,
    required this.totalSeconds,
    required this.color,
    required this.title,
    required this.onReplay,
    required this.onExit,
  });

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late final ConfettiController _confettiCtrl;

  @override
  void initState() {
    super.initState();
    _confettiCtrl = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    // Chỉ bắn confetti khi đạt 3 sao
    if (widget.stars == 3) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _confettiCtrl.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m}m ${s.toString().padLeft(2, '0')}s';
  }

  String get _resultMessage {
    if (widget.stars == 3) return 'Xuất sắc! 🎉';
    if (widget.stars == 2) return 'Tốt lắm! 👏';
    if (widget.stars == 1) return 'Cố gắng thêm! 💪';
    return 'Thử lại nhé! 🔄';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // ── Header trượt từ trên xuống ────────────────────────
                _buildHeader()
                    .animate()
                    .slideY(
                      begin: -1,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 32),

                // ── Stats trồi từ dưới lên ────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle_rounded,
                          iconColor: AppColors.success,
                          label: 'Câu đúng',
                          value:
                              '${widget.correctCount} / ${widget.totalCount}',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.timer_rounded,
                          iconColor: AppColors.primary,
                          label: 'Thời gian',
                          value: _formatTime(widget.totalSeconds),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .slideY(
                      begin: 0.4,
                      end: 0,
                      delay: 500.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    )
                    .fadeIn(delay: 500.ms, duration: 350.ms),

                const Spacer(),

                // ── Buttons fade in ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: widget.onReplay,
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('Chơi lại'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: widget.color,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onExit,
                          icon: const Icon(Icons.exit_to_app_rounded),
                          label: const Text('Về trang game'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: widget.color,
                            side: BorderSide(color: widget.color),
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 800.ms, duration: 400.ms)
                    .slideY(
                      begin: 0.2,
                      end: 0,
                      delay: 800.ms,
                      duration: 400.ms,
                      curve: Curves.easeOutCubic,
                    ),
              ],
            ),
          ),

          // ── Confetti — chỉ hiện khi 3 sao ────────────────────────────
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiCtrl,
              blastDirection: pi / 2,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.08,
              numberOfParticles: 20,
              maxBlastForce: 40,
              minBlastForce: 15,
              gravity: 0.3,
              colors: const [
                AppColors.star,
                AppColors.primary,
                AppColors.success,
                Color(0xFFFF6B6B),
                Color(0xFFFFE66D),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [widget.color, widget.color.withValues(alpha: 0.7)],
        ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: widget.color.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            _resultMessage,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 28),
          // Stars — pop in lần lượt
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final earned = i < widget.stars;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(
                  earned ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: i == 1 ? 64 : 52,
                  color: earned
                      ? AppColors.star
                      : Colors.white.withValues(alpha: 0.4),
                )
                    .animate()
                    .scale(
                      begin: const Offset(0, 0),
                      end: const Offset(1, 1),
                      delay: Duration(milliseconds: 300 + i * 180),
                      duration: 400.ms,
                      curve: Curves.elasticOut,
                    )
                    .fadeIn(
                      delay: Duration(milliseconds: 300 + i * 180),
                      duration: 200.ms,
                    ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
