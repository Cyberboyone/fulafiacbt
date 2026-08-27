import 'package:flutter/material.dart';
import 'theme.dart';

// â”€â”€ Design Tokens â”€â”€
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double sm = 10.0;
  static const double md = 14.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double full = 999.0;
}

class AppDuration {
  static const Duration micro = Duration(milliseconds: 80);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
}

class AppConstants {
  // GitHub Backend Configuration
  static const String githubUsername = 'msitarzewski';
  static const String githubRepoName = 'agency-agents';
  static const String githubBranch = 'main';

  static const String githubRawBaseUrl =
      'https://raw.githubusercontent.com/$githubUsername/$githubRepoName/$githubBranch';
  static const String jsDelivrBaseUrl =
      'https://cdn.jsdelivr.net/gh/$githubUsername/$githubRepoName@$githubBranch';

  static const String manifestPath = '/config/manifest.json';
  static const String appConfigPath = '/config/app_config.json';
  static const String questionsDir = '/questions';
  static const String materialsDir = '/materials';

  // Local Storage (Hive Box Names)
  static const String profileBox = 'profile_box';
  static const String progressBox = 'progress_box';
  static const String settingsBox = 'settings_box';
  static const String questionsBox = 'questions_box';
  static const String downloadsBox = 'downloads_box';
  static const String claimedCodesBox = 'claimed_codes_box';

  // Hive Keys
  static const String profileKey = 'user_profile';
  static const String settingsKey = 'user_settings';

  // Gameplay Settings
  static const int dailyGoalQuestions = 10;
  static const int coinsPerCorrectAnswer = 1;
  static const int coinsForHint = 5;
  static const int coinsForStreakFreeze = 15;
  static const int referralBonusCoins = 20;

  // Combo System
  static const double combo1xThreshold = 3;
  static const double combo1_5xThreshold = 5;
  static const double combo2xThreshold = 10;
  static const double combo3xMultiplier = 3.0;

  // Streak Multiplier Thresholds (days)
  static const double streak1_2xThreshold = 3;
  static const double streak1_5xThreshold = 7;
  static const double streak2xThreshold = 14;
  static const double streak3xThreshold = 30;

  // Level System: XP thresholds
  static const List<Map<String, dynamic>> levels = [
    {'xp': 0, 'title': 'Freshman', 'icon': 'ðŸŒ±'},
    {'xp': 100, 'title': 'Sophomore', 'icon': 'ðŸ“–'},
    {'xp': 500, 'title': 'Junior', 'icon': 'ðŸŽ“'},
    {'xp': 1000, 'title': 'Senior', 'icon': 'ðŸ“š'},
    {'xp': 2500, 'title': 'Graduate', 'icon': 'ðŸ…'},
    {'xp': 5000, 'title': 'Master', 'icon': 'ðŸ‘¨â€ðŸŽ“'},
    {'xp': 10000, 'title': 'Scholar', 'icon': 'ðŸ†'},
    {'xp': 25000, 'title': 'Legend', 'icon': 'ðŸ‘‘'},
  ];

  // Badge Catalog
  static const List<Map<String, String>> badgeCatalog = [
    {'id': 'first_steps', 'name': 'First Steps', 'description': 'Complete your first practice session', 'icon': 'ðŸŒ±'},
    {'id': 'perfect_score', 'name': 'Perfect Score', 'description': 'Score 100% on any exam', 'icon': 'ðŸ’¯'},
    {'id': 'speed_demon', 'name': 'Speed Demon', 'description': 'Complete a practice session in under 2 minutes', 'icon': 'âš¡'},
    {'id': 'streak_starter', 'name': 'Streak Starter', 'description': 'Maintain a 3-day streak', 'icon': 'ðŸ”¥'},
    {'id': 'streak_master', 'name': 'Streak Master', 'description': 'Maintain a 7-day streak', 'icon': 'ðŸ’ª'},
    {'id': 'streak_legend', 'name': 'Streak Legend', 'description': 'Maintain a 30-day streak', 'icon': 'ðŸ…'},
    {'id': 'centurion', 'name': 'Centurion', 'description': 'Answer 100 questions correctly total', 'icon': 'ðŸŽ¯'},
    {'id': 'scholar_badge', 'name': 'Scholar', 'description': 'Reach 5,000 XP', 'icon': 'ðŸŽ“'},
    {'id': 'legend_badge', 'name': 'Legendary', 'description': 'Reach 25,000 XP', 'icon': 'ðŸ‘‘'},
    {'id': 'quiz_addict', 'name': 'Quiz Addict', 'description': 'Attempt 500 questions total', 'icon': 'ðŸ§ '},
    {'id': 'all_rounder', 'name': 'All-Rounder', 'description': 'Practice every course at least once', 'icon': 'ðŸŒŸ'},
    {'id': 'coin_collector', 'name': 'Coin Collector', 'description': 'Earn 500 coins total', 'icon': 'ðŸª™'},
    {'id': 'combo_king', 'name': 'Combo King', 'description': 'Get 10 correct answers in a row', 'icon': 'ðŸ‘‘'},
    {'id': 'daily_devotee', 'name': 'Daily Devotee', 'description': 'Complete daily goal 7 days in a row', 'icon': 'ðŸ“…'},
    {'id': 'exam_pro', 'name': 'Exam Pro', 'description': 'Pass 5 different exams', 'icon': 'ðŸ“'},
    {'id': 'full_house', 'name': 'Full House', 'description': 'Get 100% on every course', 'icon': 'ðŸ '},
  ];

  // Exam Rules
  static const int passingScorePercentage = 45;
  static const int examDefaultMinutes = 30;
  static const int practiceMaxQuestions = 50;
  static const int examMaxQuestions = 50;

  // App Metadata
  static const String appVersion = '1.0.4';
  static const String appName = 'Fulafia CBT';
  static const String poweredBy = 'Siyayya.com';
  static const String contactEmail = 'info@fulafia.edu.ng';
  static const String webUrl = 'https://siyayya.com';

  // --- AdMob ---
  static const String admobAppId = 'ca-app-pub-9529770421530115~3653505201';
  static const String admobBannerUnitId = 'ca-app-pub-9529770421530115/3994034528';
  static const String admobInterstitialUnitId = 'ca-app-pub-9529770421530115/7414404781';
  static const String admobRewardedUnitId = 'ca-app-pub-9529770421530115/2784894636';

  // Static helpers
  static int getLevelForXp(int xp) {
    int level = 0;
    for (int i = levels.length - 1; i >= 0; i--) {
      if (xp >= (levels[i]['xp'] as int)) {
        level = i;
        break;
      }
    }
    return level;
  }

  static Map<String, dynamic> getLevelInfo(int xp) {
    final idx = getLevelForXp(xp);
    return levels[idx];
  }

  static int getNextLevelXp(int xp) {
    final currentIdx = getLevelForXp(xp);
    if (currentIdx >= levels.length - 1) return xp;
    return levels[currentIdx + 1]['xp'] as int;
  }

  static double getComboMultiplier(int combo) {
    if (combo >= combo2xThreshold) return combo3xMultiplier;
    if (combo >= combo1_5xThreshold) return 2.0;
    if (combo >= combo1xThreshold) return 1.5;
    return 1.0;
  }

  static double getStreakMultiplier(int streak) {
    if (streak >= streak3xThreshold) return 3.0;
    if (streak >= streak2xThreshold) return 2.0;
    if (streak >= streak1_5xThreshold) return 1.5;
    if (streak >= streak1_2xThreshold) return 1.2;
    return 1.0;
  }
}
