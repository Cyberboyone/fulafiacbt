import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/constants.dart';
import '../models/course.dart';
import '../models/question.dart';
import 'hive_service.dart';

/// One course in the public JSON catalog.
///
/// The catalog is deliberately data-only: adding a course is a JSON edit in the
/// repository, not a Dart, signing, or release-config change.
class CatalogCourse {
  final Course course;
  final String questionFile;
  final String version;

  const CatalogCourse({
    required this.course,
    required this.questionFile,
    required this.version,
  });

  factory CatalogCourse.fromMap(Map<dynamic, dynamic> map) {
    final id = _requiredString(map['id'], 'id');
    if (!_idPattern.hasMatch(id)) {
      throw FormatException('Invalid course id: $id');
    }

    final questionFile = _requiredString(map['file'], 'file');
    if (!_fileNamePattern.hasMatch(questionFile)) {
      throw FormatException('Unsafe question file name: $questionFile');
    }

    return CatalogCourse(
      course: Course(
        id: id,
        code: _requiredString(map['code'], 'code'),
        name: _requiredString(map['name'], 'name'),
        icon: _optionalString(map['icon'], '📘'),
        colorHex: _optionalString(map['colorHex'], '#FFE8D6'),
        mode: _optionalString(map['mode'], '100_level'),
      ),
      questionFile: questionFile,
      version: _optionalString(map['version'], '1.0.0'),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': course.id,
        'code': course.code,
        'name': course.name,
        'icon': course.icon,
        'colorHex': course.colorHex,
        'mode': course.mode,
        'file': questionFile,
        'version': version,
      };
}

class CourseCatalog {
  final int schemaVersion;
  final String updatedAt;
  final List<CatalogCourse> courses;

  const CourseCatalog({
    required this.schemaVersion,
    required this.updatedAt,
    required this.courses,
  });

  factory CourseCatalog.fromMap(Map<dynamic, dynamic> map) {
    final schemaVersion = _int(map['schemaVersion'], 'schemaVersion');
    if (schemaVersion != AppConstants.courseCatalogSchemaVersion) {
      throw FormatException('Unsupported catalog schema version: $schemaVersion');
    }

    final updatedAt = _requiredString(map['updatedAt'], 'updatedAt');
    if (DateTime.tryParse(updatedAt) == null) {
      throw FormatException('Invalid catalog updatedAt: $updatedAt');
    }

    final rawCourses = map['courses'];
    if (rawCourses is! List || rawCourses.isEmpty) {
      throw const FormatException('Catalog must contain a non-empty courses list');
    }

    final seenIds = <String>{};
    final entries = <CatalogCourse>[];
    for (final item in rawCourses) {
      if (item is! Map) {
        throw const FormatException('Each catalog course must be an object');
      }
      final entry = CatalogCourse.fromMap(Map<dynamic, dynamic>.from(item));
      if (!seenIds.add(entry.course.id)) {
        throw FormatException('Duplicate course id: ${entry.course.id}');
      }
      entries.add(entry);
    }

    return CourseCatalog(
      schemaVersion: schemaVersion,
      updatedAt: updatedAt,
      courses: entries,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'schemaVersion': schemaVersion,
        'updatedAt': updatedAt,
        'courses': courses.map((entry) => entry.toMap()).toList(),
      };
}

class CourseSyncResult {
  final List<Course> courses;
  final DateTime? syncedAt;
  final String? error;
  final int newCourseCount;
  final int updatedBankCount;

  const CourseSyncResult({
    required this.courses,
    this.syncedAt,
    this.error,
    this.newCourseCount = 0,
    this.updatedBankCount = 0,
  });
}

/// Loads the bundled course catalog, caches it in Hive, and optionally refreshes
/// it from a public HTTPS JSON file. Everything downloaded is plain question
/// data; no secrets, tokens, or release configuration are involved.
class CourseCatalogService {
  CourseCatalogService._();

  static final CourseCatalogService instance = CourseCatalogService._();

