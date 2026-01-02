import 'package:flutter/material.dart';
import 'package:konek2move/services/provider_services.dart';
import 'package:konek2move/ui/login_page/login_screen.dart';
import 'package:konek2move/ui/terms&condition_page/terms_and_condition_screen.dart';
import 'package:konek2move/utils/app_colors.dart';
import 'package:konek2move/utils/navigation.dart';
import 'package:provider/provider.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _fadeImage;
  late Animation<Offset> _slideImage;
  late Animation<double> _scaleImage;

  late Animation<double> _fadeText;
  late Animation<Offset> _slideText;

  late Animation<double> _fadeButtons;
  late Animation<Offset> _slideButtons;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    /// ===== IMAGE ANIMATION =====
    _fadeImage = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );

    _slideImage = Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
      ),
    );

    _scaleImage = Tween(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    /// ===== TEXT ANIMATION =====
    _fadeText = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
    );

    _slideText = Tween(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.75, curve: Curves.easeOut),
      ),
    );

    /// ===== BUTTONS ANIMATION =====
    _fadeButtons = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
    );

    _slideButtons = Tween(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.75, 1.0, curve: Curves.easeOut),
          ),
        );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      precacheImage(const AssetImage("assets/images/splash.png"), context);
      _controller.forward().whenComplete(() {
        if (!mounted) return;
        Provider.of<ConnectivityProvider>(context, listen: false).markUiReady();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textScale = MediaQuery.of(context).textScaleFactor;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: size.height * 0.05), // responsive top space
              /// ===== IMAGE =====
              FadeTransition(
                opacity: _fadeImage,
                child: SlideTransition(
                  position: _slideImage,
                  child: ScaleTransition(
                    scale: _scaleImage,
                    child: Image.asset(
                      "assets/images/splash.png",
                      height: size.height * 0.35,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.05),

              /// ===== TEXT =====
              FadeTransition(
                opacity: _fadeText,
                child: SlideTransition(
                  position: _slideText,
                  child: Column(
                    children: [
                      Text(
                        "Ready to Move with",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28 * textScale,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        "Konek2Move?",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28 * textScale,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: size.height * 0.02),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                        ),
                        child: Text(
                          "Seamless logistics for delivering CARD Indogrosir orders securely to your store.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16 * textScale,
                            color: Colors.grey,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              /// ===== BUTTONS =====
              FadeTransition(
                opacity: _fadeButtons,
                child: SlideTransition(
                  position: _slideButtons,
                  child: Column(
                    children: [
                      /// ▶ GET STARTED
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              SlideFadeRoute(
                                page: const TermsAndConditionScreen(),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ), // matches Reject button
                          ),
                          child: Text(
                            "Get Started",
                            style: TextStyle(
                              fontSize: 18 * textScale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: size.height * 0.01),

                      /// ▶ SIGN IN
                      SizedBox(
                        height: 52,
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              SlideFadeRoute(page: const LoginScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ), // matches Accept button
                            elevation: 0, // matches Accept button
                          ),
                          child: Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 18 * textScale,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              SizedBox(height: size.height * 0.03), // bottom space
            ],
          ),
        ),
      ),
    );
  }
}
