import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../services/hive_service.dart';

class SettingsProvider with ChangeNotifier {
  final HiveService _hiveService = HiveService();
  
  late AppSettings _settings;
  AppSettings get settings => _settings;

  SettingsProvider() {
    _settings = _hiveService.getSettings();
  }

  Future<void> toggleSound(bool value) async {
    _settings = _settings.copyWith(soundOn: value);
    await _hiveService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleLowDataMode(bool value) async {
    _settings = _settings.copyWith(lowDataMode: value);
    await _hiveService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> toggleDarkMode(bool value) async {
    _settings = _settings.copyWith(isDarkMode: value);
    await _hiveService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> setAdsRemoved(bool value) async {
    _settings = _settings.copyWith(adsRemoved: value);
    await _hiveService.saveSettings(_settings);
    notifyListeners();
  }

  Future<void> refresh() async {
    _settings = _hiveService.getSettings();
    notifyListeners();
  }
}
