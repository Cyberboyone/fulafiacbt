import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../config/constants.dart';

/// Centralized AdMob management for the whole app.
///
/// Loading rules (request economy):
///  - if an ad is already loaded       -> do NOT request another
///  - if a request is already in flight -> do NOT start another
///  - when an ad is consumed / shown   -> dispose it and preload the next one once
///  - if a load fails                  -> no immediate retry; the next natural
///                                        opportunity (network change, next
///                                        user-initiated action, next exam
///                                        completion) retries
///
/// Interstitials are only shown at natural transition points (e.g. after an
/// exam is submitted) and are rate-limited by [interstitialCooldown], which
/// is based on actual impressions (onAdShowedFullScreenContent), not on
/// ad requests.
///
/// Rewarded ads are only shown when the user explicitly opts in (see
/// PracticeScreen "Watch an Ad?" dialog). The reward is only reported after
/// `onUserEarnedReward` confirms the user earned it.
class AdService {
  AdService._();
  static final AdService instance = AdService._();

  /// Minimum time between interstitial impressions.
  static const Duration interstitialCooldown = Duration(minutes: 3);

  bool _initialized = false;
  bool _initFailed = false;
  StreamSubscription? _connectivitySubscription;

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;

  /// Last actual interstitial impression (show), not last request.
  DateTime? _lastInterstitialShown;

  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;

  /// Single pending user-initiated rewarded request. When the user opts in
  /// while a load is already in flight, the request is stored here and
  /// fulfilled (or failed) exactly once when that load resolves.
  _PendingRewarded? _pendingRewarded;

  /// Whether enough time has passed since the last interstitial impression
  /// that another one may be shown.
  bool canShowInterstitial() {
    final last = _lastInterstitialShown;
    if (last == null) return true;
    return DateTime.now().difference(last) >= interstitialCooldown;
  }

