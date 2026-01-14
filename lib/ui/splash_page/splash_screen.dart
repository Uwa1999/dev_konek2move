import 'dart:async';
import 'package:flutter/material.dart';
import 'package:konek2move/ui/landing_page/landing_screen.dart';
import 'package:konek2move/ui/login_page/login_screen.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _glowPulse;
  late Animation<Offset> _textSlide;
  late Animation<double> _textFade;

  @override
  void initState() {
    super.initState();

    // ⏱ Smooth, production timing
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    );

    _logoScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _glowPulse = Tween<double>(begin: 0.85, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.85, curve: Curves.easeInOut),
      ),
    );

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
          ),
        );

    _textFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
    );

    _controller.forward();

    // 🚀 Production splash duration
    Timer(const Duration(milliseconds: 3800), _checkAuthStatus);
  }

  // void _goNext() {
  //   if (!mounted) return;
  //   Navigator.pushReplacement(
  //     context,
  //     PageRouteBuilder(
  //       transitionDuration: const Duration(milliseconds: 600),
  //       pageBuilder: (_, __, ___) => const LandingScreen(),
  //       transitionsBuilder: (_, animation, __, child) {
  //         return FadeTransition(opacity: animation, child: child);
  //       },
  //     ),
  //   );
  // }
  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();

    final String? token = prefs.getString("jwt_token");
    final bool hasAccount = prefs.getBool("has_account") ?? false;

    if (!mounted) return;

    Widget nextScreen;

    if (token != null && token.isNotEmpty) {
      // ✅ Logged in
      nextScreen = const LandingScreen();
    } else if (hasAccount) {
      // ❌ Has account but logged out
      nextScreen = const LoginScreen();
    } else {
      // ❌ First-time user
      nextScreen = const LandingScreen();
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, _, _) => nextScreen,
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fieldFill,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFEAF6F0), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _logoFade,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 🌟 Logo + Soft Glow
                ScaleTransition(
                  scale: _logoScale,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ScaleTransition(
                        scale: _glowPulse,
                        child: Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary.withOpacity(0.08),
                          ),
                        ),
                      ),
                      Image.asset(
                        'assets/images/konek2move.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 📝 Brand Text (Production Copy)
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textFade,
                    child: Column(
                      children: [
                        // 🔤 App Name
                        const Text(
                          'Konek2Move',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.9,
                            color: AppColors.primary,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 6,
                                color: Colors.black12,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // 🏷 Production Tagline
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(22),
                          ),
                          child: const Text(
                            'Reliable delivery and logistics platform',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14.5,
                              height: 1.4,
                              letterSpacing: 0.2,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3A3A3A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
