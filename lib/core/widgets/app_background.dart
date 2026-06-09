import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Aurora blob background — đặt phía dưới cùng trong Stack của mỗi màn hình.
/// Các blob cố định, không cuộn theo content.
class AppAuroraBackground extends StatelessWidget {
  const AppAuroraBackground({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SizedBox.expand(
      child: Stack(
        children: [
          // Nền base
          Container(color: const Color(0xFFF0F5FA)),

          // Blob 1 — xanh primary, góc trên trái
          Positioned(
            top: -size.height * 0.1,
            left: -size.width * 0.2,
            child: _Blob(
              size: size.width * 0.75,
              color: AppColors.primary.withValues(alpha: 0.10),
            ),
          ),

          // Blob 2 — tím, góc dưới phải
          Positioned(
            bottom: -size.height * 0.08,
            right: -size.width * 0.2,
            child: _Blob(
              size: size.width * 0.80,
              color: const Color(0xFF7C3AED).withValues(alpha: 0.07),
            ),
          ),

          // Blob 3 — xanh nhạt, giữa phải
          Positioned(
            top: size.height * 0.35,
            right: -size.width * 0.1,
            child: _Blob(
              size: size.width * 0.45,
              color: AppColors.primaryLight.withValues(alpha: 0.06),
            ),
          ),

          // Blob 4 — tím nhạt, giữa trái
          Positioned(
            top: size.height * 0.55,
            left: -size.width * 0.1,
            child: _Blob(
              size: size.width * 0.40,
              color: const Color(0xFF9F67FA).withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  final double size;
  final Color color;

  const _Blob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