  final HiveService _hiveService = HiveService();
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 6),
    ),
  );

  CourseCatalog? _bundledCatalog;
  bool _syncInProgress = false;

  /// Offline startup work: read the bundled catalog and seed question banks that
  /// are not already cached. Remote sync is started separately by CourseProvider
  /// so the UI never waits on the network.
  Future<void> initialize() async {
    try {
      final bundled = await _loadBundledCatalog();
      _bundledCatalog = bundled;
      await _ensureBundledQuestions(bundled);

      final cached = _readCachedCatalog();
      if (cached == null || _isNewer(bundled.updatedAt, cached.updatedAt)) {
        await _hiveService.saveCourseCatalog(bundled.toMap());
      }
    } catch (e) {
      // The legacy CourseProvider list remains as a last-resort fallback.
      debugPrint('Course catalog initialization failed: $e');
    }
  }

  /// Synchronously returns the last known catalog for the first widget build.
  /// Only courses with a local question bank are exposed, so a failed download
  /// cannot create a course tile with no questions.
  List<Course>? loadCachedCourses() {
    final catalog = _readCachedCatalog() ?? _bundledCatalog;
    if (catalog == null) return null;
    return _availableCourses(catalog);
  }

  /// Checks the public catalog, downloads new/changed question banks, and saves
  /// them in Hive. On any failure the previously cached courses are returned.
  Future<CourseSyncResult> sync() async {
    if (_syncInProgress) {
      return CourseSyncResult(
        courses: _currentCourses(),
        syncedAt: _hiveService.getLastCourseSync(),
        error: 'A course update is already running.',
      );
    }

    _syncInProgress = true;
    try {
      final bundled = _bundledCatalog ?? await _loadBundledCatalog();
      _bundledCatalog = bundled;
      await _ensureBundledQuestions(bundled);

      final current = _readCachedCatalog() ?? bundled;
      final previousIds = current.courses.map((entry) => entry.course.id).toSet();

      final remoteMap = await _fetchJsonMap(_catalogFetchUri());
      final remote = CourseCatalog.fromMap(remoteMap);

      if (_isNewer(current.updatedAt, remote.updatedAt)) {
        return CourseSyncResult(
          courses: _availableCourses(current),
          syncedAt: _hiveService.getLastCourseSync(),
          error: 'The online catalog is older than the one on this device; keeping current courses.',
        );
      }

      var updatedBanks = 0;
      final failures = <String>[];

      for (final entry in remote.courses) {
        final expectedKey = _contentKey(entry);
        final needsDownload =
            _hiveService.getCachedQuestions(entry.course.id).isEmpty ||
                _hiveService.getCourseContentVersion(entry.course.id) != expectedKey;
        if (!needsDownload) continue;

        try {
          final decoded = await _fetchJson(_questionUri(entry));
          final questions = _parseQuestions(
            decoded,
            expectedCourseId: entry.course.id,
          );
          if (questions.isEmpty) {
            throw const FormatException('Question bank is empty');
          }
          await _hiveService.cacheQuestions(entry.course.id, questions);
          await _hiveService.saveCourseContentVersion(entry.course.id, expectedKey);
          updatedBanks++;
        } catch (e) {
          failures.add(entry.course.id);
          debugPrint('Could not update question bank ${entry.course.id}: $e');
        }
      }

      // Save the catalog even if a bank failed: the failed course keeps its old
      // content key, so the next sync will retry it automatically.
      await _hiveService.saveCourseCatalog(remote.toMap());
      final now = DateTime.now();
      await _hiveService.setLastCourseSync(now);

      final available = _availableCourses(remote);
      final availableIds = available.map((course) => course.id).toSet();
      final newCourseCount = remote.courses
          .where((entry) =>
              !previousIds.contains(entry.course.id) &&
              availableIds.contains(entry.course.id))
          .length;

      final String? syncError = failures.isEmpty
          ? null
          : '${failures.length} course update(s) could not be downloaded. '
              'They will retry on the next sync.';

      return CourseSyncResult(
        courses: available,
        syncedAt: now,
        error: syncError,
        newCourseCount: newCourseCount,
        updatedBankCount: updatedBanks,
      );
    } catch (e) {
      debugPrint('Course catalog sync failed: $e');
      return CourseSyncResult(
        courses: await _fallbackCourses(),
        syncedAt: _hiveService.getLastCourseSync(),
        error: 'Could not check for new courses. Your saved courses are still available.',
      );
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _ensureBundledQuestions(CourseCatalog catalog) async {
    for (final entry in catalog.courses) {
      final courseId = entry.course.id;
      if (_hiveService.getCachedQuestions(courseId).isNotEmpty) continue;

      try {
        final raw = await rootBundle.loadString('assets/questions/${entry.questionFile}');
        final questions = _parseQuestions(
          json.decode(raw),
          expectedCourseId: courseId,
        );
        if (questions.isEmpty) continue;

        await _hiveService.cacheQuestions(courseId, questions);
        await _hiveService.saveCourseContentVersion(courseId, _contentKey(entry));
        debugPrint('Seeded ${questions.length} questions for $courseId');
      } catch (e) {
        debugPrint('Could not seed bundled questions for $courseId: $e');
      }
    }
  }

  List<Course> _availableCourses(CourseCatalog catalog) {
    return catalog.courses
        .where((entry) => _hiveService.getCachedQuestions(entry.course.id).isNotEmpty)
        .map((entry) => entry.course)
        .toList();
  }

  List<Course> _currentCourses() {
    final catalog = _readCachedCatalog() ?? _bundledCatalog;
    if (catalog == null) return const <Course>[];
    return _availableCourses(catalog);
  }

  Future<List<Course>> _fallbackCourses() async {
    final catalog = _readCachedCatalog() ?? _bundledCatalog;
    if (catalog != null) return _availableCourses(catalog);

    try {
      final bundled = await _loadBundledCatalog();
      _bundledCatalog = bundled;
      return _availableCourses(bundled);
    } catch (_) {
      return const <Course>[];
    }
  }

  Future<CourseCatalog> _loadBundledCatalog() async {
    final raw = await rootBundle.loadString(AppConstants.courseCatalogAsset);
    final decoded = json.decode(raw);
    if (decoded is! Map) {
      throw const FormatException('Course catalog must be a JSON object');
    }
    return CourseCatalog.fromMap(Map<dynamic, dynamic>.from(decoded));
  }

  CourseCatalog? _readCachedCatalog() {
    final map = _hiveService.getCourseCatalog();
    if (map == null) return null;
    try {
      return CourseCatalog.fromMap(Map<dynamic, dynamic>.from(map));
    } catch (e) {
      debugPrint('Ignoring invalid cached course catalog: $e');
      return null;
    }
  }

  bool _isNewer(String candidate, String current) {
    final a = DateTime.tryParse(candidate);
    final b = DateTime.tryParse(current);
    if (a == null) return false;
    if (b == null) return true;
    return a.isAfter(b);
  }

  String _contentKey(CatalogCourse entry) =>
      '${entry.version}::${entry.questionFile}';

  Uri _catalogSourceUri() {
    final uri = Uri.parse(AppConstants.courseCatalogUrl);
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      throw const FormatException('Course catalog URL must use http or https');
    }
    return uri;
  }

  Uri _catalogBaseUri() =>
      _catalogSourceUri().replace(query: '', fragment: '');

  Uri _catalogFetchUri() {
    final source = _catalogSourceUri();
    final params = <String, dynamic>{
      ...source.queryParameters,
      '_': DateTime.now().millisecondsSinceEpoch.toString(),
    };
    return source.replace(queryParameters: params);
  }

  Uri _questionUri(CatalogCourse entry) {
    final base = _catalogBaseUri();
    final resolved = base.resolve(entry.questionFile);
    if (resolved.scheme != base.scheme || resolved.host != base.host) {
      throw const FormatException('Question file resolved outside the catalog host');
    }
    final params = <String, dynamic>{
      ...resolved.queryParameters,
      'v': Uri.encodeComponent(entry.version),
    };
    return resolved.replace(queryParameters: params);
  }

  Future<Map<dynamic, dynamic>> _fetchJsonMap(Uri uri) async {
    final decoded = await _fetchJson(uri);
    if (decoded is! Map) {
      throw FormatException('Expected a JSON object from $uri');
    }
    return Map<dynamic, dynamic>.from(decoded);
  }

  Future<dynamic> _fetchJson(Uri uri) async {
    final response = await _dio.getUri<String>(
      uri,
      options: Options(
        responseType: ResponseType.plain,
        receiveTimeout: const Duration(seconds: 12),
        headers: <String, dynamic>{'Cache-Control': 'no-cache'},
      ),
    );
    final data = response.data;
    if (data is! String || data.isEmpty) {
      throw FormatException('Empty response from $uri');
    }
    return json.decode(data);
  }
}

