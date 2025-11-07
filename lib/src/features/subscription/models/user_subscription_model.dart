import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';
import 'payment_transaction_model.dart';
import 'subscription_plan_model.dart';

class UserSubscriptionModel {
  final String subscriptionId;
  final String userId;
  final SubscriptionPlanModel subscriptionPlan;
  final List<PaymentTransactionModel> paymentTransactions; // Changed to List
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool autoRenew;
  final SubscriptionStatus status;
  final DateTime? cancelAt;

  UserSubscriptionModel({
    required this.subscriptionId,
    required this.userId,
    required this.subscriptionPlan,
    required this.paymentTransactions, // Changed parameter
    required this.startDateTime,
    required this.endDateTime,
    required this.autoRenew,
    required this.status,
    this.cancelAt,
  });

  /// Empty
  static UserSubscriptionModel empty() {
    return UserSubscriptionModel(
      subscriptionId: '',
      userId: '',
      subscriptionPlan: SubscriptionPlanModel.empty(),
      paymentTransactions: [], // Empty list
      startDateTime: DateTime.fromMillisecondsSinceEpoch(0),
      endDateTime: DateTime.fromMillisecondsSinceEpoch(0),
      autoRenew: false,
      status: SubscriptionStatus.active,
    );
  }

  /// Get latest payment transaction (for display)
  PaymentTransactionModel? get latestPayment {
    if (paymentTransactions.isEmpty) return null;
    return paymentTransactions.reduce((a, b) =>
    a.transactionDateTime.isAfter(b.transactionDateTime) ? a : b
    );
  }

  /// Get successful payment transaction
  PaymentTransactionModel? get successfulPayment {
    try {
      return paymentTransactions.firstWhere(
            (t) => t.status == PaymentStatus.succeeded,
      );
    } catch (e) {
      return null;
    }
  }

  /// Get failed payment transactions
  List<PaymentTransactionModel> get failedPayments {
    return paymentTransactions
        .where((t) => t.status == PaymentStatus.failed)
        .toList();
  }

  /// Get total amount paid
  double get totalAmountPaid {
    return paymentTransactions
        .where((t) => t.status == PaymentStatus.succeeded)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Check if has pending payment
  bool get hasPendingPayment {
    return paymentTransactions.any((t) => t.status == PaymentStatus.pending);
  }

  /// Check if has failed payment
  bool get hasFailedPayment {
    return paymentTransactions.any((t) => t.status == PaymentStatus.failed);
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.subscriptionId: subscriptionId,
      FirebaseFieldNames.userId: userId,
      FirebaseFieldNames.subscriptionPlanId: subscriptionPlan.subscriptionPlanId,
      FirebaseFieldNames.startDateTime: startDateTime.millisecondsSinceEpoch,
      FirebaseFieldNames.endDateTime: endDateTime.millisecondsSinceEpoch,
      FirebaseFieldNames.autoRenew: autoRenew,
      FirebaseFieldNames.status: status.value,
      FirebaseFieldNames.cancelAt: cancelAt?.millisecondsSinceEpoch,
    };
  }

  /// From Snapshot
  factory UserSubscriptionModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) return UserSubscriptionModel.empty();

    return UserSubscriptionModel(
      subscriptionId: data[FirebaseFieldNames.subscriptionId] ?? '',
      userId: data[FirebaseFieldNames.userId] ?? '',
      subscriptionPlan: SubscriptionPlanModel.empty(),
      paymentTransactions: [], // Will be populated separately
      startDateTime: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.startDateTime] ?? 0),
      endDateTime: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.endDateTime] ?? 0),
      autoRenew: data[FirebaseFieldNames.autoRenew] ?? false,
      status: SubscriptionStatus.fromString(
          data[FirebaseFieldNames.status] ?? 'active'),
      cancelAt: data[FirebaseFieldNames.cancelAt] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.cancelAt])
          : null,
    );
  }

  /// Copy with
  UserSubscriptionModel copyWith({
    String? subscriptionId,
    String? userId,
    SubscriptionPlanModel? subscriptionPlan,
    List<PaymentTransactionModel>? paymentTransactions, // Changed parameter
    DateTime? startDateTime,
    DateTime? endDateTime,
    bool? autoRenew,
    SubscriptionStatus? status,
    DateTime? cancelAt,
  }) {
    return UserSubscriptionModel(
      subscriptionId: subscriptionId ?? this.subscriptionId,
      userId: userId ?? this.userId,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      paymentTransactions: paymentTransactions ?? this.paymentTransactions,
      startDateTime: startDateTime ?? this.startDateTime,
      endDateTime: endDateTime ?? this.endDateTime,
      autoRenew: autoRenew ?? this.autoRenew,
      status: status ?? this.status,
      cancelAt: cancelAt ?? this.cancelAt,
    );
  }

  /// Check if subscription is active
  bool get isActive => status == SubscriptionStatus.active;

  /// Check if subscription is expired
  bool get isExpired => status == SubscriptionStatus.expired;

  /// Check if subscription is failed
  bool get isFailed => status == SubscriptionStatus.failed;

  /// Check if subscription is pending
  bool get isPending => status == SubscriptionStatus.pending;

  /// Get days remaining
  int get daysRemaining {
    if (!isActive) return 0;
    return endDateTime.difference(DateTime.now()).inDays;
  }
}