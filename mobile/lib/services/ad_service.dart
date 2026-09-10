import '../models/template.dart';
import 'user_settings_service.dart';
import '../theme/theme.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class AdService {
  static final AdService instance = AdService._internal();
  AdService._internal();

  // --- Official Google AdMob Test Ad Unit IDs for Android ---
  static const String testAppOpenAdId = 'ca-app-pub-3940256099942544/9257395921';
  static const String testInterstitialAdId = 'ca-app-pub-3940256099942544/1033173712';
  static const String testRewardedAdId = 'ca-app-pub-3940256099942544/5224354917';

  // --- State Flags ---
  bool _isInitialized = false;
  bool _hasShownAppOpenThisSession = false;

  // --- Remote Config Values & Kill Switches ---
  bool _adsEnabled = true; // Master Kill Switch
  bool _appOpenAdsEnabled = true;
  bool _interstitialAdsEnabled = true;
  bool _rewardedAdsEnabled = true;
  int _interstitialActionCounterThreshold = 12; // 10-15 actions
  int _interstitialCooldownSeconds = 75;
  int _appOpenTimeoutSeconds = 6; // 6-8 seconds

  String _appOpenAdUnitId = testAppOpenAdId;
  String _interstitialAdUnitId = testInterstitialAdId;
  String _rewardedAdUnitId = testRewardedAdId;

  // --- Ad Instances ---
  AppOpenAd? _appOpenAd;
  bool _isAppOpenLoading = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  int _currentActionCount = 0;
  DateTime? _lastInterstitialShowTime;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  // --- Getters ---
  bool get isAdsEnabled => _adsEnabled;
  bool get isAppOpenAdsEnabled => _adsEnabled && _appOpenAdsEnabled;
  bool get isInterstitialAdsEnabled => _adsEnabled && _interstitialAdsEnabled;
  bool get isRewardedAdsEnabled => _adsEnabled && _rewardedAdsEnabled;
  int get appOpenTimeoutSeconds => _appOpenTimeoutSeconds;
  bool get hasShownAppOpenThisSession => _hasShownAppOpenThisSession;

  /// Initialize Mobile Ads SDK and Firebase Remote Config
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      await _initRemoteConfig();
      _isInitialized = true;
      
      // Preload background ads if enabled
      if (isInterstitialAdsEnabled) {
        preloadInterstitialAd();
      }
      if (isRewardedAdsEnabled) {
        preloadRewardedAd();
      }
    } catch (e) {
      debugPrint('[AdService] Init error: $e');
      _isInitialized = true;
    }
  }

  /// Initialize and fetch Firebase Remote Config
  Future<void> _initRemoteConfig() async {
    try {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1), // Fast updates during testing
      ));

      // Set default fallback values
      await remoteConfig.setDefaults(<String, dynamic>{
        'ads_enabled': true,
        'app_open_ads_enabled': true,
        'interstitial_ads_enabled': true,
        'rewarded_ads_enabled': true,
        'interstitial_action_counter': 12,
        'interstitial_cooldown_seconds': 75,
        'app_open_timeout_seconds': 6,
        'admob_app_open_id': testAppOpenAdId,
        'admob_interstitial_id': testInterstitialAdId,
        'admob_rewarded_id': testRewardedAdId,
      });

      // Try fetching and activating Remote Config
      await remoteConfig.fetchAndActivate();

      // Read values into memory
      _adsEnabled = remoteConfig.getBool('ads_enabled');
      _appOpenAdsEnabled = remoteConfig.getBool('app_open_ads_enabled');
      _interstitialAdsEnabled = remoteConfig.getBool('interstitial_ads_enabled');
      _rewardedAdsEnabled = remoteConfig.getBool('rewarded_ads_enabled');
      _interstitialActionCounterThreshold = remoteConfig.getInt('interstitial_action_counter');
      if (_interstitialActionCounterThreshold <= 0) _interstitialActionCounterThreshold = 12;

      _interstitialCooldownSeconds = remoteConfig.getInt('interstitial_cooldown_seconds');
      if (_interstitialCooldownSeconds <= 0) _interstitialCooldownSeconds = 75;

      _appOpenTimeoutSeconds = remoteConfig.getInt('app_open_timeout_seconds');
      if (_appOpenTimeoutSeconds < 4 || _appOpenTimeoutSeconds > 15) _appOpenTimeoutSeconds = 6;

      final remoteAppOpen = remoteConfig.getString('admob_app_open_id');
      if (remoteAppOpen.isNotEmpty) _appOpenAdUnitId = remoteAppOpen;

      final remoteInterstitial = remoteConfig.getString('admob_interstitial_id');
      if (remoteInterstitial.isNotEmpty) _interstitialAdUnitId = remoteInterstitial;

      final remoteRewarded = remoteConfig.getString('admob_rewarded_id');
      if (remoteRewarded.isNotEmpty) _rewardedAdUnitId = remoteRewarded;

      debugPrint('[AdService] Remote Config loaded: ads_enabled=$_adsEnabled, app_open=$_appOpenAdsEnabled, interstitial=$_interstitialAdsEnabled, rewarded=$_rewardedAdsEnabled');
    } catch (e) {
      debugPrint('[AdService] Remote Config error (using defaults): $e');
    }
  }

  // ===========================================================================
  // 1. APP OPEN ADS (COLD START ONLY)
  // ===========================================================================

  /// Loads an App Open Ad with a maximum timeout.
  /// If the ad loads within the timeout, returns true; otherwise false.
  Future<bool> loadAppOpenAdWithTimeout({Duration? timeout}) async {
    if (!isAppOpenAdsEnabled || _hasShownAppOpenThisSession) {
      return false;
    }

    final effectiveTimeout = timeout ?? Duration(seconds: _appOpenTimeoutSeconds);
    final completer = Completer<bool>();
    _isAppOpenLoading = true;

    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _isAppOpenLoading = false;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] AppOpenAd failed to load: $error');
          _appOpenAd = null;
          _isAppOpenLoading = false;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    // Timeout watchdog (6-8s): bypass if internet is slow or ad network doesn't respond
    return Future.any([
      completer.future,
      Future.delayed(effectiveTimeout, () {
        if (!completer.isCompleted) {
          debugPrint('[AdService] AppOpenAd load timed out after ${effectiveTimeout.inSeconds}s');
          _isAppOpenLoading = false;
          completer.complete(false);
        }
        return false;
      }),
    ]);
  }

  /// Shows the loaded App Open Ad if available.
  /// Once shown or skipped, marks _hasShownAppOpenThisSession = true so it NEVER shows on resume.
  void showAppOpenAdIfAvailable({required VoidCallback onDismissed}) {
    if (!isAppOpenAdsEnabled || _hasShownAppOpenThisSession || _appOpenAd == null) {
      _hasShownAppOpenThisSession = true;
      onDismissed();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdService] AppOpenAd showed full screen');
      },
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdService] AppOpenAd dismissed');
        ad.dispose();
        _appOpenAd = null;
        _hasShownAppOpenThisSession = true;
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] AppOpenAd failed to show: $error');
        ad.dispose();
        _appOpenAd = null;
        _hasShownAppOpenThisSession = true;
        onDismissed();
      },
    );

    _appOpenAd!.show();
  }

  // ===========================================================================
  // 2. INTERSTITIAL ADS (10-15 ACTIONS IN EDITOR)
  // ===========================================================================

  /// Preload Interstitial Ad in background
  void preloadInterstitialAd() {
    if (!isInterstitialAdsEnabled || _isInterstitialLoading || _interstitialAd != null) {
      return;
    }

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: _interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          debugPrint('[AdService] InterstitialAd preloaded successfully');
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] InterstitialAd failed to load: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  /// Register an action in the editor (e.g. adding shape, flower, text, moving, changing style).
  /// If action count reaches the threshold (10-15) and cooldown passed, displays interstitial.
  void registerAction(BuildContext context) {
    if (!isInterstitialAdsEnabled) return;

    _currentActionCount++;
    debugPrint('[AdService] Action registered: $_currentActionCount/$_interstitialActionCounterThreshold');

    if (_currentActionCount >= _interstitialActionCounterThreshold) {
      final now = DateTime.now();
      if (_lastInterstitialShowTime == null ||
          now.difference(_lastInterstitialShowTime!).inSeconds >= _interstitialCooldownSeconds) {
        _showInterstitial(context);
      }
    }
  }

  /// Show the interstitial ad if available
  void _showInterstitial(BuildContext context) {
    if (_interstitialAd == null) {
      preloadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _lastInterstitialShowTime = DateTime.now();
        _currentActionCount = 0;
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        preloadInterstitialAd(); // Preload next one
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _interstitialAd = null;
        preloadInterstitialAd();
      },
    );

    _interstitialAd!.show();
  }

  // ===========================================================================
  // 3. REWARDED ADS (WATCH AD TO EXPORT)
  // ===========================================================================

  /// Preload Rewarded Ad in background
  void preloadRewardedAd() {
    if (!isRewardedAdsEnabled || _isRewardedLoading || _rewardedAd != null) {
      return;
    }

    _isRewardedLoading = true;
    RewardedAd.load(
      adUnitId: _rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoading = false;
          debugPrint('[AdService] RewardedAd preloaded successfully');
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] RewardedAd failed to load: $error');
          _rewardedAd = null;
          _isRewardedLoading = false;
        },
      ),
    );
  }

  /// Shows the Rewarded Ad when the user requests to export.
  /// If the ad plays and user earns reward, invokes onUserEarnedReward.
  /// If ad is not ready or network fails, gracefully invokes onUserEarnedReward as a fail-safe.
  void showRewardedAd(
    BuildContext context, {
    required VoidCallback onUserEarnedReward,
    VoidCallback? onDismissed,
  }) {
    if (!isRewardedAdsEnabled) {
      // Ads disabled: grant immediately
      onUserEarnedReward();
      onDismissed?.call();
      return;
    }

    if (_rewardedAd == null) {
      // Fail-safe: If ad isn't loaded, grant reward anyway so user is never blocked
      debugPrint('[AdService] RewardedAd not ready, granting fail-safe download reward');
      preloadRewardedAd();
      onUserEarnedReward();
      onDismissed?.call();
      return;
    }

    bool userEarnedReward = false;

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('[AdService] RewardedAd showed full screen');
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        preloadRewardedAd(); // Preload next one
        if (userEarnedReward) {
          onUserEarnedReward();
        }
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] RewardedAd failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
        preloadRewardedAd();
        // Fail-safe: grant reward anyway
        onUserEarnedReward();
        onDismissed?.call();
      },
    );

    _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        debugPrint('[AdService] User earned reward: ${reward.amount} ${reward.type}');
        userEarnedReward = true;
      },
    );
  }

  /// Displays a dialog allowing the user to watch a rewarded video ad to unlock a template with full access.
  /// If ads are disabled or template is already unlocked, immediately invokes [onUnlocked].
  /// If user cancels, dialog closes without unlocking.
  void showUnlockTemplateDialog(
    BuildContext context, {
    required Template template,
    required VoidCallback onUnlocked,
  }) {
    if (!isRewardedAdsEnabled || UserSettingsService.instance.isTemplateUnlocked(template.id)) {
      onUnlocked();
      return;
    }

    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _UnlockTemplateSheet(
        template: template,
        onUnlocked: onUnlocked,
      ),
    );
  }

}

