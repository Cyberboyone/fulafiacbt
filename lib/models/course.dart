import 'package:flutter/material.dart';

class Course {
  final String id;
  final String code;
  final String name;
  final String icon; // Emoji character or icon key
  final String colorHex; // Hex string for styling
  final String mode; // e.g. "100_level"

  Course({
    required this.id,
    required this.code,
    required this.name,
    required this.icon,
    required this.colorHex,
    this.mode = '100_level',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'icon': icon,
      'colorHex': colorHex,
      'mode': mode,
    };
  }

  factory Course.fromMap(Map<dynamic, dynamic> map) {
    return Course(
      id: map['id'] as String? ?? '',
      code: map['code'] as String? ?? '',
      name: map['name'] as String? ?? '',
      icon: map['icon'] as String? ?? '📘',
      colorHex: map['colorHex'] as String? ?? '#FFE8D6',
      mode: map['mode'] as String? ?? '100_level',
    );
  }

  Color get color {
    try {
      final hexString = colorHex.replaceAll('#', '');
      if (hexString.length == 6) {
        return Color(int.parse('FF$hexString', radix: 16));
      }
      return Color(int.parse(hexString, radix: 16));
    } catch (_) {
      return const Color(0xFFE8D6FF);
    }
  }
}
