class AppSettings {
  final bool soundOn;
  final bool adsRemoved;
  final bool lowDataMode;
  final bool isDarkMode;

  AppSettings({
    this.soundOn = true,
    this.adsRemoved = false,
    this.lowDataMode = false,
    this.isDarkMode = true,
  });

  AppSettings copyWith({
    bool? soundOn,
    bool? adsRemoved,
    bool? lowDataMode,
    bool? isDarkMode,
  }) {
    return AppSettings(
      soundOn: soundOn ?? this.soundOn,
      adsRemoved: adsRemoved ?? this.adsRemoved,
      lowDataMode: lowDataMode ?? this.lowDataMode,
      isDarkMode: isDarkMode ?? this.isDarkMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'soundOn': soundOn,
      'adsRemoved': adsRemoved,
      'lowDataMode': lowDataMode,
      'isDarkMode': isDarkMode,
    };
  }

  factory AppSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppSettings(
      soundOn: map['soundOn'] as bool? ?? true,
      adsRemoved: map['adsRemoved'] as bool? ?? false,
      lowDataMode: map['lowDataMode'] as bool? ?? false,
      isDarkMode: map['isDarkMode'] as bool? ?? true,
    );
  }
}
