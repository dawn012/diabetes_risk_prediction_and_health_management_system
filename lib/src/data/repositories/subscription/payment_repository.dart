import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../features/subscription/models/payment_transaction_model.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_collection_names.dart';

/// Paginated transaction response model
class PaginatedTransactionsResponse {
  final List<PaymentTransactionModel> transactions;
  final int totalCount;

  PaginatedTransactionsResponse({
    required this.transactions,
    required this.totalCount,
  });
}

class PaymentRepository extends GetxController {
  static PaymentRepository get instance => Get.find();

  /// Firestore instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Get Firebase Auth user
  User? get authUser => FirebaseAuth.instance.currentUser;

  /// Collection reference
  late final CollectionReference _paymentsCollection;
  late final CollectionReference _subscriptionsCollection;
  late final CollectionReference _plansCollection;

  @override
  void onInit() {
    super.onInit();
    _paymentsCollection = _db.collection(FirebaseCollectionNames.payments);
    _subscriptionsCollection = _db.collection(FirebaseCollectionNames.userSubscriptions);
    _plansCollection = _db.collection(FirebaseCollectionNames.subscriptionPlans);
  }

  /// Fetch paginated transactions with filters
  Future<PaginatedTransactionsResponse> fetchPaginatedTransactions({
    required int page,
    required int itemsPerPage,
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
  }) async {
    try {
      print('Fetching transactions - Page: $page, Items: $itemsPerPage');

      // Build base query
      Query query = _paymentsCollection;

      // Apply date range filter if provided
      if (startDate != null && endDate != null) {
        final startMillis = startDate.millisecondsSinceEpoch;
        final endMillis = endDate.millisecondsSinceEpoch;

        query = query
            .where('transactionDateTime', isGreaterThanOrEqualTo: startMillis)
            .where('transactionDateTime', isLessThanOrEqualTo: endMillis);
      }

      // Apply status filter if provided
      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      // Order by transaction date (descending - newest first)
      query = query.orderBy('transactionDateTime', descending: true);

      // Get total count first
      final countSnapshot = await query.get();
      int totalCount = countSnapshot.docs.length;

      // Apply search filter if provided (client-side)
      List<DocumentSnapshot> allDocs = countSnapshot.docs;

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final lowerQuery = searchQuery.toLowerCase();
        allDocs = allDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final transactionId = (data['transactionId'] ?? '').toString().toLowerCase();
          final amount = (data['amount'] ?? 0).toString();
          final method = (data['paymentMethod'] ?? '').toString().toLowerCase();
          final statusValue = (data['status'] ?? '').toString().toLowerCase();

          return transactionId.contains(lowerQuery) ||
              amount.contains(lowerQuery) ||
              method.contains(lowerQuery) ||
              statusValue.contains(lowerQuery);
        }).toList();

