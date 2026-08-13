import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:audioplayers/audioplayers.dart';
import 'services/hive_service.dart';
import 'services/ad_service.dart';
import 'services/sound_service.dart';
import 'models/question.dart';
import 'config/constants.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();
  FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  // Initialize AdMob (non-blocking so app launches fast)
  AdService.instance.init();

  // Make all sound effects mix with (never interrupt) audio already
  // playing on the device.
  await AudioPlayer.global.setAudioContext(AppSound.context);

  // Initialize Hive local database
  final hiveService = HiveService();
  await hiveService.init();

  // Pre-load bundled starter questions into Hive (only if cache is empty)
  await _seedStarterQuestions(hiveService);

  runApp(const FulafiaCbtApp());
}

/// Seeds the local Hive question cache from bundled JSON assets
/// so the app is usable immediately after install with zero internet.
Future<void> _seedStarterQuestions(HiveService hiveService) async {
  const courseIds = ['bly111', 'chem111', 'csc111', 'gst111', 'gst112', 'gst113_1', 'gst113_2', 'mth111', 'mth121', 'phy111', 'phy102', 'phy104', 'phy121', 'bio102', 'bly121', 'bly122', 'chm102', 'chm121', 'chm122'];

  for (final courseId in courseIds) {
    final cached = hiveService.getCachedQuestions(courseId);
    if (cached.isNotEmpty) continue; // already seeded or updated from GitHub

    try {
      final jsonStr = await rootBundle.loadString('assets/questions/$courseId.json');
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final questionsRaw = data['questions'] as List<dynamic>;

      final questions = questionsRaw.map((q) {
        final map = q as Map<String, dynamic>;
        return Question(
          id: map['id'] as String? ?? '',
          text: map['text'] as String? ?? '',
          options: List<String>.from(map['options'] as List? ?? []),
          correctIndex: map['correct_index'] as int? ?? 0,
          explanation: map['explanation'] as String? ?? '',
          difficulty: map['difficulty'] as int? ?? 1,
        );
      }).toList();

      await hiveService.cacheQuestions(courseId, questions);
      debugPrint('Seeded ${questions.length} questions for $courseId');
    } catch (e) {
      debugPrint('Failed to seed $courseId: $e');
    }
  }
}
