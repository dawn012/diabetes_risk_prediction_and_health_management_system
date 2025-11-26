import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../features/subscription/models/payment_transaction_model.dart';
import '../../../features/subscription/models/subscription_plan_model.dart';
import '../../../features/subscription/models/user_subscription_model.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import 'payment_repository.dart';

class SubscriptionRepository extends GetxController {
  static SubscriptionRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final PaymentRepository _paymentRepo = Get.put(PaymentRepository());

  /// Get Firebase Auth user
  User? get authUser => FirebaseAuth.instance.currentUser;

  final uuid = Uuid();

  late final CollectionReference _subscriptionsCollection;
  late final CollectionReference _paymentsCollection;
  late final CollectionReference _plansCollection;

  @override
  void onInit() {
    super.onInit();
    _subscriptionsCollection =
        _db.collection(FirebaseCollectionNames.userSubscriptions);
    _paymentsCollection = _db.collection(FirebaseCollectionNames.payments);
    _plansCollection =
        _db.collection(FirebaseCollectionNames.subscriptionPlans);
  }

  /// Get all subscription plans
  Future<List<SubscriptionPlanModel>> getAllPlans() async {
    try {
      final querySnapshot =
      await _plansCollection.orderBy('price', descending: false).get();

      return querySnapshot.docs
          .map((doc) => SubscriptionPlanModel.fromSnapshot(
          doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error getting all plans: $e');
      return [];
    }
  }

  /// Create a new subscription with payment
  Future<void> createSubscription(UserSubscriptionModel subscription) async {
    try {
      final batch = _db.batch();

      // 1. Create payment transaction record (first transaction only)
      if (subscription.paymentTransactions.isNotEmpty) {
        await _paymentRepo.createPaymentTransaction(
          transaction: subscription.paymentTransactions.first,
          subscriptionId: subscription.subscriptionId,
        );
      }

      // 2. Create user subscription record
      final subscriptionDoc =
      _subscriptionsCollection.doc(subscription.subscriptionId);
      batch.set(subscriptionDoc, subscription.toJson());

      await batch.commit();
      print(
          'Subscription created successfully: ${subscription.subscriptionId}');
    } catch (e) {
      print('Error creating subscription: $e');
      throw Exception('Failed to create subscription: $e');
    }
  }

  /// Create pending subscription without payment (用于 pending 状态)
  Future<void> createPendingSubscriptionOnly(
      UserSubscriptionModel subscription) async {
    try {
      final subscriptionDoc =
      _subscriptionsCollection.doc(subscription.subscriptionId);

      // 只保存 subscription，不创建 payment
      final subscriptionData = subscription.toJson();

      await subscriptionDoc.set(subscriptionData);
      print(
          'Pending subscription created (no payment): ${subscription.subscriptionId}');
    } catch (e) {
      print('Error creating pending subscription: $e');
      throw Exception('Failed to create pending subscription: $e');
    }
  }

  /// Add payment to existing subscription (for auto-renew or retry)
  Future<void> addPaymentToSubscription({
    required String subscriptionId,
    required PaymentTransactionModel payment,
  }) async {
    try {
      await _paymentRepo.createPaymentTransaction(
        transaction: payment,
        subscriptionId: subscriptionId,
      );
      print('Payment added to subscription: $subscriptionId');
    } catch (e) {
      print('Error adding payment to subscription: $e');
      throw Exception('Failed to add payment: $e');
    }
  }

  /// Get user's active subscription
  Future<UserSubscriptionModel?> getActiveSubscription(String userId) async {
    try {
      final querySnapshot = await _subscriptionsCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: SubscriptionStatus.active.value)
          .orderBy('endDateTime', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return await _buildSubscriptionFromDoc(querySnapshot.docs.first);
    } catch (e) {
      print('Error getting active subscription: $e');
      return null;
    }
  }

  /// Stream active subscription status
  Stream<bool> streamHasActiveSubscription(String userId) {
    try {
      return _subscriptionsCollection
          .where(FirebaseFieldNames.userId, isEqualTo: userId)
          .where(FirebaseFieldNames.status, isEqualTo: SubscriptionStatus.active.value)
          .limit(1)
          .snapshots()
          .map((querySnapshot) {
        final hasActive = querySnapshot.docs.isNotEmpty;
        print('Active subscription status update: $hasActive');
        return hasActive;
      }).handleError((error) {
        print('Error in streamHasActiveSubscription: $error');
        return false;
      });
    } catch (e) {
      print('Error setting up streamHasActiveSubscription: $e');
      return Stream.value(false);
    }
  }

  /// Check if user has pending subscription
  Future<bool> hasPendingSubscription(String userId) async {
    try {
      final querySnapshot = await _subscriptionsCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: SubscriptionStatus.pending.value)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Error checking pending subscription: $e');
      return false;
    }
  }

  /// Get user's pending subscription
  Future<UserSubscriptionModel?> getPendingSubscription(String userId) async {
    try {
      final querySnapshot = await _subscriptionsCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: SubscriptionStatus.pending.value)
          .orderBy('startDateTime', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return await _buildSubscriptionFromDoc(querySnapshot.docs.first);
    } catch (e) {
      print('Error getting pending subscription: $e');
      return null;
    }
  }

  /// Get subscription by ID
  Future<UserSubscriptionModel?> getSubscriptionById(
      String subscriptionId) async {
    try {
      final doc = await _subscriptionsCollection.doc(subscriptionId).get();
      if (!doc.exists) return null;

      return await _buildSubscriptionFromDoc(doc);
    } catch (e) {
      print('Error getting subscription by ID: $e');
      return null;
    }
  }

  /// Get user's subscription history
  Future<List<UserSubscriptionModel>> getSubscriptionHistory(
      String userId) async {
    try {
      final querySnapshot = await _subscriptionsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('startDateTime', descending: true)
          .get();

      List<UserSubscriptionModel> subscriptions = [];
      for (var doc in querySnapshot.docs) {
        final subscription = await _buildSubscriptionFromDoc(doc);
        if (subscription != null) {
          subscriptions.add(subscription);
        }
      }
      return subscriptions;
    } catch (e) {
      print('Error getting subscription history: $e');
      return [];
    }
  }

  /// Stream user subscriptions in real-time
  Stream<List<UserSubscriptionModel>> streamUserSubscriptions() {
    final userId = authUser?.uid;
    if (userId == null) {
      print('No authenticated user');
      return Stream.value([]);
    }

    try {
      return _subscriptionsCollection
          .where(FirebaseFieldNames.userId, isEqualTo: userId)
          .orderBy(FirebaseFieldNames.startDateTime, descending: true)
          .snapshots()
          .asyncMap((querySnapshot) async {
        if (querySnapshot.docs.isEmpty) {
          return <UserSubscriptionModel>[];
        }

        List<UserSubscriptionModel> subscriptions = [];

        for (var doc in querySnapshot.docs) {
          try {
            final subscription = await _buildSubscriptionFromDoc(doc);
            if (subscription != null) {
              subscriptions.add(subscription);
            }
          } catch (e) {
            print('Error building subscription from doc ${doc.id}: $e');
            continue;
          }
        }

        return subscriptions;
      }).handleError((error) {
        print('Error in streamUserSubscriptions: $error');
        return <UserSubscriptionModel>[];
      });
    } catch (e) {
      print('Error setting up streamUserSubscriptions: $e');
      return Stream.value([]);
    }
  }

  /// Stream active subscription in real-time
  Stream<UserSubscriptionModel?> streamActiveSubscription() {
    final userId = authUser?.uid;
    if (userId == null) {
      print('No authenticated user');
      return Stream.value(null);
    }

    try {
      return _subscriptionsCollection
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: SubscriptionStatus.active.value)
          .orderBy('endDateTime', descending: true)
          .limit(1)
          .snapshots()
          .asyncMap((querySnapshot) async {
        if (querySnapshot.docs.isEmpty) return null;
        return await _buildSubscriptionFromDoc(querySnapshot.docs.first);
      });
    } catch (e) {
      print('Error streaming active subscription: $e');
      return Stream.value(null);
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription(String userId) async {
    try {
      final activeSubscription = await getActiveSubscription(userId);
      return activeSubscription != null;
    } catch (e) {
      print('Error checking active subscription: $e');
      return false;
    }
  }

  /// Update subscription status
  Future<void> updateSubscriptionStatus(
      String subscriptionId, SubscriptionStatus status) async {
    try {
      await _subscriptionsCollection.doc(subscriptionId).update({
        'status': status.value,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      print('Subscription status updated: $subscriptionId -> ${status.value}');
    } catch (e) {
      print('Error updating subscription status: $e');
      throw Exception('Failed to update subscription status: $e');
    }
  }

  /// Cancel subscription
  Future<void> cancelSubscription(String subscriptionId) async {
    try {
      await updateSubscriptionStatus(
          subscriptionId, SubscriptionStatus.cancelled);
    } catch (e) {
      print('Error cancelling subscription: $e');
      throw Exception('Failed to cancel subscription: $e');
    }
  }

  /// Update auto-renew setting
  Future<void> updateAutoRenew(String subscriptionId, bool autoRenew) async {
    try {
      await _subscriptionsCollection.doc(subscriptionId).update({
        'autoRenew': autoRenew,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      print('Auto-renew updated: $subscriptionId -> $autoRenew');
    } catch (e) {
      print('Error updating auto-renew: $e');
      throw Exception('Failed to update auto-renew: $e');
    }
  }

  /// Delete subscription
  Future<void> deleteSubscription(String subscriptionId) async {
    try {
      await _subscriptionsCollection.doc(subscriptionId).delete();
      print('Subscription deleted: $subscriptionId');
    } catch (e) {
      print('Error deleting subscription: $e');
      throw Exception('Failed to delete subscription: $e');
    }
  }

  /// Get plan by ID
  Future<SubscriptionPlanModel?> getPlanById(String planId) async {
    try {
      final doc = await _plansCollection.doc(planId).get();
      if (!doc.exists) return null;

      return SubscriptionPlanModel.fromSnapshot(
        doc as DocumentSnapshot<Map<String, dynamic>>,
      );
    } catch (e) {
      print('Error getting plan: $e');
      return null;
    }
  }

  /// Build UserSubscriptionModel from document (fetch related data)
  Future<UserSubscriptionModel?> _buildSubscriptionFromDoc(
      DocumentSnapshot doc) async {
    try {
      if (!doc.exists) {
        print('Document does not exist: ${doc.id}');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>?;
      if (data == null) {
        print('Document data is null: ${doc.id}');
        return null;
      }

      // 1. Get plan ID and fetch plan
      final planId = data[FirebaseFieldNames.subscriptionPlanId];
      if (planId == null) {
        print('Plan ID is null for subscription: ${doc.id}');
        return null;
      }

      final plan = await getPlanById(planId);
      if (plan == null) {
        print('Plan not found: $planId');
        return null;
      }

      // 2. Create base subscription model
      final subscription = UserSubscriptionModel.fromSnapshot(
        doc as DocumentSnapshot<Map<String, dynamic>>,
      );

      // 3. Get all payment transactions for this subscription
      final transactions = await _paymentRepo.getPaymentsBySubscriptionId(
        subscription.subscriptionId,
      );

      // 4. If no transactions exist and subscription is pending/failed, create temporary transaction
      List<PaymentTransactionModel> finalTransactions = transactions;

      if (transactions.isEmpty &&
          (subscription.status == SubscriptionStatus.pending ||
              subscription.status == SubscriptionStatus.failed)) {
        finalTransactions = [
          PaymentTransactionModel(
            transactionId: 'pending',
            amount: plan.price,
            currency: 'MYR',
            paymentMethod: 'stripe',
            transactionDateTime: subscription.startDateTime,
            status: subscription.status == SubscriptionStatus.failed
                ? PaymentStatus.failed
                : PaymentStatus.pending,
          )
        ];
      }

      // 5. Return complete subscription with all related data
      return subscription.copyWith(
        subscriptionPlan: plan,
        paymentTransactions: finalTransactions,
      );
    } catch (e) {
      print('Error in _buildSubscriptionFromDoc: $e');
      print('Stack trace: ${StackTrace.current}');
      return null;
    }
  }

  /// Expire subscriptions (called by cloud function)
  Future<void> expireSubscriptions() async {
    try {
      final now = Timestamp.now();
      final querySnapshot = await _subscriptionsCollection
          .where('status', isEqualTo: SubscriptionStatus.active.value)
          .where('endDateTime', isLessThan: now)
          .get();

      final batch = _db.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'status': SubscriptionStatus.expired.value,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        });
      }

      await batch.commit();
      print('Expired ${querySnapshot.docs.length} subscriptions');
    } catch (e) {
      print('Error expiring subscriptions: $e');
    }
  }

  /// Get subscription statistics
  Future<Map<String, dynamic>> getSubscriptionStats(String userId) async {
    try {
      final subscriptions = await getSubscriptionHistory(userId);

      final totalSubscriptions = subscriptions.length;
      final activeCount = subscriptions
          .where((s) => s.status == SubscriptionStatus.active)
          .length;
      final expiredCount = subscriptions
          .where((s) => s.status == SubscriptionStatus.expired)
          .length;
      final failedCount = subscriptions
          .where((s) => s.status == SubscriptionStatus.failed)
          .length;
      final cancelledCount = subscriptions
          .where((s) => s.status == SubscriptionStatus.cancelled)
          .length;

      final totalSpent = subscriptions.fold(0.0, (sum, s) => sum + s.totalAmountPaid);

      return {
        'totalSubscriptions': totalSubscriptions,
        'activeSubscriptions': activeCount,
        'expiredSubscriptions': expiredCount,
        'failedSubscriptions': failedCount,
        'cancelledSubscriptions': cancelledCount,
        'totalSpent': totalSpent,
      };
    } catch (e) {
      print('Error getting subscription stats: $e');
      return {
        'totalSubscriptions': 0,
        'activeSubscriptions': 0,
        'expiredSubscriptions': 0,
        'failedSubscriptions': 0,
        'cancelledSubscriptions': 0,
        'totalSpent': 0.0,
      };
    }
  }
}