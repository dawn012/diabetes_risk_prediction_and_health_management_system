import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/firebase_field_names.dart';

class SubscriptionPlanModel {
  final String subscriptionPlanId;
  final String planName;
  final double price;
  final int durationDays;
  final List<String> features;
  final bool isActive;

  SubscriptionPlanModel({
    required this.subscriptionPlanId,
    required this.planName,
    required this.price,
    required this.durationDays,
    required this.features,
    required this.isActive
  });

  /// Empty
  static SubscriptionPlanModel empty() {
    return SubscriptionPlanModel(
      subscriptionPlanId: '',
      planName: '',
      price: 0.0,
      durationDays: 0,
      features: [],
      isActive: false,
    );
  }

  /// To JSON
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.subscriptionPlanId: subscriptionPlanId,
      FirebaseFieldNames.planName: planName,
      FirebaseFieldNames.price: price,
      FirebaseFieldNames.durationDays: durationDays,
      FirebaseFieldNames.features: features,
      FirebaseFieldNames.isActive: isActive,
    };
  }

  /// From Snapshot
  factory SubscriptionPlanModel.fromSnapshot(
      DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) return SubscriptionPlanModel.empty();

    return SubscriptionPlanModel(
      subscriptionPlanId: data[FirebaseFieldNames.subscriptionPlanId] ?? '',
      planName: data[FirebaseFieldNames.planName] ?? '',
      price: (data[FirebaseFieldNames.price] ?? 0).toDouble(),
      durationDays: data[FirebaseFieldNames.durationDays] ?? 0,
      features: List<String>.from(data[FirebaseFieldNames.features] ?? []),
      isActive: data[FirebaseFieldNames.isActive] ?? false,
    );
  }

  /// From Map
  factory SubscriptionPlanModel.fromMap(Map<String, dynamic> data) {
    return SubscriptionPlanModel(
      subscriptionPlanId: data[FirebaseFieldNames.subscriptionPlanId] ?? '',
      planName: data[FirebaseFieldNames.planName] ?? '',
      price: (data[FirebaseFieldNames.price] ?? 0).toDouble(),
      durationDays: data[FirebaseFieldNames.durationDays] ?? 0,
      features: List<String>.from(data[FirebaseFieldNames.features] ?? []),
      isActive: data[FirebaseFieldNames.isActive] ?? false,
    );
  }
}
