class StudyMaterial {
  final String id;
  final String title;
  final String courseId;
  final String fileUrl;
  final int version;
  final String size;
  final bool isDownloaded;
  final String? localPath;

  StudyMaterial({
    required this.id,
    required this.title,
    required this.courseId,
    required this.fileUrl,
    required this.version,
    required this.size,
    this.isDownloaded = false,
    this.localPath,
  });

  StudyMaterial copyWith({
    bool? isDownloaded,
    String? localPath,
  }) {
    return StudyMaterial(
      id: this.id,
      title: this.title,
      courseId: this.courseId,
      fileUrl: this.fileUrl,
      version: this.version,
      size: this.size,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localPath: localPath ?? this.localPath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'courseId': courseId,
      'fileUrl': fileUrl,
      'version': version,
      'size': size,
      'isDownloaded': isDownloaded,
      'localPath': localPath,
    };
  }

  factory StudyMaterial.fromMap(Map<dynamic, dynamic> map) {
    return StudyMaterial(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      courseId: map['courseId'] as String? ?? '',
      fileUrl: map['fileUrl'] as String? ?? '',
      version: map['version'] as int? ?? 1,
      size: map['size'] as String? ?? '0MB',
      isDownloaded: map['isDownloaded'] as bool? ?? false,
      localPath: map['localPath'] as String?,
    );
  }
}
