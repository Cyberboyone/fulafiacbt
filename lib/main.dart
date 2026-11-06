import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:audioplayers/audioplayers.dart';

import 'services/hive_service.dart';
import 'services/ad_service.dart';
import 'services/sound_service.dart';
import 'services/course_catalog_service.dart';
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

  // Load the bundled course catalog and seed question banks into Hive so the
  // app is usable immediately after install with zero internet. New/updated
  // courses are fetched in the background by CourseProvider after launch.
  await CourseCatalogService.instance.initialize();

  runApp(const FulafiaCbtApp());
}
