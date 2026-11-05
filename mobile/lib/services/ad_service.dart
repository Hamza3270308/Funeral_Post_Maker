import 'package:flutter/foundation.dart';
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

  // --- Default Production Ad Unit IDs for Android ---
  static const String defaultAppOpenAdId = 'ca-app-pub-1105449328380981/7071024932';
  static const String defaultInterstitialAdId = 'ca-app-pub-1105449328380981/3501164210';
  static const String defaultRewardedAdId = 'ca-app-pub-1105449328380981/7248837535';

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
  int _interstitialActionCounterThreshold = 10; // Trigger interstitial at 10 actions
  static const int _interstitialPreloadThreshold = 8; // Preload just-in-time at 8th action
  int _appOpenTimeoutSeconds = 8; // 8 seconds timeout

  String _appOpenAdUnitId = defaultAppOpenAdId;
  String _interstitialAdUnitId = defaultInterstitialAdId;
  String _rewardedAdUnitId = defaultRewardedAdId;

  // --- Ad Instances ---
  AppOpenAd? _appOpenAd;
  bool _isAppOpenLoading = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  int _currentActionCount = 0;

  RewardedAd? _rewardedAd;
  bool _isRewardedLoading = false;

  // --- Getters ---
  bool get isInitialized => _isInitialized;
  bool get isAdsEnabled => _adsEnabled;
  bool get isAppOpenAdsEnabled => _adsEnabled && _appOpenAdsEnabled;
  bool get isInterstitialAdsEnabled => _adsEnabled && _interstitialAdsEnabled;
  bool get isRewardedAdsEnabled => _adsEnabled && _rewardedAdsEnabled;
  int get appOpenTimeoutSeconds => _appOpenTimeoutSeconds;
  bool get hasShownAppOpenThisSession => _hasShownAppOpenThisSession;
  bool get isRewardedLoading => _isRewardedLoading;
  bool get isRewardedAdReady => _rewardedAd != null;

  // --- Safe Ad Unit ID Getters (Force Google Test IDs in Debug/Testing) ---
  String get appOpenAdUnitId {
    if (kDebugMode) return testAppOpenAdId;
    return _appOpenAdUnitId;
  }

  String get interstitialAdUnitId {
    if (kDebugMode) return testInterstitialAdId;
    return _interstitialAdUnitId;
  }

  String get rewardedAdUnitId {
    if (kDebugMode) return testRewardedAdId;
    return _rewardedAdUnitId;
  }

  /// Initialize Mobile Ads SDK and Firebase Remote Config
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await MobileAds.instance.initialize();
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment: TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        ),
      );
      await _initRemoteConfig();
      _isInitialized = true;
      
      // NOTE: Interstitial and Rewarded ads are NOT preloaded on startup.
      // Interstitial is preloaded just-in-time at action #8, and Rewarded is preloaded when Export is clicked.
      // This protects show rate from unused matched requests.
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
        'fpm_ads_enabled': true,
        'fpm_app_open_ads_enabled': true,
        'fpm_interstitial_ads_enabled': true,
        'fpm_rewarded_ads_enabled': true,
        'fpm_interstitial_action_counter': 10,
        'fpm_app_open_timeout_seconds': 7,
        'fpm_app_open_ad_id': defaultAppOpenAdId,
        'fpm_interstitial_ad_id': defaultInterstitialAdId,
        'fpm_rewarded_ad_id': defaultRewardedAdId,
      });

      // Try fetching and activating Remote Config
      await remoteConfig.fetchAndActivate();

      // Read values into memory
      _adsEnabled = remoteConfig.getBool('fpm_ads_enabled');
      _appOpenAdsEnabled = remoteConfig.getBool('fpm_app_open_ads_enabled');
      _interstitialAdsEnabled = remoteConfig.getBool('fpm_interstitial_ads_enabled');
      _rewardedAdsEnabled = remoteConfig.getBool('fpm_rewarded_ads_enabled');
      
      _interstitialActionCounterThreshold = remoteConfig.getInt('fpm_interstitial_action_counter');
      if (_interstitialActionCounterThreshold <= 0) _interstitialActionCounterThreshold = 10;

      _appOpenTimeoutSeconds = remoteConfig.getInt('fpm_app_open_timeout_seconds');
      if (_appOpenTimeoutSeconds < 4 || _appOpenTimeoutSeconds > 15) _appOpenTimeoutSeconds = 8;

      final rAppOpen = remoteConfig.getString('fpm_app_open_ad_id');
      if (rAppOpen.isNotEmpty) _appOpenAdUnitId = rAppOpen;

      final rInterstitial = remoteConfig.getString('fpm_interstitial_ad_id');
      if (rInterstitial.isNotEmpty) _interstitialAdUnitId = rInterstitial;

      final rRewarded = remoteConfig.getString('fpm_rewarded_ad_id');
      if (rRewarded.isNotEmpty) _rewardedAdUnitId = rRewarded;

      debugPrint('[AdService] Safety Check: kDebugMode= (Forcing Google Test IDs: )');

      debugPrint('[AdService] Remote Config loaded: ads_enabled=$_adsEnabled, app_open=$_appOpenAdsEnabled, interstitial=$_interstitialAdsEnabled, rewarded=$_rewardedAdsEnabled, actions=$_interstitialActionCounterThreshold');
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
    bool hasTimedOut = false;

    AppOpenAd.load(
      adUnitId: appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _isAppOpenLoading = false;
          if (hasTimedOut || completer.isCompleted) {
            // Late arrival after splash timeout: dispose immediately to prevent orphan match
            debugPrint('[AdService] AppOpenAd loaded after timeout - disposing to protect show rate');
            ad.dispose();
            _appOpenAd = null;
            return;
          }
          _appOpenAd = ad;
          completer.complete(true);
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

    // Timeout watchdog: bypass if internet is slow or ad network doesn't respond
    return Future.any([
      completer.future,
      Future.delayed(effectiveTimeout, () {
        if (!completer.isCompleted) {
          hasTimedOut = true;
          debugPrint('[AdService] AppOpenAd load timed out after ${effectiveTimeout.inSeconds}s');
          _isAppOpenLoading = false;
          completer.complete(false);
        }
        return false;
      }),
    ]);
  }

  /// Explicitly marks that the App Open ad has been handled for this session.
  /// Prevents any ad from showing on background resume.
  void markAppOpenSessionHandled() {
    _hasShownAppOpenThisSession = true;
  }

  /// Shows the loaded App Open Ad if available.
  /// Once shown or skipped, marks _hasShownAppOpenThisSession = true so it NEVER shows on resume.
  void showAppOpenAdIfAvailable({required VoidCallback onDismissed}) {
    _hasShownAppOpenThisSession = true;

    if (!isAppOpenAdsEnabled || _appOpenAd == null) {
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
        onDismissed();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] AppOpenAd failed to show: $error');
        ad.dispose();
        _appOpenAd = null;
        onDismissed();
      },
    );

    _appOpenAd!.show();
  }

  // ===========================================================================
  // 2. INTERSTITIAL ADS (JUST-IN-TIME: PRELOAD AT 8, SHOW AT 10)
  // ===========================================================================

  /// Preload Interstitial Ad in background
  void preloadInterstitialAd() {
    if (!isInterstitialAdsEnabled || _isInterstitialLoading || _interstitialAd != null) {
      return;
    }

    _isInterstitialLoading = true;
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
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
  /// Preloads at action #8, displays at action #10.
  void registerAction(BuildContext context) {
    if (!isInterstitialAdsEnabled) return;

    _currentActionCount++;
    debugPrint('[AdService] Action registered: $_currentActionCount/$_interstitialActionCounterThreshold');

    // Preload just-in-time on action #8 so it is ready by action #10
    if (_currentActionCount == _interstitialPreloadThreshold) {
      preloadInterstitialAd();
    }

    if (_currentActionCount >= _interstitialActionCounterThreshold) {
      _showInterstitial(context);
    }
  }

  /// Show the interstitial ad if available
  void _showInterstitial(BuildContext context) {
    if (_interstitialAd == null) {
      // If not ready yet, request preload so subsequent action can show it
      preloadInterstitialAd();
      return;
    }

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _currentActionCount = 0;
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _currentActionCount = 0;
        // Do NOT immediately preload here (prevents ghost requests when user exits)
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] InterstitialAd failed to show: $error');
        ad.dispose();
        _interstitialAd = null;
        _currentActionCount = 0;
      },
    );

    _interstitialAd!.show();
  }

  // ===========================================================================
  // 3. REWARDED ADS (JUST-IN-TIME: PRELOAD ON EXPORT CLICK)
  // ===========================================================================

  /// Preload Rewarded Ad in background
  void preloadRewardedAd() {
    if (!isRewardedAdsEnabled || _isRewardedLoading || _rewardedAd != null) {
      return;
    }

    _isRewardedLoading = true;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
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
  /// If the ad is loading, waits briefly so the user actually sees it.
  /// If ad is not ready or network fails, gracefully invokes onUserEarnedReward as a fail-safe.
  Future<void> showRewardedAd(
    BuildContext context, {
    required VoidCallback onUserEarnedReward,
    VoidCallback? onDismissed,
  }) async {
    if (!isRewardedAdsEnabled) {
      // Ads disabled: grant immediately
      onUserEarnedReward();
      onDismissed?.call();
      return;
    }

    // If ad is currently loading, wait up to 3 seconds for it to finish
    if (_rewardedAd == null && _isRewardedLoading) {
      int waitedMs = 0;
      while (_isRewardedLoading && waitedMs < 3000) {
        await Future.delayed(const Duration(milliseconds: 150));
        waitedMs += 150;
      }
    }

    if (_rewardedAd == null) {
      // Fail-safe: If ad isn't loaded, grant reward anyway so user is never blocked
      debugPrint('[AdService] RewardedAd not ready, granting fail-safe download reward');
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
        // Do NOT reload here (stops ghost ads when user finishes exporting)
        if (userEarnedReward) {
          onUserEarnedReward();
        }
        onDismissed?.call();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdService] RewardedAd failed to show: $error');
        ad.dispose();
        _rewardedAd = null;
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

  @override
  void initState() {
    super.initState();
    AdService.instance.preloadRewardedAd();
  }

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
