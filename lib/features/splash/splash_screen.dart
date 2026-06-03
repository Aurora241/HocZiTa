import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../home/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  late AnimationController _progressCtrl;

  final List<_OnboardingData> _pages = [
    _OnboardingData(
      lottiePath: 'assets/lottie/onboarding_1.json',
      fallbackIcon: Icons.school_rounded,
      title: 'Học thông minh hơn\nmỗi ngày',
      description: 'Kết hợp kiến thức và trò chơi — cách học hiệu quả nhất cho thế hệ mới',
      gradientColors: [Color(0xFF0077BB), Color(0xFF00AADD)],
    ),
    _OnboardingData(
      lottiePath: 'assets/lottie/onboarding_2.json',
      fallbackIcon: Icons.menu_book_rounded,
      title: 'Lộ trình rõ ràng,\ntiến bộ thật sự',
      description: 'Nội dung được thiết kế theo 3 cấp độ A · B · C, phù hợp mọi trình độ',
      gradientColors: [Color(0xFF004F99), Color(0xFF0077BB)],
    ),
    _OnboardingData(
      lottiePath: 'assets/lottie/onboarding_3.json',
      fallbackIcon: Icons.emoji_events_rounded,
      title: 'Thách thức bản thân\nmỗi ngày',
      description: 'Chinh phục 6 mini-game, tích sao và leo lên đỉnh bảng xếp hạng',
      gradientColors: [Color(0xFF0088CC), Color(0xFF00BBDD)],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _progressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) _goToNext();
      });
    _progressCtrl.forward();
  }

  void _startProgress() {
    _progressCtrl.reset();
    _progressCtrl.forward();
  }

  void _goToNext() {
    _progressCtrl.reset();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      // _startProgress() sẽ được gọi lại từ onPageChanged
    } else {
      _goToHome();
    }
  }

  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  void dispose() {
    _progressCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      body: Stack(
        children: [
          // ── PageView ────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) {
              setState(() => _currentPage = i);
              _startProgress();
            },
            itemBuilder: (context, index) => _OnboardingPage(
              data: _pages[index],
            ),
          ),

          // ── Nút Bỏ qua (top right) ──────────────────────────────
          if (_currentPage < _pages.length - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 20,
              child: TextButton(
                onPressed: _goToHome,
                child: const Text(
                  'Bỏ qua',
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
              ),
            ),

          // ── Dots + Nút nằm trong vùng trắng ─────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.of(context).padding.bottom + 36,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Dot indicators + progress bar
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: List.generate(
                          _pages.length,
                          (i) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            width: _currentPage == i ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentPage == i
                                  ? Colors.white
                                  : Colors.white38,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Countdown progress bar
                      SizedBox(
                        width: 80,
                        child: AnimatedBuilder(
                          animation: _progressCtrl,
                          builder: (ctx, _) => ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            child: LinearProgressIndicator(
                              value: _progressCtrl.value,
                              minHeight: 3,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Nút Tiếp theo / Bắt đầu
                  GestureDetector(
                    onTap: _goToNext,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _currentPage == _pages.length - 1
                                ? 'Bắt đầu'
                                : 'Tiếp theo',
                            style: TextStyle(
                              color: page.gradientColors[0],
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _currentPage == _pages.length - 1
                                ? Icons.check_circle_rounded
                                : Icons.arrow_forward_rounded,
                            color: page.gradientColors[0],
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mỗi trang onboarding
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gradient toàn màn hình
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: data.gradientColors,
            ),
          ),
        ),

        // Circles trang trí
        const _DecorativeCircles(),

        // Nội dung
        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 60),

              // Lottie animation
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Lottie.asset(
                    data.lottiePath,
                    fit: BoxFit.contain,
                    repeat: true,
                    errorBuilder: (context, error, stack) => Icon(
                      data.fallbackIcon,
                      size: 160,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ),

              // Text
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        data.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        data.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circles trang trí bán trong suốt
// ─────────────────────────────────────────────────────────────────────────────

class _DecorativeCircles extends StatelessWidget {
  const _DecorativeCircles();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Góc trên trái — lớn
        Positioned(
          top: -60,
          left: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),
        ),
        // Góc trên phải — nhỏ
        Positioned(
          top: 40,
          right: -30,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
        // Giữa trái — vừa
        Positioned(
          top: 140,
          left: 20,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
        ),
        // Dưới phải — lớn mờ
        Positioned(
          bottom: -20,
          right: -40,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data model
// ─────────────────────────────────────────────────────────────────────────────

class _OnboardingData {
  final String lottiePath;
  final IconData fallbackIcon;
  final String title;
  final String description;
  final List<Color> gradientColors;

  const _OnboardingData({
    required this.lottiePath,
    required this.fallbackIcon,
    required this.title,
    required this.description,
    required this.gradientColors,
  });
}
