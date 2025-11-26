import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/enums.dart';

/// Delete Account Request Model
/// Manages manager's account deletion requests that require admin approval
class DeleteAccountRequestModel {
  final String requestId;
  final String requesterId; // Manager who made the request
  final String requesterUsername;
  final String requesterEmail;
  final RequestStatus status;
  final String? responderId; // Admin who responded
  final String? responseMessage;
  final DateTime createdAt;
  final DateTime expiresAt; // 48 hours from creation
  final DateTime? respondedAt;

  const DeleteAccountRequestModel({
    required this.requestId,
    required this.requesterId,
    required this.requesterUsername,
    required this.requesterEmail,
    required this.status,
    this.responderId,
    this.responseMessage,
    required this.createdAt,
    required this.expiresAt,
    this.respondedAt,
  });

  /// Empty request
  static DeleteAccountRequestModel empty() {
    return DeleteAccountRequestModel(
      requestId: '',
      requesterId: '',
      requesterUsername: '',
      requesterEmail: '',
      status: RequestStatus.pending,
      createdAt: DateTime(0),
      expiresAt: DateTime(0),
    );
  }

  /// Check if request is expired
  bool get isExpired {
    return status == RequestStatus.pending && DateTime.now().isAfter(expiresAt);
  }

  /// Check if request can be responded to
  bool get canRespond {
    return status == RequestStatus.pending && !isExpired;
  }

  /// Get time remaining until expiration
  Duration get timeRemaining {
    if (isExpired) return Duration.zero;
    return expiresAt.difference(DateTime.now());
  }

  /// Copy with
  DeleteAccountRequestModel copyWith({
    String? requestId,
    String? requesterId,
    String? requesterUsername,
    String? requesterEmail,
    RequestStatus? status,
    String? responderId,
    String? responseMessage,
    DateTime? createdAt,
    DateTime? expiresAt,
    DateTime? respondedAt,
  }) {
    return DeleteAccountRequestModel(
      requestId: requestId ?? this.requestId,
      requesterId: requesterId ?? this.requesterId,
      requesterUsername: requesterUsername ?? this.requesterUsername,
      requesterEmail: requesterEmail ?? this.requesterEmail,
      status: status ?? this.status,
      responderId: responderId ?? this.responderId,
      responseMessage: responseMessage ?? this.responseMessage,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'requestId': requestId,
      'requesterId': requesterId,
      'requesterUsername': requesterUsername,
      'requesterEmail': requesterEmail,
      'status': status.name,
      'responderId': responderId,
      'responseMessage': responseMessage,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'expiresAt': expiresAt.millisecondsSinceEpoch,
      'respondedAt': respondedAt?.millisecondsSinceEpoch,
    };
  }

  /// Create from Firestore document
  factory DeleteAccountRequestModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;

      return DeleteAccountRequestModel(
        requestId: data['requestId'] ?? '',
        requesterId: data['requesterId'] ?? '',
        requesterUsername: data['requesterUsername'] ?? '',
        requesterEmail: data['requesterEmail'] ?? '',
        status: _parseRequestStatus(data['status']),
        responderId: data['responderId'],
        responseMessage: data['responseMessage'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(data['createdAt'] ?? 0),
        expiresAt: DateTime.fromMillisecondsSinceEpoch(data['expiresAt'] ?? 0),
        respondedAt: data['respondedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(data['respondedAt'])
            : null,
      );
    } else {
      return DeleteAccountRequestModel.empty();
    }
  }

  /// Parse request status from string
  static RequestStatus _parseRequestStatus(String? statusString) {
    if (statusString == null) return RequestStatus.pending;

    try {
      return RequestStatus.values.firstWhere(
            (status) => status.name == statusString,
        orElse: () => RequestStatus.pending,
      );
    } catch (e) {
      return RequestStatus.pending;
    }
  }

  @override
  String toString() {
    return 'DeleteAccountRequestModel{requestId: $requestId, status: ${status.name}, isExpired: $isExpired}';
  }
}