import 'package:flutter/material.dart';
import '../models/course.dart';
import '../models/progress.dart';
import '../services/hive_service.dart';

class CourseProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();

  final List<Course> _courses = [
    // FULafia 100 Level Courses
    Course(
      id: 'bly111',
      code: 'BLY 111',
      name: 'General Biology I',
      icon: '🧬',
      colorHex: '#DFF5E4', // Mint
      mode: '100_level',
    ),
    Course(
      id: 'chem111',
      code: 'CHM 111',
      name: 'Introductory Physical Chemistry',
      icon: '⚗️',
      colorHex: '#FFF3CD', // Amber
      mode: '100_level',
    ),
    Course(
      id: 'csc111',
      code: 'CSC 111',
      name: 'Introduction to Computer Science',
      icon: '💻',
      colorHex: '#DCEEFF', // Sky
      mode: '100_level',
    ),
    Course(
      id: 'gst111',
      code: 'GST 111',
      name: 'Use of English',
      icon: '📘',
      colorHex: '#FFE8D6', // Peach
      mode: '100_level',
    ),
    Course(
      id: 'gst112',
      code: 'GST 112',
      name: 'Use of Library & ICT',
      icon: '📚',
      colorHex: '#EAE2FA', // Lavender
      mode: '100_level',
    ),
    Course(
      id: 'gst113_1',
      code: 'GST 113',
      name: 'Nigeria People and Culture I',
      icon: '🌍',
      colorHex: '#DCEEFF', // Sky
      mode: '100_level',
    ),
    Course(
      id: 'mth111',
      code: 'MTH 111',
      name: 'General Mathematics I',
      icon: '📐',
      colorHex: '#FFF3CD', // Amber
      mode: '100_level',
    ),
    Course(
      id: 'phy111',
      code: 'PHY 111',
      name: 'General Physics I',
      icon: '⚡',
      colorHex: '#FFE8D6', // Peach
      mode: '100_level',
    ),
    Course(
      id: 'bio102',
      code: 'BIO 102',
      name: 'General Biology II (Ecology)',
      icon: '🌿',
      colorHex: '#DFF5E4', // Mint
      mode: '100_level',
    ),
    Course(
      id: 'bly121',
      code: 'BLY 121',
      name: 'General Biology II (Diversity)',
      icon: '🦋',
      colorHex: '#DFF5E4', // Mint
      mode: '100_level',
    ),
    Course(
      id: 'bly122',
      code: 'BLY 122',
      name: 'General Biology II (Survey & Practical)',
      icon: '🔬',
      colorHex: '#EAE2FA', // Lavender
      mode: '100_level',
    ),
    Course(
      id: 'chm102',
      code: 'CHM 102',
      name: 'General Chemistry II',
      icon: '🧪',
      colorHex: '#DCEEFF', // Sky
      mode: '100_level',
    ),
    Course(
      id: 'chm121',
      code: 'CHM 121',
      name: 'Introductory Inorganic Chemistry',
      icon: '⚗️',
      colorHex: '#FFF3CD', // Amber
      mode: '100_level',
    ),
    Course(
      id: 'chm122',
      code: 'CHM 122',
      name: 'Introductory Organic Chemistry',
      icon: '🧫',
      colorHex: '#EAE2FA', // Lavender
      mode: '100_level',
    ),
    Course(
      id: 'gst113_2',
      code: 'GST 113',
      name: 'Nigeria People and Culture II',
      icon: '🌍',
      colorHex: '#FFE8D6', // Peach
      mode: '100_level',
    ),
    Course(
      id: 'mth121',
      code: 'MTH 121',
      name: 'General Mathematics II',
      icon: '📐',
      colorHex: '#FFF3CD', // Amber
      mode: '100_level',
    ),
    Course(
      id: 'phy102',
      code: 'PHY 102',
      name: 'Electricity & Magnetism',
      icon: '🧲',
      colorHex: '#FFE8D6', // Peach
      mode: '100_level',
    ),
    Course(
      id: 'phy104',
      code: 'PHY 104',
      name: 'Vibration, Waves & Optics',
      icon: '🌊',
      colorHex: '#DCEEFF', // Sky
      mode: '100_level',
    ),
    Course(
      id: 'phy121',
      code: 'PHY 121',
      name: 'Electricity, Magnetism & Modern Physics',
      icon: '🔌',
      colorHex: '#DFF5E4', // Mint
      mode: '100_level',
    ),
  ];

  List<Course> get courses => _courses;

  final Map<String, CourseProgress> _progressMap = {};

  CourseProvider() {
    loadAllProgress();
  }

  void loadAllProgress() {
    for (var course in _courses) {
      _progressMap[course.id] = _hiveService.getProgress(course.id);
    }
    notifyListeners();
  }

  CourseProgress getProgressForCourse(String courseId) {
    return _progressMap[courseId] ??
        CourseProgress(
          courseId: courseId,
          questionsAttempted: 0,
          correctCount: 0,
          bestScore: 0,
          lastAttemptDate: DateTime.now(),
        );
  }

  double getCompletionPercentage(String courseId) {
    // For demo purposes and mock completeness, we'll calculate based on standard 100 questions pool.
    // If questions are cached, we can check how many questions are in Hive.
    final cachedQuestionsCount = _hiveService.getCachedQuestions(courseId).length;
    final total = cachedQuestionsCount > 0 ? cachedQuestionsCount : 100;
    
    final progress = getProgressForCourse(courseId);
    if (progress.questionsAttempted == 0) return 0.0;
    
    final pct = (progress.questionsAttempted / total);
    return pct > 1.0 ? 1.0 : pct;
  }

  Future<void> updateCourseProgress({
    required String courseId,
    required int additionalAttempted,
    required int additionalCorrect,
    int? newExamScore,
  }) async {
    final current = getProgressForCourse(courseId);
    
    int updatedAttempted = current.questionsAttempted + additionalAttempted;
    int updatedCorrect = current.correctCount + additionalCorrect;
    int updatedBestScore = current.bestScore;

    if (newExamScore != null && newExamScore > current.bestScore) {
      updatedBestScore = newExamScore;
    }

    final updated = CourseProgress(
      courseId: courseId,
      questionsAttempted: updatedAttempted,
      correctCount: updatedCorrect,
      bestScore: updatedBestScore,
      lastAttemptDate: DateTime.now(),
    );

    _progressMap[courseId] = updated;
    await _hiveService.saveProgress(updated);
    notifyListeners();
  }
}
