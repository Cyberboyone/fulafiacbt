import '../models/profile.dart';
import '../models/progress.dart';
import '../models/settings.dart';
import '../services/hive_service.dart';
import '../utils/backup_codec.dart';

class BackupService {
  final HiveService _hiveService = HiveService();

  // Generate backup code
  String generateBackupCode() {
    final profile = _hiveService.getProfile();
    if (profile == null) return '';

    final settings = _hiveService.getSettings();
    final progressList = _hiveService.getAllProgress();

    final data = {
      'profile': profile.toMap(),
      'settings': settings.toMap(),
      'progress': progressList.map((p) => p.toMap()).toList(),
      'timestamp': DateTime.now().toIso8601String(),
    };

    return BackupCodec.encode(data);
  }

  // Restore from backup code
  Future<bool> restoreFromCode(String code) async {
    final decoded = BackupCodec.decode(code);
    if (decoded == null) return false;

    try {
      // Clear current boxes
      await _hiveService.clearAllData();

      // Restore profile
      if (decoded.containsKey('profile')) {
        final profile = Profile.fromMap(decoded['profile'] as Map);
        await _hiveService.saveProfile(profile);
      }

      // Restore settings
      if (decoded.containsKey('settings')) {
        final settings = AppSettings.fromMap(decoded['settings'] as Map);
        await _hiveService.saveSettings(settings);
      }

      // Restore progress items
      if (decoded.containsKey('progress')) {
        final progressList = decoded['progress'] as List;
        for (var item in progressList) {
          final progress = CourseProgress.fromMap(item as Map);
          await _hiveService.saveProgress(progress);
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
