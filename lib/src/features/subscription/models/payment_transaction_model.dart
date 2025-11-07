import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_field_names.dart';

class PaymentTransactionModel {
  final String transactionId;
  final double amount;
  final String currency;
  final String paymentMethod;
  final DateTime transactionDateTime;
  final PaymentStatus status;

  PaymentTransactionModel({
    required this.transactionId,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.transactionDateTime,
    required this.status,
  });

  /// Empty
  static PaymentTransactionModel empty() {
    return PaymentTransactionModel(
      transactionId: '',
      amount: 0.0,
      currency: '',
      paymentMethod: '',
      transactionDateTime: DateTime.fromMillisecondsSinceEpoch(0),
      status: PaymentStatus.pending,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.transactionId: transactionId,
      FirebaseFieldNames.amount: amount,
      FirebaseFieldNames.currency: currency,
      FirebaseFieldNames.paymentMethod: paymentMethod,
      FirebaseFieldNames.transactionDateTime: transactionDateTime.millisecondsSinceEpoch,
      FirebaseFieldNames.status: status.value,
    };
  }

  /// From Snapshot
  factory PaymentTransactionModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) return PaymentTransactionModel.empty();

    return PaymentTransactionModel(
      transactionId: data[FirebaseFieldNames.transactionId] ?? '',
      amount: (data[FirebaseFieldNames.amount] ?? 0).toDouble(),
      currency: data[FirebaseFieldNames.currency] ?? '',
      paymentMethod: data[FirebaseFieldNames.paymentMethod] ?? '',
      transactionDateTime: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.transactionDateTime] ?? 0),
      status: PaymentStatus.fromString(
          data[FirebaseFieldNames.status] ?? 'pending'),
    );
  }

  /// From Map (useful for nested docs)
  factory PaymentTransactionModel.fromMap(Map<String, dynamic> data) {
    return PaymentTransactionModel(
      transactionId: data[FirebaseFieldNames.transactionId] ?? '',
      amount: (data[FirebaseFieldNames.amount] ?? 0).toDouble(),
      currency: data[FirebaseFieldNames.currency] ?? '',
      paymentMethod: data[FirebaseFieldNames.paymentMethod] ?? '',
      transactionDateTime: DateTime.fromMillisecondsSinceEpoch(
          data[FirebaseFieldNames.transactionDateTime] ?? 0),
      status: PaymentStatus.fromString(
          data[FirebaseFieldNames.status] ?? 'pending'),
    );
  }

  /// Copy with
  PaymentTransactionModel copyWith({
    String? transactionId,
    double? amount,
    String? currency,
    String? paymentMethod,
    DateTime? transactionDateTime,
    PaymentStatus? status,
  }) {
    return PaymentTransactionModel(
      transactionId: transactionId ?? this.transactionId,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      transactionDateTime: transactionDateTime ?? this.transactionDateTime,
      status: status ?? this.status,
    );
  }
}