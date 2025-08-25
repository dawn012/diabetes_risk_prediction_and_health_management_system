import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/firebase_field_names.dart';
import 'payment_transaction_model.dart';
import 'subscription_plan_model.dart';

class UserSubscriptionModel {
  final String subscriptionId;
  final String userId;
  final SubscriptionPlanModel subscriptionPlan;
  final PaymentTransactionModel paymentTransaction;
  final DateTime startDateTime;
  final DateTime endDateTime;
  final bool autoRenew;
  final String status;

  UserSubscriptionModel({
    required this.subscriptionId,
    required this.userId,
    required this.subscriptionPlan,
    required this.paymentTransaction,
    required this.startDateTime,
    required this.endDateTime,
    required this.autoRenew,
    required this.status
  });

  /// Empty
  static UserSubscriptionModel empty() {
    return UserSubscriptionModel(
      subscriptionId: '',
      userId: '',
      subscriptionPlan: SubscriptionPlanModel.empty(),
      paymentTransaction: PaymentTransactionModel.empty(),
      startDateTime: DateTime(0),
      endDateTime: DateTime(0),
      autoRenew: false,
      status: '',
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.subscriptionId: subscriptionId,
      FirebaseFieldNames.userId: userId,
      FirebaseFieldNames.subscriptionPlan: subscriptionPlan.toJson(),
      FirebaseFieldNames.paymentTransaction: paymentTransaction.toJson(),
      FirebaseFieldNames.startDateTime: Timestamp.fromDate(startDateTime),
      FirebaseFieldNames.endDateTime: Timestamp.fromDate(endDateTime),
      FirebaseFieldNames.autoRenew: autoRenew,
      FirebaseFieldNames.status: status,
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
      subscriptionPlan: data[FirebaseFieldNames.subscriptionPlan] != null
          ? SubscriptionPlanModel.fromMap(
          Map<String, dynamic>.from(data[FirebaseFieldNames.subscriptionPlan]))
          : SubscriptionPlanModel.empty(),
      paymentTransaction: data[FirebaseFieldNames.paymentTransaction] != null
          ? PaymentTransactionModel.fromMap(
          Map<String, dynamic>.from(data[FirebaseFieldNames.paymentTransaction]))
          : PaymentTransactionModel.empty(),
      startDateTime:
      (data[FirebaseFieldNames.startDateTime] as Timestamp).toDate(),
      endDateTime: (data[FirebaseFieldNames.endDateTime] as Timestamp).toDate(),
      autoRenew: data[FirebaseFieldNames.autoRenew] ?? false,
      status: data[FirebaseFieldNames.status] ?? '',
    );
  }
}
