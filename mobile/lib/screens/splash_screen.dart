import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../theme/theme.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_settings_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Auto-transition: wait for both the splash delay AND a fresh read of settings from disk
    Future.wait([
      Future.delayed(const Duration(seconds: 3)),
      UserSettingsService.instance.init(),
    ]).then((_) {
      if (!mounted) return;
      final isLoggedIn = FirebaseAuth.instance.currentUser != null;
      final isGuest = UserSettingsService.instance.isGuest;
      final hasSeenOnboarding = UserSettingsService.instance.hasSeenOnboarding;

      Widget nextScreen;
      if (!hasSeenOnboarding) {
        nextScreen = const OnboardingScreen();
      } else if (!isLoggedIn && !isGuest) {
        nextScreen = const LoginScreen();
      } else {
        nextScreen = const HomeScreen();
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 800),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.darkBackground,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Mocking a glowing AI graphic logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.darkSurface,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accentNeon.withOpacity(0.3),
                      blurRadius: 40,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 60,
                  color: AppTheme.accentNeon,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Funeral Post Maker',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Honoring lives with beautiful tributes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  color: Colors.white.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
