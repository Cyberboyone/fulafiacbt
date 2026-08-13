import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../models/profile.dart';
import '../services/hive_service.dart';

class ProfileProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();

  Profile? _profile;
  Profile? get profile => _profile;

  bool get hasProfile => _profile != null;

  List<String> _recentlyUnlockedBadges = [];
  List<String> get recentlyUnlockedBadges => _recentlyUnlockedBadges;
  void clearRecentBadges() => _recentlyUnlockedBadges = [];

  int _previousLevel = -1;
  int get previousLevel => _previousLevel;
  void clearLevelUp() => _previousLevel = -1;

  Future<void> loadProfile() async {
    _profile = _hiveService.getProfile();
    _resetDailyGoalIfNeeded();
    notifyListeners();
  }

  Future<void> createProfile(String nickname) async {
    _profile = await _hiveService.createInitialProfile(nickname);
    notifyListeners();
  }

  void _resetDailyGoalIfNeeded() {
    if (_profile == null) return;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    if (_profile!.lastGoalResetDate != today) {
      _profile = _profile!.copyWith(
        questionsToday: 0,
        lastGoalResetDate: today,
      );
      _hiveService.saveProfile(_profile!);
    }
  }

  Future<void> updateXP(int amount) async {
    if (_profile == null) return;
    _previousLevel = AppConstants.getLevelForXp(_profile!.xp);
    _profile = _profile!.copyWith(xp: _profile!.xp + amount);
    await _hiveService.saveProfile(_profile!);
    notifyListeners();
  }

  int get currentLevel => AppConstants.getLevelForXp(_profile?.xp ?? 0);
  Map<String, dynamic> get levelInfo => AppConstants.getLevelInfo(_profile?.xp ?? 0);
  int get nextLevelXp => AppConstants.getNextLevelXp(_profile?.xp ?? 0);
  double get levelProgress {
    if (_profile == null) return 0;
    final currentIdx = AppConstants.getLevelForXp(_profile!.xp);
    if (currentIdx >= AppConstants.levels.length - 1) return 1.0;
    final currentThreshold = AppConstants.levels[currentIdx]['xp'] as int;
    final nextThreshold = AppConstants.levels[currentIdx + 1]['xp'] as int;
    if (nextThreshold == currentThreshold) return 1.0;
    return ((_profile!.xp - currentThreshold) / (nextThreshold - currentThreshold)).clamp(0.0, 1.0);
  }

  Future<void> addCoins(int amount) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(
      coins: _profile!.coins + amount,
      totalCoinsEarned: _profile!.totalCoinsEarned + amount,
    );
    await _hiveService.saveProfile(_profile!);
    notifyListeners();
  }

  Future<bool> spendCoins(int amount) async {
    if (_profile == null || _profile!.coins < amount) return false;
    _profile = _profile!.copyWith(coins: _profile!.coins - amount);
    await _hiveService.saveProfile(_profile!);
    notifyListeners();
    return true;
  }

  Future<bool> buyStreakFreeze() async {
    return spendCoins(AppConstants.coinsForStreakFreeze);
  }

  void recordDailyQuestions(int count) {
    if (_profile == null) return;
    _resetDailyGoalIfNeeded();
    final wasBelowGoal = _profile!.questionsToday < AppConstants.dailyGoalQuestions;
    final newTotal = _profile!.questionsToday + count;
    final reachedGoal = wasBelowGoal && newTotal >= AppConstants.dailyGoalQuestions;
    _profile = _profile!.copyWith(
      questionsToday: newTotal,
      daysGoalCompleted: reachedGoal ? _profile!.daysGoalCompleted + 1 : _profile!.daysGoalCompleted,
    );
    _hiveService.saveProfile(_profile!);
  }

  Future<void> updateStreak() async {
    if (_profile == null) return;

    final now = DateTime.now();
    final lastActive = _profile!.lastActiveDate;

    final lastActiveDay = DateTime(lastActive.year, lastActive.month, lastActive.day);
    final today = DateTime(now.year, now.month, now.day);
    final difference = today.difference(lastActiveDay).inDays;

    int newStreak = _profile!.streakCount;

    if (difference == 1) {
      newStreak += 1;
    } else if (difference > 1) {
      if (_profile!.streakFreezeActive && difference == 2) {
        _profile = _profile!.copyWith(
          streakFreezeActive: false,
          lastActiveDate: now,
        );
        await _hiveService.saveProfile(_profile!);
        notifyListeners();
        return;
      }
      newStreak = 1;
    } else if (difference == 0 && newStreak == 0) {
      newStreak = 1;
    }

    _profile = _profile!.copyWith(
      streakCount: newStreak,
      lastActiveDate: now,
    );

    await _hiveService.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> setNickname(String newName) async {
    if (_profile == null) return;
    _profile = _profile!.copyWith(nickname: newName);
    await _hiveService.saveProfile(_profile!);
    notifyListeners();
  }

  Future<void> resetProfile() async {
    await _hiveService.clearAllData();
    _profile = null;
    notifyListeners();
  }

  void recordCombo(int combo) {
    if (_profile == null) return;
    if (combo > _profile!.bestCombo) {
      _profile = _profile!.copyWith(bestCombo: combo);
      _hiveService.saveProfile(_profile!);
      notifyListeners();
    }
  }

  void recordSessionStats({required int correct, required int attempted, required int coins}) {
    if (_profile == null) return;
    _resetDailyGoalIfNeeded();
    final wasBelowGoal = _profile!.questionsToday < AppConstants.dailyGoalQuestions;
    final newTotal = _profile!.questionsToday + attempted;
    final reachedGoal = wasBelowGoal && newTotal >= AppConstants.dailyGoalQuestions;
    _profile = _profile!.copyWith(
      totalCorrectEver: _profile!.totalCorrectEver + correct,
      totalAttemptedEver: _profile!.totalAttemptedEver + attempted,
      questionsToday: newTotal,
      lastGoalResetDate: DateTime.now().toIso8601String().substring(0, 10),
      daysGoalCompleted: reachedGoal ? _profile!.daysGoalCompleted + 1 : _profile!.daysGoalCompleted,
    );
    _hiveService.saveProfile(_profile!);
    notifyListeners();
  }

  List<String> checkBadges({List<String> coursesPracticed = const [], int passedExamCount = 0, bool currentExamPerfect = false, bool allCoursesPerfect = false}) {
    if (_profile == null) return [];
    final newlyUnlocked = <String>[];
    final currentBadges = Set<String>.from(_profile!.unlockedBadgeIds);

    void tryUnlock(String id) {
      if (!currentBadges.contains(id)) {
        newlyUnlocked.add(id);
        currentBadges.add(id);
      }
    }

    if (_profile!.totalAttemptedEver >= 1) tryUnlock('first_steps');
    if (_profile!.totalCorrectEver >= 100) tryUnlock('centurion');
    if (_profile!.totalAttemptedEver >= 500) tryUnlock('quiz_addict');
    if (_profile!.xp >= 5000) tryUnlock('scholar_badge');
    if (_profile!.xp >= 25000) tryUnlock('legend_badge');
    if (_profile!.totalCoinsEarned >= 500) tryUnlock('coin_collector');
    if (_profile!.bestCombo >= 10) tryUnlock('combo_king');
    if (_profile!.streakCount >= 3) tryUnlock('streak_starter');
    if (_profile!.streakCount >= 7) tryUnlock('streak_master');
    if (_profile!.streakCount >= 30) tryUnlock('streak_legend');
    if (_profile!.daysGoalCompleted >= 7) tryUnlock('daily_devotee');
    if (coursesPracticed.length >= 6) tryUnlock('all_rounder');
    if (currentExamPerfect) tryUnlock('perfect_score');
    if (passedExamCount >= 5) tryUnlock('exam_pro');
    if (allCoursesPerfect) tryUnlock('full_house');

    if (newlyUnlocked.isNotEmpty) {
      _profile = _profile!.copyWith(unlockedBadgeIds: currentBadges.toList());
      _recentlyUnlockedBadges = newlyUnlocked;
      _hiveService.saveProfile(_profile!);
      notifyListeners();
    }

    return newlyUnlocked;
  }

  void activateStreakFreeze() {
    if (_profile == null) return;
    _profile = _profile!.copyWith(streakFreezeActive: true);
    _hiveService.saveProfile(_profile!);
    notifyListeners();
  }
}
