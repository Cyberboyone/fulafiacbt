import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../config/constants.dart';
import '../models/profile.dart';
import '../models/progress.dart';
import '../models/settings.dart';
import '../models/question.dart';
import '../models/material.dart';

class HiveService {
  static final HiveService _instance = HiveService._internal();
  factory HiveService() => _instance;
  HiveService._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    
    // Open all required Hive boxes
    await Hive.openBox(AppConstants.profileBox);
    await Hive.openBox(AppConstants.progressBox);
    await Hive.openBox(AppConstants.settingsBox);
    await Hive.openBox(AppConstants.questionsBox);
    await Hive.openBox(AppConstants.downloadsBox);
    await Hive.openBox(AppConstants.claimedCodesBox);

    _initialized = true;
    _initDefaults();
  }

  void _initDefaults() {
    final settingsBox = Hive.box(AppConstants.settingsBox);
    if (settingsBox.get(AppConstants.settingsKey) == null) {
      final defaultSettings = AppSettings();
      settingsBox.put(AppConstants.settingsKey, defaultSettings.toMap());
    }
  }

  // --- Profile Operations ---
  Profile? getProfile() {
    final box = Hive.box(AppConstants.profileBox);
    final data = box.get(AppConstants.profileKey);
    if (data == null) return null;
    return Profile.fromMap(data as Map);
  }

  Future<void> saveProfile(Profile profile) async {
    final box = Hive.box(AppConstants.profileBox);
    await box.put(AppConstants.profileKey, profile.toMap());
  }

  Future<Profile> createInitialProfile(String nickname) async {
    final deviceId = const Uuid().v4();
    final referralCode = _generateReferralCode(nickname);
    
    final newProfile = Profile(
      deviceId: deviceId,
      nickname: nickname,
      xp: 0,
      streakCount: 0,
      coins: 20, // Give some starter coins
      lastActiveDate: DateTime.now(),
      referralCode: referralCode,
    );

    await saveProfile(newProfile);
    return newProfile;
  }

  String _generateReferralCode(String nickname) {
    final cleanName = nickname.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    final prefix = cleanName.length >= 4 ? cleanName.substring(0, 4) : cleanName.padRight(4, 'X');
    final rand = const Uuid().v4().substring(0, 4).toUpperCase();
    return '$prefix-$rand';
  }

  // --- Settings Operations ---
  AppSettings getSettings() {
    final box = Hive.box(AppConstants.settingsBox);
    final data = box.get(AppConstants.settingsKey);
    if (data == null) return AppSettings();
    return AppSettings.fromMap(data as Map);
  }

  Future<void> saveSettings(AppSettings settings) async {
    final box = Hive.box(AppConstants.settingsBox);
    await box.put(AppConstants.settingsKey, settings.toMap());
  }

  // --- Course Progress Operations ---
  List<CourseProgress> getAllProgress() {
    final box = Hive.box(AppConstants.progressBox);
    return box.values.map((data) => CourseProgress.fromMap(data as Map)).toList();
  }

  CourseProgress getProgress(String courseId) {
    final box = Hive.box(AppConstants.progressBox);
    final data = box.get(courseId);
    if (data == null) {
      return CourseProgress(
        courseId: courseId,
        questionsAttempted: 0,
        correctCount: 0,
        bestScore: 0,
        lastAttemptDate: DateTime.now(),
      );
    }
    return CourseProgress.fromMap(data as Map);
  }

  Future<void> saveProgress(CourseProgress progress) async {
    final box = Hive.box(AppConstants.progressBox);
    await box.put(progress.courseId, progress.toMap());
  }

  // --- Question Caching Operations ---
  List<Question> getCachedQuestions(String courseId) {
    final box = Hive.box(AppConstants.questionsBox);
    final dataList = box.get(courseId) as List?;
    if (dataList == null) return [];
    return dataList.map((map) => Question.fromMap(map as Map)).toList();
  }

  Future<void> cacheQuestions(String courseId, List<Question> questions) async {
    final box = Hive.box(AppConstants.questionsBox);
    final dataList = questions.map((q) => q.toMap()).toList();
    await box.put(courseId, dataList);
  }

  // --- Study Materials Operations ---
  List<StudyMaterial> getAllMaterials() {
    final box = Hive.box(AppConstants.downloadsBox);
    return box.values.map((data) => StudyMaterial.fromMap(data as Map)).toList();
  }

  StudyMaterial? getMaterial(String materialId) {
    final box = Hive.box(AppConstants.downloadsBox);
    final data = box.get(materialId);
    if (data == null) return null;
    return StudyMaterial.fromMap(data as Map);
  }

  Future<void> saveMaterial(StudyMaterial material) async {
    final box = Hive.box(AppConstants.downloadsBox);
    await box.put(material.id, material.toMap());
  }

  // --- Claimed Referral Codes ---
  bool isReferralCodeClaimed(String code) {
    final box = Hive.box(AppConstants.claimedCodesBox);
    return box.get(code, defaultValue: false) == true;
  }

  Future<void> markReferralCodeClaimed(String code) async {
    final box = Hive.box(AppConstants.claimedCodesBox);
    await box.put(code, true);
  }

  // --- Clear local database for reset ---
  Future<void> clearAllData() async {
    await Hive.box(AppConstants.profileBox).clear();
    await Hive.box(AppConstants.progressBox).clear();
    await Hive.box(AppConstants.settingsBox).clear();
    await Hive.box(AppConstants.questionsBox).clear();
    await Hive.box(AppConstants.downloadsBox).clear();
    _initDefaults();
  }
}
