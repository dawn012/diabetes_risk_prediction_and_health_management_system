import 'package:hive/hive.dart';
import 'meal_analysis_result_model.dart';

part 'meal_photo_record_model.g.dart';

@HiveType(typeId: 1)
class MealPhotoRecord extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String localPath;

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
    required this.localPath,
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
    String? localPath,
    int? fileSize,
    DateTime? uploadTime,
    bool? needsProcessing,
    MealAnalysisResult? analysisResult,
  }) {
    return MealPhotoRecord(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
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
      'localPath': localPath,
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
      localPath: json['localPath'],
      fileSize: json['fileSize'],
      uploadTime: DateTime.parse(json['uploadTime']),
      needsProcessing: json['needsProcessing'] ?? true,
      analysisResult: json['analysisResult'] != null
          ? MealAnalysisResult.fromJson(json['analysisResult'])
          : null,
    );
  }

  @override
  String toString() {
    return 'MealPhotoRecord(id: $id, size: ${getSizeFormatted()}, processed: ${!needsProcessing})';
  }
}

// import 'dart:io';
//
// import '../../../utils/helpers/meal_photo_helper.dart';
// import 'meal_analysis_result_model.dart';
//
// /// Model for meal photo with analysis data
// class MealPhotoRecord {
//   final String id;
//   final String localPath;
//   final int fileSize;
//   final DateTime uploadTime;
//   final bool needsProcessing;
//   final MealAnalysisResult? analysisResult;
//
//   const MealPhotoRecord({
//     required this.id,
//     required this.localPath,
//     required this.fileSize,
//     required this.uploadTime,
//     this.needsProcessing = true,
//     this.analysisResult,
//   });
//
//   Map<String, dynamic> toJson() => {
//     'id': id,
//     'localPath': localPath,
//     'fileSize': fileSize,
//     'uploadTime': uploadTime.toIso8601String(),
//     'needsProcessing': needsProcessing,
//     if (analysisResult != null) 'analysisResult': analysisResult!.toJson(),
//   };
//
//   factory MealPhotoRecord.fromJson(Map<String, dynamic> json) => MealPhotoRecord(
//     id: json['id'],
//     localPath: json['localPath'],
//     fileSize: json['fileSize'],
//     uploadTime: DateTime.parse(json['uploadTime']),
//     needsProcessing: json['needsProcessing'] ?? true,
//     analysisResult: json['analysisResult'] != null
//         ? MealAnalysisResult.fromJson(json['analysisResult'])
//         : null,
//   );
//
//   MealPhotoRecord copyWith({
//     String? id,
//     String? localPath,
//     int? fileSize,
//     DateTime? uploadTime,
//     bool? needsProcessing,
//     MealAnalysisResult? analysisResult,
//   }) => MealPhotoRecord(
//     id: id ?? this.id,
//     localPath: localPath ?? this.localPath,
//     fileSize: fileSize ?? this.fileSize,
//     uploadTime: uploadTime ?? this.uploadTime,
//     needsProcessing: needsProcessing ?? this.needsProcessing,
//     analysisResult: analysisResult ?? this.analysisResult,
//   );
//
//   /// Get formatted file size
//   String getSizeFormatted() => MealPhotoHelper.getFormattedSize(File(localPath));
//
//   /// Check if photo has been analyzed
//   bool get isAnalyzed => analysisResult != null && !needsProcessing;
//
//   /// Get GL value if available
//   double? get glycemicLoad => analysisResult?.totalGL;
//
//   /// Get GL category if available
//   String? get glCategory => analysisResult?.glCategory;
//
//   /// Check if analysis has errors
//   bool get hasAnalysisError => analysisResult?.hasError ?? false;
// }