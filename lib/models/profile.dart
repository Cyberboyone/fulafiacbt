class Profile {
  final String deviceId;
  final String nickname;
  final int xp;
  final int streakCount;
  final int coins;
  final DateTime lastActiveDate;
  final String referralCode;
  final int questionsToday;
  final String lastGoalResetDate;
  final int bestCombo;
  final int totalCorrectEver;
  final int totalAttemptedEver;
  final int totalCoinsEarned;
  final int daysGoalCompleted;
  final List<String> unlockedBadgeIds;
  final bool streakFreezeActive;

  Profile({
    required this.deviceId,
    required this.nickname,
    this.xp = 0,
    this.streakCount = 0,
    this.coins = 0,
    required this.lastActiveDate,
    required this.referralCode,
    this.questionsToday = 0,
    this.lastGoalResetDate = '',
    this.bestCombo = 0,
    this.totalCorrectEver = 0,
    this.totalAttemptedEver = 0,
    this.totalCoinsEarned = 0,
    this.daysGoalCompleted = 0,
    this.unlockedBadgeIds = const [],
    this.streakFreezeActive = false,
  });

  Profile copyWith({
    String? nickname,
    int? xp,
    int? streakCount,
    int? coins,
    DateTime? lastActiveDate,
    String? referralCode,
    int? questionsToday,
    String? lastGoalResetDate,
    int? bestCombo,
    int? totalCorrectEver,
    int? totalAttemptedEver,
    int? totalCoinsEarned,
    int? daysGoalCompleted,
    List<String>? unlockedBadgeIds,
    bool? streakFreezeActive,
  }) {
    return Profile(
      deviceId: this.deviceId,
      nickname: nickname ?? this.nickname,
      xp: xp ?? this.xp,
      streakCount: streakCount ?? this.streakCount,
      coins: coins ?? this.coins,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      referralCode: referralCode ?? this.referralCode,
      questionsToday: questionsToday ?? this.questionsToday,
      lastGoalResetDate: lastGoalResetDate ?? this.lastGoalResetDate,
      bestCombo: bestCombo ?? this.bestCombo,
      totalCorrectEver: totalCorrectEver ?? this.totalCorrectEver,
      totalAttemptedEver: totalAttemptedEver ?? this.totalAttemptedEver,
      totalCoinsEarned: totalCoinsEarned ?? this.totalCoinsEarned,
      daysGoalCompleted: daysGoalCompleted ?? this.daysGoalCompleted,
      unlockedBadgeIds: unlockedBadgeIds ?? this.unlockedBadgeIds,
      streakFreezeActive: streakFreezeActive ?? this.streakFreezeActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'nickname': nickname,
      'xp': xp,
      'streakCount': streakCount,
      'coins': coins,
      'lastActiveDate': lastActiveDate.toIso8601String(),
      'referralCode': referralCode,
      'questionsToday': questionsToday,
      'lastGoalResetDate': lastGoalResetDate,
      'bestCombo': bestCombo,
      'totalCorrectEver': totalCorrectEver,
      'totalAttemptedEver': totalAttemptedEver,
      'totalCoinsEarned': totalCoinsEarned,
      'daysGoalCompleted': daysGoalCompleted,
      'unlockedBadgeIds': unlockedBadgeIds,
      'streakFreezeActive': streakFreezeActive,
    };
  }

  factory Profile.fromMap(Map<dynamic, dynamic> map) {
    final badgeList = map['unlockedBadgeIds'];
    List<String> badges = [];
    if (badgeList != null) {
      if (badgeList is List) {
        badges = badgeList.map((e) => e.toString()).toList();
      }
    }
    return Profile(
      deviceId: map['deviceId'] as String? ?? '',
      nickname: map['nickname'] as String? ?? 'Student',
      xp: map['xp'] as int? ?? 0,
      streakCount: map['streakCount'] as int? ?? 0,
      coins: map['coins'] as int? ?? 0,
      lastActiveDate: _safeParseDateTime(map['lastActiveDate']),
      referralCode: map['referralCode'] as String? ?? '',
      questionsToday: map['questionsToday'] as int? ?? 0,
      lastGoalResetDate: map['lastGoalResetDate'] as String? ?? '',
      bestCombo: map['bestCombo'] as int? ?? 0,
      totalCorrectEver: map['totalCorrectEver'] as int? ?? 0,
      totalAttemptedEver: map['totalAttemptedEver'] as int? ?? 0,
      totalCoinsEarned: map['totalCoinsEarned'] as int? ?? 0,
      daysGoalCompleted: map['daysGoalCompleted'] as int? ?? 0,
      unlockedBadgeIds: badges,
      streakFreezeActive: map['streakFreezeActive'] as bool? ?? false,
    );
  }

  static DateTime _safeParseDateTime(dynamic value) {
    if (value is String) {
      try { return DateTime.parse(value); } catch (_) {}
    }
    return DateTime.now();
  }
}
