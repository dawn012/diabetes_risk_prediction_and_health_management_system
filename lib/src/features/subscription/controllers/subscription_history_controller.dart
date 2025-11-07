import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/subscription/subscription_repository.dart';
import '../../../utils/constants/enums.dart';
import '../models/user_subscription_model.dart';

class SubscriptionHistoryController extends GetxController {
  final subscriptionRepo = Get.put(SubscriptionRepository());

  // Observables - 只关注历史记录
  final RxList<UserSubscriptionModel> allSubscriptions = <UserSubscriptionModel>[].obs;
  final RxList<UserSubscriptionModel> subscriptionHistory = <UserSubscriptionModel>[].obs;
  final RxList<UserSubscriptionModel> filteredSubscriptions = <UserSubscriptionModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedStatus = 'all'.obs;
  final RxString selectedSortOption = 'newest'.obs;

  // Search controller
  final searchController = TextEditingController();

  // Stream subscription
  StreamSubscription? _subscriptionStream;

  // Filter options
  final List<String> statusFilters = [
    'all',
    'pending',
    'expired',
    'failed',
    'cancelled',
  ];

  final List<String> sortOptions = [
    'newest',
    'oldest',
    'amount_high',
    'amount_low',
  ];

  @override
  void onInit() {
    super.onInit();
    _startListening();
  }

  @override
  void onClose() {
    _subscriptionStream?.cancel();
    searchController.dispose();
    super.onClose();
  }

  /// Start listening to subscription updates
  void _startListening() {
    isLoading.value = true;

    _subscriptionStream = subscriptionRepo
        .streamUserSubscriptions()
        .listen((subscriptions) {
      if (subscriptions.isEmpty) {
        subscriptionHistory.clear();
        allSubscriptions.clear();
        filteredSubscriptions.clear();
        isLoading.value = false;
        return;
      }

      // Store all subscriptions
      allSubscriptions.value = subscriptions;

      // Get history (non-active subscriptions)
      subscriptionHistory.value = subscriptions
          .where((s) => s.status != SubscriptionStatus.active)
          .toList();

      // Apply filters
      applyFilters();

      isLoading.value = false;
    }, onError: (error) {
      print('Error streaming subscriptions: $error');
      isLoading.value = false;
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load subscription history',
      );
    });
  }

  /// Apply all filters (search, status, sort)
  void applyFilters() {
    List<UserSubscriptionModel> filtered = List.from(subscriptionHistory);

    // Apply search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered.where((subscription) {
        final planName = subscription.subscriptionPlan.planName.toLowerCase();
        final query = searchQuery.value.toLowerCase();
        return planName.contains(query);
      }).toList();
    }

    // Apply status filter
    if (selectedStatus.value != 'all') {
      final targetStatus = SubscriptionStatus.fromString(selectedStatus.value);
      filtered = filtered
          .where((subscription) => subscription.status == targetStatus)
          .toList();
    }

    // Apply sorting
    filtered = _applySorting(filtered);

    filteredSubscriptions.value = filtered;
  }

  /// Apply sorting to subscriptions
  List<UserSubscriptionModel> _applySorting(
      List<UserSubscriptionModel> subscriptions) {
    switch (selectedSortOption.value) {
      case 'newest':
        subscriptions
            .sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
        break;
      case 'oldest':
        subscriptions
            .sort((a, b) => a.startDateTime.compareTo(b.startDateTime));
        break;
      case 'amount_high':
        subscriptions.sort((a, b) => b.totalAmountPaid
            .compareTo(a.totalAmountPaid));
        break;
      case 'amount_low':
        subscriptions.sort((a, b) => a.totalAmountPaid
            .compareTo(b.totalAmountPaid));
        break;
      default:
        subscriptions
            .sort((a, b) => b.startDateTime.compareTo(a.startDateTime));
    }
    return subscriptions;
  }

  /// Get status label for display
  String getStatusLabel(String status) {
    if (status == 'all') return 'All';
    return SubscriptionStatus.fromString(status).displayName;
  }

  /// Get sort option label
  String getSortOptionLabel(String sortOption) {
    switch (sortOption) {
      case 'newest':
        return 'Newest First';
      case 'oldest':
        return 'Oldest First';
      case 'amount_high':
        return 'Amount: High to Low';
      case 'amount_low':
        return 'Amount: Low to High';
      default:
        return 'Newest First';
    }
  }

  /// Handle search input
  void onSearchChanged(String value) {
    searchQuery.value = value;
    applyFilters();
  }

  /// Clear search
  void clearSearch() {
    searchController.clear();
    searchQuery.value = '';
    applyFilters();
  }

  /// Handle status filter change
  void onStatusFilterChanged(String status) {
    selectedStatus.value = status;
    applyFilters();
  }

  /// Handle sort option change
  void onSortOptionChanged(String sortOption) {
    selectedSortOption.value = sortOption;
    applyFilters();
  }

  /// Refresh data
  Future<void> refreshData() async {
    // Stream will automatically refresh, just show loading briefly
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 500));
    isLoading.value = false;
  }
}