        totalCount = allDocs.length;
      }

      // Apply pagination
      final startIndex = (page - 1) * itemsPerPage;
      final endIndex = (startIndex + itemsPerPage).clamp(0, allDocs.length);

      final paginatedDocs = allDocs.sublist(
        startIndex.clamp(0, allDocs.length),
        endIndex,
      );

      // Convert to models
      final transactions = paginatedDocs
          .map((doc) => PaymentTransactionModel.fromSnapshot(
          doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      print('Fetched ${transactions.length} transactions out of $totalCount total');

      return PaginatedTransactionsResponse(
        transactions: transactions,
        totalCount: totalCount,
      );
    } catch (e) {
      print('Error fetching paginated transactions: $e');
      return PaginatedTransactionsResponse(
        transactions: [],
        totalCount: 0,
      );
    }
  }

  /// Get transaction count by filters
  Future<int> getTransactionCount({
    PaymentStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      Query query = _paymentsCollection;

      if (startDate != null && endDate != null) {
        final startMillis = startDate.millisecondsSinceEpoch;
        final endMillis = endDate.millisecondsSinceEpoch;

        query = query
            .where('transactionDateTime', isGreaterThanOrEqualTo: startMillis)
            .where('transactionDateTime', isLessThanOrEqualTo: endMillis);
      }

      if (status != null) {
        query = query.where('status', isEqualTo: status.value);
      }

      final snapshot = await query.get();
      return snapshot.docs.length;
    } catch (e) {
      print('Error getting transaction count: $e');
      return 0;
    }
  }

  /// Create a new payment transaction with subscription ID
  Future<void> createPaymentTransaction({
    required PaymentTransactionModel transaction,
    required String subscriptionId,
  }) async {
    try {
      // 创建包含额外字段的数据
      final paymentData = {
        ...transaction.toJson(), // 基础交易数据
        'subscriptionId': subscriptionId, // 额外添加的字段
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      await _paymentsCollection.doc(transaction.transactionId).set(paymentData);
      print(
          'Payment transaction created: ${transaction.transactionId} for subscription: $subscriptionId');
    } catch (e) {
      print('Error creating payment transaction: $e');
      throw Exception('Failed to create payment transaction: $e');
    }
  }

  /// Get payment transaction by ID
  Future<PaymentTransactionModel?> getPaymentTransaction(
      String transactionId) async {
    try {
      final doc = await _paymentsCollection.doc(transactionId).get();
      if (!doc.exists) return null;

      final data = doc.data() as Map<String, dynamic>;
      return PaymentTransactionModel.fromMap(data);
    } catch (e) {
      print('Error getting payment transaction: $e');
      return null;
    }
  }

  /// Get all payments by subscription ID
  Future<List<PaymentTransactionModel>> getPaymentsBySubscriptionId(
      String subscriptionId) async {
    try {
      final querySnapshot = await _paymentsCollection
          .where('subscriptionId', isEqualTo: subscriptionId)
          .orderBy('transactionDateTime', descending: true)
          .get();

      if (querySnapshot.docs.isEmpty) return [];

      return querySnapshot.docs
          .map((doc) => PaymentTransactionModel.fromMap(
          doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting payments by subscription ID: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> streamUserPaymentTransactions() {
    final userId = authUser?.uid;
    if (userId == null) {
      print('No authenticated user');
      return Stream.value([]);
    }

    try {
      return _subscriptionsCollection
          .where('userId', isEqualTo: userId)
          .snapshots()
          .asyncMap((subscriptionSnapshot) async {
        if (subscriptionSnapshot.docs.isEmpty) return [];

        List<Map<String, dynamic>> results = [];

        for (var subDoc in subscriptionSnapshot.docs) {
          try {
            final subData = subDoc.data() as Map<String, dynamic>;
            final subscriptionId = subData['subscriptionId'] ?? subDoc.id;

            // Get payment transaction
            final paymentDoc = await _paymentsCollection
                .where('subscriptionId', isEqualTo: subscriptionId)
                .limit(1)
                .get();

            if (paymentDoc.docs.isEmpty) continue;

            final paymentData = paymentDoc.docs.first.data() as Map<String, dynamic>;
            final transaction = PaymentTransactionModel.fromMap(paymentData);

            // Get plan details
            final planId = subData['subscriptionPlanId'];
            final planDoc = await _plansCollection.doc(planId).get();

            String planName = 'Subscription Plan';
            if (planDoc.exists) {
              final planData = planDoc.data() as Map<String, dynamic>;
              planName = planData['planName'] ?? 'Subscription Plan';
            }

            results.add({
              'transaction': transaction,
              'subscriptionId': subscriptionId,
              'planName': planName,
            });
          } catch (e) {
            print('Error processing subscription: $e');
            continue;
          }
        }

        return results;
      });
    } catch (e) {
      print('Error streaming user payment transactions: $e');
      return Stream.value([]);
    }
  }

  /// Get payment by subscription ID
  Future<PaymentTransactionModel?> getPaymentBySubscriptionId(
      String subscriptionId) async {
    try {
      final querySnapshot = await _paymentsCollection
          .where('subscriptionId', isEqualTo: subscriptionId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final data = querySnapshot.docs.first.data() as Map<String, dynamic>;
      return PaymentTransactionModel.fromMap(data);
    } catch (e) {
      print('Error getting payment by subscription ID: $e');
      return null;
    }
  }

  /// Get transactions by date range
  Future<List<PaymentTransactionModel>> getTransactionsByDateRange(
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      print('Fetching transactions from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      // 将 DateTime 转换为毫秒时间戳
      final startMillis = startDate.millisecondsSinceEpoch;
      final endMillis = endDate.millisecondsSinceEpoch;

      final QuerySnapshot querySnapshot = await _paymentsCollection
          .where('transactionDateTime', isGreaterThanOrEqualTo: startMillis)
          .where('transactionDateTime', isLessThanOrEqualTo: endMillis)
          .orderBy('transactionDateTime', descending: true)
          .get();

      final List<PaymentTransactionModel> transactions = querySnapshot.docs
          .map((doc) => PaymentTransactionModel.fromSnapshot(
          doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();

      print('Found ${transactions.length} transactions');
      return transactions;
    } catch (e) {
      print('Error fetching transactions by date range: $e');
      return [];
    }
  }

  /// Get all transactions
  Future<List<PaymentTransactionModel>> getAllTransactions() async {
    try {
      final QuerySnapshot querySnapshot = await _paymentsCollection
          .orderBy('transactionDateTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PaymentTransactionModel.fromSnapshot(
          doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error fetching all transactions: $e');
      return [];
    }
  }

  /// Get transactions by status
  Future<List<PaymentTransactionModel>> getTransactionsByStatus(
      PaymentStatus status) async {
    try {
      final QuerySnapshot querySnapshot = await _paymentsCollection
          .where('status', isEqualTo: status.value)
          .orderBy('transactionDateTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PaymentTransactionModel.fromSnapshot(
          doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error fetching transactions by status: $e');
      return [];
    }
  }

  /// Get transactions for a specific user
  Future<List<PaymentTransactionModel>> getTransactionsByUserId(
      String userId) async {
    try {
      final QuerySnapshot querySnapshot = await _paymentsCollection
          .where('userId', isEqualTo: userId)
          .orderBy('transactionDateTime', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PaymentTransactionModel.fromSnapshot(
          doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      print('Error fetching transactions by user ID: $e');
      return [];
    }
  }

  /// Get subscription ID by transaction ID
  Future<String?> getSubscriptionIdByTransactionId(String transactionId) async {
    try {
      final doc = await _paymentsCollection.doc(transactionId).get();

      if (!doc.exists) {
        print('Payment transaction not found: $transactionId');
        return null;
      }

      final data = doc.data() as Map<String, dynamic>?;

      if (data == null) {
        print('Payment transaction data is null: $transactionId');
        return null;
      }

      final subscriptionId = data['subscriptionId'] as String?;

      if (subscriptionId == null) {
        print('Subscription ID not found in payment transaction: $transactionId');
        return null;
      }

      return subscriptionId;

    } catch (e) {
      print('Error getting subscription ID by transaction ID: $e');
      return null;
    }
  }

  /// Get transaction statistics for a date range
  Future<Map<String, dynamic>> getTransactionStats(
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final transactions = await getTransactionsByDateRange(startDate, endDate);
      final successfulTransactions = transactions
          .where((t) => t.status == PaymentStatus.succeeded)
          .toList();

      final totalTransactions = transactions.length;
      final successfulCount = successfulTransactions.length;
      final totalRevenue =
      successfulTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final averageTransactionValue =
      successfulCount > 0 ? totalRevenue / successfulCount : 0.0;

      return {
        'totalTransactions': totalTransactions,
        'successfulTransactions': successfulCount,
        'failedTransactions': totalTransactions - successfulCount,
        'totalRevenue': totalRevenue,
        'averageTransactionValue': averageTransactionValue,
        'successRate': totalTransactions > 0
            ? (successfulCount / totalTransactions * 100)
            : 0.0,
      };
    } catch (e) {
      print('Error getting transaction stats: $e');
      return {
        'totalTransactions': 0,
        'successfulTransactions': 0,
        'failedTransactions': 0,
        'totalRevenue': 0.0,
        'averageTransactionValue': 0.0,
        'successRate': 0.0,
      };
    }
  }

  /// Get monthly revenue for a specific year
  Future<Map<int, double>> getMonthlyRevenue(int year) async {
    try {
      final startDate = DateTime(year, 1, 1);
      final endDate = DateTime(year, 12, 31, 23, 59, 59);

      final transactions = await getTransactionsByDateRange(startDate, endDate);
      final successfulTransactions = transactions
          .where((t) => t.status == PaymentStatus.succeeded)
          .toList();

      Map<int, double> monthlyRevenue = {};

      for (var transaction in successfulTransactions) {
        final month = transaction.transactionDateTime.month;
        monthlyRevenue[month] =
            (monthlyRevenue[month] ?? 0.0) + transaction.amount;
      }

      return monthlyRevenue;
    } catch (e) {
      print('Error getting monthly revenue: $e');
      return {};
    }
  }

  /// Create a new transaction (for testing purposes)
  Future<void> createTransaction(PaymentTransactionModel transaction) async {
    try {
      await _paymentsCollection.add(transaction.toJson());
    } catch (e) {
      print('Error creating transaction: $e');
      throw Exception('Failed to create transaction: $e');
    }
  }

  /// Update transaction status
  Future<void> updateTransactionStatus(
      String transactionId, PaymentStatus newStatus) async {
    try {
      final QuerySnapshot querySnapshot = await _paymentsCollection
          .where('transactionId', isEqualTo: transactionId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({
          'status': newStatus.value,
        });
      }
    } catch (e) {
      print('Error updating transaction status: $e');
      throw Exception('Failed to update transaction status: $e');
    }
  }
}