class _UnlockTemplateSheet extends StatefulWidget {
  final Template template;
  final VoidCallback onUnlocked;

  const _UnlockTemplateSheet({
    required this.template,
    required this.onUnlocked,
  });

  @override
  State<_UnlockTemplateSheet> createState() => _UnlockTemplateSheetState();
}

class _UnlockTemplateSheetState extends State<_UnlockTemplateSheet> {
  bool _isLoading = false;

  void _watchAdToUnlock() {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    bool rewarded = false;

    AdService.instance.showRewardedAd(
      context,
      onUserEarnedReward: () async {
        rewarded = true;
        await UserSettingsService.instance.unlockTemplate(widget.template.id);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
        widget.onUnlocked();
        final messenger = ScaffoldMessenger.maybeOf(context);
        if (messenger != null) {
          messenger.showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.greenAccent),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Unlocked "' + widget.template.title + '" with full access!',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      onDismissed: () {
        if (mounted) {
          setState(() => _isLoading = false);
          if (!rewarded) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Watch the complete video ad to unlock this template.'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 25,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD54F), Color(0xFFFF9800)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF9800).withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: Colors.white,
              size: 38,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Unlock Memorial Template',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppTheme.textDark,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.template.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.blueGrey.shade700,
                fontFamily: 'Inter',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Watch a short sponsored video to unlock full editing and export access for this template.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                _buildFeature(Icons.brush_rounded, 'Full access to all editing layers & fonts'),
                const SizedBox(height: 8),
                _buildFeature(Icons.photo_rounded, 'Insert memorial portrait & custom frames'),
                const SizedBox(height: 8),
                _buildFeature(Icons.download_rounded, 'Export in high-resolution PNG & PDF'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _watchAdToUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.play_circle_filled_rounded, color: Color(0xFFFFD54F), size: 24),
                        SizedBox(width: 10),
                        Text(
                          'Watch Video to Unlock',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      Navigator.of(context).pop(false);
                    },
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade600,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Inter',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF0D9488)),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.textDark,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ],
    );
  }
}
