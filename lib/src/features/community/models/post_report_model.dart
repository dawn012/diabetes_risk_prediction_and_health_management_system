import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';

class PostReportModel {
  final String reportId;
  final String postId;
  final String reporterId;
  final ReportReason reason;
  final String? additionalNote;
  final ReportStatus status;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const PostReportModel({
    required this.reportId,
    required this.postId,
    required this.reporterId,
    required this.reason,
    this.additionalNote,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  /// Empty constructor
  factory PostReportModel.empty() => PostReportModel(
    reportId: '',
    postId: '',
    reporterId: '',
    reason: ReportReason.other,
    additionalNote: null,
    status: ReportStatus.pending,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
    resolvedAt: null,
  );

  /// Create a copy with updated fields
  PostReportModel copyWith({
    String? reportId,
    String? postId,
    String? reporterId,
    ReportReason? reason,
    String? additionalNote,
    ReportStatus? status,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return PostReportModel(
      reportId: reportId ?? this.reportId,
      postId: postId ?? this.postId,
      reporterId: reporterId ?? this.reporterId,
      reason: reason ?? this.reason,
      additionalNote: additionalNote ?? this.additionalNote,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.reportId: reportId,
      FirebaseFieldNames.postId: postId,
      FirebaseFieldNames.reporterId: reporterId,
      FirebaseFieldNames.reason: reason.value,
      if (additionalNote != null) FirebaseFieldNames.additionalNote: additionalNote,
      FirebaseFieldNames.status: status.value,
      FirebaseFieldNames.createdAt: createdAt.millisecondsSinceEpoch,
      if (resolvedAt != null) FirebaseFieldNames.resolvedAt: resolvedAt!.millisecondsSinceEpoch,
    };
  }

  /// Create from Firestore document
  factory PostReportModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data() ?? {};
    return PostReportModel(
      reportId: data[FirebaseFieldNames.reportId] ?? document.id,
      postId: data[FirebaseFieldNames.postId] ?? '',
      reporterId: data[FirebaseFieldNames.reporterId] ?? '',
      reason: ReportReason.fromString(data[FirebaseFieldNames.reason] ?? 'other'),
      additionalNote: data[FirebaseFieldNames.additionalNote],
      status: ReportStatus.fromString(data[FirebaseFieldNames.status] ?? 'pending'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.createdAt] ?? 0),
      resolvedAt: data[FirebaseFieldNames.resolvedAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.resolvedAt])
          : null,
    );
  }

  @override
  String toString() {
    return 'PostReportModel{reportId: $reportId, postId: $postId, reason: ${reason.displayName}, status: ${status.displayName}}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostReportModel && other.reportId == reportId;
  }

  @override
  int get hashCode => reportId.hashCode;
}