  /// Initializes the Mobile Ads SDK exactly once (duplicate calls are no-ops),
  /// then preloads one interstitial and one rewarded ad.
  ///
  /// This is called from `main()` and is the ONLY ad-related work done at
  /// app startup — no ad is shown on launch or on resume.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    debugPrint('[AdService] Initializing Google Mobile Ads');
    try {
      await MobileAds.instance.initialize();
      debugPrint('[AdService] Google Mobile Ads initialized');
    } catch (e) {
      // e.g. MissingApplicationIdException / MobileAdsSetupException.
      // The app must keep working normally without ads.
      _initFailed = true;
      debugPrint('[AdService] AdMob init failed: $e - ads disabled');
      return;
    }
    _listenConnectivity();
    preloadInterstitial();
    preloadRewarded();
  }

  void _listenConnectivity() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) {
      // connectivity_plus 5.x reports one result per active interface;
      // any active data connection (WiFi, mobile, ethernet, VPN) counts.
      final hasData = results.any((result) => result != ConnectivityResult.none);
      if (!hasData || _initFailed) return;
      debugPrint('[AdService] Network available ($results) - preloading missing ads');
      // Guarded no-ops for ads that are already loaded or loading.
      preloadInterstitial();
      preloadRewarded();
    });
  }

  // ────────────────────────────── Interstitial ──────────────────────────────

  /// Preloads the next interstitial once. No-op if one is already loaded
  /// or a load is in flight.
  void preloadInterstitial() => loadInterstitial();

  void loadInterstitial({
    void Function(InterstitialAd)? onLoaded,
    VoidCallback? onFailed,
  }) {
    if (_initFailed || _interstitialAd != null || _isLoadingInterstitial) return;
    _isLoadingInterstitial = true;
    debugPrint('[AdService] Loading interstitial');
    InterstitialAd.load(
      adUnitId: AppConstants.admobInterstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Interstitial loaded');
          _isLoadingInterstitial = false;
          _interstitialAd = ad;
          onLoaded?.call(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Interstitial load failed: ${error.message}');
          _isLoadingInterstitial = false;
          _interstitialAd = null;
          // No aggressive retry loop — the next natural opportunity
          // (network change / next transition point) will retry.
          onFailed?.call();
        },
      ),
    );
  }

  /// Shows the preloaded interstitial at a natural transition point.
  ///
  /// Skips silently (and keeps the cached ad for the next natural moment)
  /// if the ad is not loaded or the cooldown has not expired. `onComplete`
  /// is called exactly once in every case, so callers never block.
  void showInterstitial({VoidCallback? onComplete}) {
    bool callbackFired = false;
    void fireComplete() {
      if (!callbackFired) {
        callbackFired = true;
        onComplete?.call();
      }
    }

    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint('[AdService] Interstitial not ready - skipping, preloading for next time');
      // One bounded request so the next transition point has an ad ready.
      preloadInterstitial();
      Future.microtask(fireComplete);
      return;
    }

    if (!canShowInterstitial()) {
      debugPrint('[AdService] Interstitial skipped - cooldown still active');
      // Keep the cached ad; it can be shown at the next natural moment.
      Future.microtask(fireComplete);
      return;
    }

    debugPrint('[AdService] Showing interstitial');
    _interstitialAd = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (a) {
        // Impression-based cooldown (not request-based).
        _lastInterstitialShown = DateTime.now();
      },
      onAdDismissedFullScreenContent: (a) {
        debugPrint('[AdService] Interstitial dismissed');
        a.dispose();
        // Preload the next one once.
        preloadInterstitial();
        fireComplete();
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        debugPrint('[AdService] Interstitial show failed: ${error.message}');
        a.dispose();
        // The cached ad was stale/expired - load a fresh one for next time.
        preloadInterstitial();
        fireComplete();
      },
    );
    ad.show();
  }

  // ─────────────────────────────── Rewarded ───────────────────────────────

  /// Preloads the next rewarded ad once. No-op if one is already loaded or a
  /// load is in flight.
  void preloadRewarded() => loadRewarded();

  void loadRewarded({
    void Function(RewardedAd)? onLoaded,
    VoidCallback? onFailed,
  }) {
    if (_initFailed || _rewardedAd != null || _isLoadingRewarded) return;
    _isLoadingRewarded = true;
    debugPrint('[AdService] Loading rewarded');
    RewardedAd.load(
      adUnitId: AppConstants.admobRewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          debugPrint('[AdService] Rewarded loaded');
          _isLoadingRewarded = false;
          _rewardedAd = ad;
          _flushPendingRewarded();
          onLoaded?.call(ad);
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] Rewarded load failed: ${error.message}');
          _isLoadingRewarded = false;
          _rewardedAd = null;
          // No aggressive retry loop — the next user-initiated request
          // (or network change) will retry.
          _failPendingRewarded();
          onFailed?.call();
        },
      ),
    );
  }

  /// Shows a rewarded ad the user has explicitly opted into.
  ///
  /// If an ad is already loaded it is shown immediately. If not, a single
  /// bounded load is started — the user's opt-in moment is a legitimate
  /// opportunity, and it never loops. If a load is already in flight the
  /// request is queued in [_pendingRewarded] and fulfilled once.
  ///
  /// The reward is only reported through `onRewarded` after
  /// `onUserEarnedReward` confirms the user earned it. Closing the ad early
  /// (dismiss without completion) reports `onFailed` and grants nothing.
  void showRewarded({VoidCallback? onRewarded, VoidCallback? onFailed}) {
    final ad = _rewardedAd;
    if (ad != null) {
      _presentRewarded(ad, onRewarded, onFailed);
      return;
    }

    if (_isLoadingRewarded) {
      // A load is already in flight (e.g. from the connectivity listener).
      // Wait for it — latest request wins the single pending slot.
      _pendingRewarded = _PendingRewarded(onRewarded, onFailed);
      return;
    }

    debugPrint('[AdService] Rewarded not ready - single load on user request');
    loadRewarded(
      onLoaded: (loaded) => _presentRewarded(loaded, onRewarded, onFailed),
      onFailed: () {
        _pendingRewarded = null;
        onFailed?.call();
      },
    );
  }

  void _flushPendingRewarded() {
    final pending = _pendingRewarded;
    _pendingRewarded = null;
    if (pending == null) return;
    final ad = _rewardedAd;
    if (ad == null) {
      pending.fail();
      return;
    }
    _presentRewarded(ad, pending.reward, pending.fail);
  }

  void _failPendingRewarded() {
    final pending = _pendingRewarded;
    _pendingRewarded = null;
    pending?.fail();
  }

  void _presentRewarded(
    RewardedAd ad,
    VoidCallback? onRewarded,
    VoidCallback? onFailed,
  ) {
    debugPrint('[AdService] Showing rewarded');
    _rewardedAd = null; // consumed

    // Exactly one of onRewarded/onFailed must reach the caller. The SDK
    // fires onUserEarnedReward (on completion) and THEN
    // onAdDismissedFullScreenContent, so the first outcome wins.
    bool settled = false;
    void finish({required bool rewarded}) {
      if (settled) return;
      settled = true;
      if (rewarded) {
        debugPrint('[AdService] Rewarded completed - granting reward');
        onRewarded?.call();
      } else {
        // Early close / failed show -> no reward granted.
        onFailed?.call();
      }
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (a) {
        debugPrint('[AdService] Rewarded dismissed');
        a.dispose();
        // Preload the next rewarded ad once.
        preloadRewarded();
        finish(rewarded: false);
      },
      onAdFailedToShowFullScreenContent: (a, error) {
        debugPrint('[AdService] Rewarded show failed: ${error.message}');
        a.dispose();
        // Preload a fresh one once.
        preloadRewarded();
        finish(rewarded: false);
      },
    );
    ad.show(
      onUserEarnedReward: (a, reward) {
        finish(rewarded: true);
      },
    );
  }

  /// Disposes any cached ads. Safe to call more than once.
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
    _interstitialAd = null;
    _rewardedAd = null;
  }
}

/// Holds the callbacks of a single user-initiated rewarded request that must
/// wait for an in-flight ad load.
class _PendingRewarded {
  _PendingRewarded(this.reward, this.fail);

  final VoidCallback? reward;
  final VoidCallback? fail;
}
