import 'package:flutter/material.dart';
import 'onboarding_screen.dart';
import '../theme/theme.dart';

import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_settings_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

import 'dart:io';
import '../services/ad_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _hasNoInternet = false;
  bool _isChecking = false;

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
    _checkInternetAndProceed();
  }

  Future<void> _checkInternetAndProceed() async {
    if (_isChecking) return;
    setState(() {
      _isChecking = true;
      _hasNoInternet = false;
    });

    try {
      bool hasConnection = false;
      try {
        final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 4));
        hasConnection = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      } catch (_) {
        hasConnection = false;
      }

      if (!hasConnection) {
        if (mounted) {
          setState(() {
            _hasNoInternet = true;
            _isChecking = false;
          });
        }
        return;
      }

      // Internet connection available: initialize settings and attempt App Open Ad
      await UserSettingsService.instance.init();

      // Only attempt App Open Ad on cold launch and if enabled
      if (AdService.instance.isAppOpenAdsEnabled && !AdService.instance.hasShownAppOpenThisSession) {
        // Wait for App Open Ad with 6s timeout watchdog
        final adLoaded = await AdService.instance.loadAppOpenAdWithTimeout(
          timeout: Duration(seconds: AdService.instance.appOpenTimeoutSeconds),
        );

        if (!mounted) return;

        if (adLoaded) {
          AdService.instance.showAppOpenAdIfAvailable(
            onDismissed: () {
              if (mounted) _proceedToNextScreen();
            },
          );
          return;
        }
      }

      // If ad was not shown/timed out/already shown, proceed to next screen
      if (mounted) {
        _proceedToNextScreen();
      }
    } catch (e) {
      debugPrint('[SplashScreen] Initialization error: $e');
      if (mounted) {
        _proceedToNextScreen();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _proceedToNextScreen() {
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
      body: Stack(
        children: [
          Center(
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
          if (_hasNoInternet)
            Container(
              color: Colors.black.withOpacity(0.85),
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.wifi_off_rounded,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No Internet Connection',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'An active internet connection is required to open the app and load templates. Please check your Wi-Fi or mobile data and try again.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: _isChecking ? null : _checkInternetAndProceed,
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : const Icon(Icons.refresh_rounded, color: Colors.black),
                      label: Text(
                        _isChecking ? 'Checking...' : 'Try Again',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentNeon,
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
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
