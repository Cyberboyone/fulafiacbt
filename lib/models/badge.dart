class GamifiedBadge {
  final String id;
  final String name;
  final String description;
  final String icon; // Emoji icon representing badge
  final DateTime? unlockedAt;

  GamifiedBadge({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;

  GamifiedBadge unlock() {
    return GamifiedBadge(
      id: id,
      name: name,
      description: description,
      icon: icon,
      unlockedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  factory GamifiedBadge.fromMap(Map<dynamic, dynamic> map) {
    return GamifiedBadge(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      icon: map['icon'] as String? ?? '🏆',
      unlockedAt: _safeParseDateTime(map['unlockedAt']),
    );
  }

  static DateTime? _safeParseDateTime(dynamic value) {
    if (value is String) {
      try { return DateTime.parse(value); } catch (_) {}
    }
    return null;
  }
}
