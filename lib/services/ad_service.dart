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
        Connectivity().onConnectivityChanged.listen((result) {
      // connectivity_plus 5.0.x emits a single ConnectivityResult per event.
      // Any active data connection (WiFi, mobile, ethernet, VPN) counts.
      if (result == ConnectivityResult.none || _initFailed) return;
      debugPrint('[AdService] Network available ($result) - preloading missing ads');
      // Guarded no-ops for ads that are already loaded or loading.
      preloadInterstitial();
      preloadRewarded();
    });
  }

  // ────────────────────────────── Interstitial ──────────────────────────────

  /// Preloads the next interstitial once. 
