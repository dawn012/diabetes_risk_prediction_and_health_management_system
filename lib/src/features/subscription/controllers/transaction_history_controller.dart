// transaction_history_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/subscription/payment_repository.dart';
import '../../../data/repositories/subscription/subscription_repository.dart';
import '../models/payment_transaction_model.dart';
import '../models/user_subscription_model.dart';

class TransactionHistoryController extends GetxController {
  final paymentRepo = Get.put(PaymentRepository());
  final subscriptionRepo = Get.put(SubscriptionRepository());

  // 存储 subscription 对象（key 是 transactionId）
  final RxMap<String, UserSubscriptionModel> transactionSubscriptions =
      <String, UserSubscriptionModel>{}.obs;

  // Observables
  final RxList<PaymentTransactionModel> allTransactions = <PaymentTransactionModel>[].obs;
  final RxList<PaymentTransactionModel> filteredTransactions = <PaymentTransactionModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedSortOption = 'newest'.obs;

  final searchController = TextEditingController();
  StreamSubscription? _transactionStream;

  final List<String> statusFilters = ['all', 'succeeded', 'pending', 'failed'];
  final List<String> sortOptions = ['newest', 'oldest', 'amount_high', 'amount_low'];

  @override
  void onInit() {
    super.onInit();
    _startListening();
  }

  @override
  void onClose() {
    _transactionStream?.cancel();
    searchController.dispose();
    super.onClose();
  }

  void _startListening() {
    isLoading.value = true;

    // 使用 streamUserSubscriptions 获取所有订阅
    _transactionStream = subscriptionRepo.streamUserSubscriptions().listen((subscriptions) {
      allTransactions.clear();
      transactionSubscriptions.clear();

      // 遍历所有订阅
      for (var subscription in subscriptions) {
        // 遍历每个订阅的所有支付交易
        for (var transaction in subscription.paymentTransactions) {
          allTransactions.add(transaction);
          // 以 transactionId 为 key 存储完整的 subscription
          transactionSubscriptions[transaction.transactionId] = subscription;
        }
      }

      applyFilters();
      isLoading.value = false;
    }, onError: (error) {
      print('Error streaming transactions: $error');
      isLoading.value = false;
    });
  }

  void applyFilters() {
    List<PaymentTransactionModel> filtered = List.from(allTransactions);

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      final query = searchQuery.value.toLowerCase();
      filtered = filtered.where((transaction) {
        final subscription = transactionSubscriptions[transaction.transactionId];
        final planName = subscription?.subscriptionPlan.planName ?? '';

        return transaction.transactionId.toLowerCase().contains(query) ||
            transaction.paymentMethod.toLowerCase().contains(query) ||
            planName.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filter
    if (selectedStatus.value != 'all') {
      filtered = filtered.where((transaction) =>
      transaction.status.value == selectedStatus.value
      ).toList();
    }

    // Apply sorting
    filtered = _applySorting(filtered);

    filteredTransactions.value = filtered;
  }

  List<PaymentTransactionModel> _applySorting(List<PaymentTransactionModel> transactions) {
    switch (selectedSortOption.value) {
      case 'newest':
        transactions.sort((a, b) => b.transactionDateTime.compareTo(a.transactionDateTime));
        break;
      case 'oldest':
        transactions.sort((a, b) => a.transactionDateTime.compareTo(b.transactionDateTime));
        break;
      case 'amount_high':
        transactions.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case 'amount_low':
        transactions.sort((a, b) => a.amount.compareTo(b.amount));
        break;
      default:
        transactions.sort((a, b) => b.transactionDateTime.compareTo(a.transactionDateTime));
    }
    return transactions;
  }

  // 根据 transactionId 获取对应的 subscription
  UserSubscriptionModel? getSubscription(String transactionId) {
    return transactionSubscriptions[transactionId];
  }

  // 获取 plan name（仍然保留这个方法用于列表显示）
  String getPlanName(String transactionId) {
    return transactionSubscriptions[transactionId]?.subscriptionPlan.planName ??
        'Subscription Plan';
  }

  int getStatusCount(String status) {
    if (status == 'all') return allTransactions.length;
    return allTransactions.where((t) => t.status.value == status).length;
  }

  String getStatusLabel(String status) {
    switch (status) {
      case 'all': return 'All';
      case 'succeeded': return 'Succeeded';
      case 'pending': return 'Pending';
      case 'failed': return 'Failed';
      default: return status;
    }
  }

  String getSortOptionLabel(String sortOption) {
    switch (sortOption) {
      case 'newest': return 'Newest First';
      case 'oldest': return 'Oldest First';
      case 'amount_high': return 'Amount: High to Low';
      case 'amount_low': return 'Amount: Low to High';
      default: return 'Newest First';
    }
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    applyFilters();
  }

  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    applyFilters();
  }

  void onStatusFilterChanged(String status) {
    selectedStatus.value = status;
    applyFilters();
  }

  void onSortOptionChanged(String sortOption) {
    selectedSortOption.value = sortOption;
    applyFilters();
  }

  Future<void> refreshData() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    isLoading.value = false;
  }
}