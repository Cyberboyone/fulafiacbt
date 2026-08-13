class CourseProgress {
  final String courseId;
  final int questionsAttempted;
  final int correctCount;
  final int bestScore; // Percentage
  final DateTime lastAttemptDate;

  CourseProgress({
    required this.courseId,
    this.questionsAttempted = 0,
    this.correctCount = 0,
    this.bestScore = 0,
    required this.lastAttemptDate,
  });

  CourseProgress copyWith({
    int? questionsAttempted,
    int? correctCount,
    int? bestScore,
    DateTime? lastAttemptDate,
  }) {
    return CourseProgress(
      courseId: this.courseId,
      questionsAttempted: questionsAttempted ?? this.questionsAttempted,
      correctCount: correctCount ?? this.correctCount,
      bestScore: bestScore ?? this.bestScore,
      lastAttemptDate: lastAttemptDate ?? this.lastAttemptDate,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'questionsAttempted': questionsAttempted,
      'correctCount': correctCount,
      'bestScore': bestScore,
      'lastAttemptDate': lastAttemptDate.toIso8601String(),
    };
  }

  factory CourseProgress.fromMap(Map<dynamic, dynamic> map) {
    return CourseProgress(
      courseId: map['courseId'] as String? ?? '',
      questionsAttempted: map['questionsAttempted'] as int? ?? 0,
      correctCount: map['correctCount'] as int? ?? 0,
      bestScore: map['bestScore'] as int? ?? 0,
      lastAttemptDate: _safeParseDateTime(map['lastAttemptDate']),
    );
  }

  static DateTime _safeParseDateTime(dynamic value) {
    if (value is String) {
      try { return DateTime.parse(value); } catch (_) {}
    }
    return DateTime.now();
  }
}
