import 'package:hive/hive.dart';
import 'meal_analysis_result_model.dart';

part 'meal_photo_record_model.g.dart';

@HiveType(typeId: 1)
class MealPhotoRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String imagePath;  // 共用字段：本地时存 localPath，云端时存 storageUrl

  @HiveField(2)
  final int fileSize;

  @HiveField(3)
  final DateTime uploadTime;

  @HiveField(4)
  final bool needsProcessing;

  @HiveField(5)
  final MealAnalysisResult? analysisResult;

  MealPhotoRecord({
    required this.id,
    required this.imagePath,
    required this.fileSize,
    required this.uploadTime,
    this.needsProcessing = true,
    this.analysisResult,
  });

  /// Get file size in MB
  double getSizeInMB() {
    return fileSize / (1024 * 1024);
  }

  /// Get formatted size string
  String getSizeFormatted() {
    final sizeInMB = getSizeInMB();
    if (sizeInMB < 0.1) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    }
    return '${sizeInMB.toStringAsFixed(2)} MB';
  }

  /// Copy with
  MealPhotoRecord copyWith({
    String? id,
    String? imagePath,
    int? fileSize,
    DateTime? uploadTime,
    bool? needsProcessing,
    MealAnalysisResult? analysisResult,
  }) {
    return MealPhotoRecord(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      fileSize: fileSize ?? this.fileSize,
      uploadTime: uploadTime ?? this.uploadTime,
      needsProcessing: needsProcessing ?? this.needsProcessing,
      analysisResult: analysisResult ?? this.analysisResult,
    );
  }

  /// To JSON (for backup/export)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'fileSize': fileSize,
      'uploadTime': uploadTime.toIso8601String(),
      'needsProcessing': needsProcessing,
      'analysisResult': analysisResult?.toJson(),
    };
  }

  /// From JSON
  factory MealPhotoRecord.fromJson(Map<String, dynamic> json) {
    return MealPhotoRecord(
      id: json['id'],
      imagePath: json['imagePath'],
      fileSize: json['fileSize'],
      uploadTime: DateTime.parse(json['uploadTime']),
      needsProcessing: json['needsProcessing'] ?? true,
      analysisResult: json['analysisResult'] != null
          ? MealAnalysisResult.fromJson(json['analysisResult'])
          : null,
    );
  }

  /// 便捷方法：创建云端照片记录
  factory MealPhotoRecord.createFromCloud({
    required String id,
    required String storageUrl,
    required DateTime uploadTime,
    MealAnalysisResult? analysisResult,
  }) {
    return MealPhotoRecord(
      id: id,
      imagePath: storageUrl, // 使用 storageUrl 作为 imagePath
      fileSize: 0, // 云端记录文件大小为 0（不需要）
      uploadTime: uploadTime,
      needsProcessing: false, // 云端记录已经处理过
      analysisResult: analysisResult,
    );
  }

  /// 检查是否是本地路径
  bool get isLocalPath => imagePath.startsWith('/') ||
      imagePath.startsWith('file://');

  /// 检查是否是网络URL
  bool get isNetworkUrl => imagePath.startsWith('http://') ||
      imagePath.startsWith('https://');

  @override
  String toString() {
    return 'MealPhotoRecord(id: $id, size: ${getSizeFormatted()}, processed: ${!needsProcessing})';
  }
}