List<Question> _parseQuestions(
  dynamic decoded, {
  String? expectedCourseId,
}) {
  if (decoded is! Map) {
    throw const FormatException('Question bank must be a JSON object');
  }

  final root = Map<dynamic, dynamic>.from(decoded);
  final declaredId = root['course_id'];
  if (expectedCourseId != null &&
      declaredId is String &&
      declaredId.isNotEmpty &&
      declaredId != expectedCourseId) {
    throw FormatException(
      'Question bank course_id "$declaredId" does not match "$expectedCourseId"',
    );
  }

  final rawQuestions = root['questions'];
  if (rawQuestions is! List || rawQuestions.isEmpty) {
    throw const FormatException('Question bank has no questions');
  }
  if (rawQuestions.length > 2000) {
    throw const FormatException('Question bank is too large');
  }

  final questions = <Question>[];
  for (var i = 0; i < rawQuestions.length; i++) {
    final item = rawQuestions[i];
    if (item is! Map) {
      throw FormatException('Question #${i + 1} must be an object');
    }
    final map = Map<dynamic, dynamic>.from(item);

    final textCandidate = map['text'];
    final textValue = (textCandidate is String && textCandidate.trim().isNotEmpty)
        ? textCandidate
        : map['question'];
    final text = _requiredString(textValue, 'text/question');

    final rawOptions = map['options'];
    if (rawOptions is! List || rawOptions.length < 2 || rawOptions.length > 6) {
      throw FormatException('Question #${i + 1} needs 2 to 6 options');
    }
    final options = <String>[];
    for (final option in rawOptions) {
      if (option is! String || option.trim().isEmpty) {
        throw FormatException('Question #${i + 1} has an invalid option');
      }
      options.add(option);
    }

    final correctIndex =
        _int(map['correct_index'] ?? map['correctIndex'], 'correct_index');
    if (correctIndex < 0 || correctIndex >= options.length) {
      throw FormatException('Question #${i + 1} has an out-of-range correct_index');
    }

    questions.add(
      Question(
        id: _optionalString(map['id'], '${expectedCourseId ?? 'course'}_${i + 1}'),
        text: text,
        options: options,
        correctIndex: correctIndex,
        explanation: _optionalString(map['explanation'], ''),
        difficulty: _optionalInt(map['difficulty'], 1, min: 1, max: 5),
      ),
    );
  }

  return questions;
}

final RegExp _idPattern = RegExp(r'^[a-z0-9][a-z0-9_-]*$');
final RegExp _fileNamePattern =
    RegExp(r'^[A-Za-z0-9][A-Za-z0-9_.-]*\.json$');

String _requiredString(dynamic value, String field) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  throw FormatException('Missing or invalid "$field"');
}

String _optionalString(dynamic value, String fallback) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

int _int(dynamic value, String field) {
  if (value is bool) {
    throw FormatException('Invalid "$field"');
  }
  if (value is int) return value;
  if (value is num && value.toInt() == value) return value.toInt();
  throw FormatException('Missing or invalid "$field"');
}

int _optionalInt(
  dynamic value,
  int fallback, {
  int? min,
  int? max,
}) {
  int parsed;
  try {
    parsed = _int(value, 'value');
  } catch (_) {
    return fallback;
  }
  if (min != null && parsed < min) parsed = min;
  if (max != null && parsed > max) parsed = max;
  return parsed;
}
