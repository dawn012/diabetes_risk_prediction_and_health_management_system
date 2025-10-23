import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import '../../../features/subscription/models/payment_transaction_model.dart';
import '../../../utils/constants/firebase_collection_names.dart';

class PaymentRepository extends GetxController {
  static PaymentRepository get instance => Get.find();

  /// Firestore instance
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Collection reference
  late final CollectionReference _paymentsCollection;

  @override
  void onInit() {
    super.onInit();
    _paymentsCollection = _db.collection(FirebaseCollectionNames.payments);
  }

  /// Get transactions by date range
  Future<List<PaymentTransactionModel>> getTransactionsByDateRange(
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      print('Fetching transactions from ${startDate.toIso8601String()} to ${endDate.toIso8601String()}');

      final QuerySnapshot querySnapshot = await _paymentsCollection
          .where('transactionDateTime', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('transactionDateTime', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
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
  Future<List<PaymentTransactionModel>> getTransactionsByStatus(String status) async {
    try {
      final QuerySnapshot querySnapshot = await _paymentsCollection
          .where('status', isEqualTo: status)
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
  Future<List<PaymentTransactionModel>> getTransactionsByUserId(String userId) async {
    try {
      final QuerySnapshot querySnapshot = await _paymentsCollection
          .where('userId', isEqualTo: userId) // Assuming you have userId field
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

  /// Get transaction statistics for a date range
  Future<Map<String, dynamic>> getTransactionStats(
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final transactions = await getTransactionsByDateRange(startDate, endDate);
      final successfulTransactions = transactions.where((t) => t.status.toLowerCase() == 'success').toList();

      final totalTransactions = transactions.length;
      final successfulCount = successfulTransactions.length;
      final totalRevenue = successfulTransactions.fold(0.0, (sum, t) => sum + t.amount);
      final averageTransactionValue = successfulCount > 0 ? totalRevenue / successfulCount : 0.0;

      return {
        'totalTransactions': totalTransactions,
        'successfulTransactions': successfulCount,
        'failedTransactions': totalTransactions - successfulCount,
        'totalRevenue': totalRevenue,
        'averageTransactionValue': averageTransactionValue,
        'successRate': totalTransactions > 0 ? (successfulCount / totalTransactions * 100) : 0.0,
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
      final successfulTransactions = transactions.where((t) => t.status.toLowerCase() == 'success').toList();

      Map<int, double> monthlyRevenue = {};

      for (var transaction in successfulTransactions) {
        final month = transaction.transactionDateTime.month;
        monthlyRevenue[month] = (monthlyRevenue[month] ?? 0.0) + transaction.amount;
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
  Future<void> updateTransactionStatus(String transactionId, String newStatus) async {
    try {
      final QuerySnapshot querySnapshot = await _paymentsCollection
          .where('transactionId', isEqualTo: transactionId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        await querySnapshot.docs.first.reference.update({'status': newStatus});
      }
    } catch (e) {
      print('Error updating transaction status: $e');
      throw Exception('Failed to update transaction status: $e');
    }
  }
}