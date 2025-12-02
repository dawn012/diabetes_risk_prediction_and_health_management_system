import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../utils/constants/admin_colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/subscription/payment_repository.dart';
import '../../../data/repositories/subscription/subscription_repository.dart';
import '../../subscription/models/payment_transaction_model.dart';
import '../../subscription/models/subscription_plan_model.dart';

/// Cache entry model
class CachedTransactionPage {
  final List<PaymentTransactionModel> transactions;
  final DateTime cachedAt;
  final int totalCount;

  CachedTransactionPage({
    required this.transactions,
    required this.cachedAt,
    required this.totalCount,
  });
}

class TransactionManagementController extends GetxController {
  static TransactionManagementController get instance => Get.find();

  // Observable variables
  final RxList<PaymentTransactionModel> displayedTransactions =
      <PaymentTransactionModel>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<PaymentStatus?> selectedStatus = Rx<PaymentStatus?>(null);
  final Rx<String?> selectedPlanId = Rx<String?>(null);
  // 专门给不需要勾选的表用的空列表
  final RxList<PaymentTransactionModel> emptySelection =
      <PaymentTransactionModel>[].obs;

  // Date range filter
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);
  final RxString selectedPeriod =
      'all'.obs; // 'all', '7days', '30days', '90days', 'custom'

  // Search and sorting
  final TextEditingController searchController = TextEditingController();
  final RxInt sortColumnIndex = 2
      .obs; // 默认用日期列（index 2），你也可以改成 0 等和 UI 对齐
  final RxBool sortAscending = false.obs; // Default: newest first
  Timer? _searchDebounce;

  // Pagination
  final RxInt currentPage = 1.obs;
  final RxInt itemsPerPage = 10.obs;
  final RxInt totalCount = 0.obs;
  final RxInt totalPages = 1.obs;
  final RxList<int> itemsPerPageOptions = [10, 25, 50, 100].obs;

  // Cache management (max 3 pages)
  final Map<String, CachedTransactionPage> _pageCache = {};
  static const int _maxCachedPages = 3;

  // Plan data for filter and display
  final RxList<SubscriptionPlanModel> availablePlans =
      <SubscriptionPlanModel>[].obs;
  final RxMap<String, SubscriptionPlanModel> planData =
      <String, SubscriptionPlanModel>{}.obs;

  // Statistics
  final RxDouble totalRevenue = 0.0.obs;
  final RxInt successfulTransactions = 0.obs;
  final RxInt failedTransactions = 0.obs;
  final RxDouble averageTransaction = 0.0.obs;

  // Current user role
  final RxString currentUserRole = ''.obs;

  // Repositories
  final paymentRepo = Get.put(PaymentRepository());
  final subscriptionRepo = Get.put(SubscriptionRepository());
  final _authRepo = AuthenticationRepository.instance;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    _initData();
  }

  Future<void> _initData() async {
    await _loadCurrentUserRole();
    if (!canViewTransactions) return;

    await _loadAvailablePlans();
    await _loadFirstPage();
    await _calculateStatistics();
  }

  @override
  void onClose() {
    searchController.dispose();
    _searchDebounce?.cancel();
    _pageCache.clear();
    super.onClose();
  }

  /// Load current user role
  Future<void> _loadCurrentUserRole() async {
    try {
      final role = await _authRepo.getUserRole();
      currentUserRole.value = role;
    } catch (e) {
      print("Error loading user role: $e");
      currentUserRole.value = "user";
    }
  }

  /// Check if user has permission to view transactions
  bool get canViewTransactions {
    final role = currentUserRole.value.toLowerCase();
    return role == 'admin';
  }

  /// Load available subscription plans for filtering
  Future<void> _loadAvailablePlans() async {
    try {
      final plans = await subscriptionRepo.getAllPlans();
      availablePlans.assignAll(plans);

      // Build plan lookup map
      for (var plan in plans) {
        planData[plan.subscriptionPlanId] = plan;
      }
    } catch (e) {
      print('Error loading plans: $e');
    }
  }

  /// Generate cache key
  String _getCacheKey(int page) {
    return '${selectedStatus.value?.name ?? "all"}_'
        '${selectedPlanId.value ?? "all"}_'
        '${selectedPeriod.value}_'
        '${searchController.text}_'
        '$page';
  }

  /// Load first page
  Future<void> _loadFirstPage() async {
    currentPage.value = 1;
    await _loadPage(1, preloadNext: true);
  }

  /// Load specific page
  Future<void> _loadPage(int page, {bool preloadNext = false}) async {
    if (!canViewTransactions) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to view transactions.',
      );
      return;
    }

    try {
      final cacheKey = _getCacheKey(page);

      // 1) 先看 cache（和 Community 类似）
      if (_pageCache.containsKey(cacheKey)) {
        print('📦 Loading page $page from cache');
        final cached = _pageCache[cacheKey]!;
        displayedTransactions.assignAll(cached.transactions);
        totalCount.value = cached.totalCount;
        _calculateTotalPages();
        await _loadPlanDataForTransactions(cached.transactions);

        if (preloadNext && page < totalPages.value) {
          _preloadPage(page + 1);
        }
        return;
      }

      isLoading.value = true;

      // Prepare filters for repository
      DateTime? filterStartDate;
      DateTime? filterEndDate;

      if (startDate.value != null && endDate.value != null) {
        filterStartDate = startDate.value;
        filterEndDate = endDate.value;
      } else if (selectedPeriod.value == '7days') {
        filterEndDate = DateTime.now();
        filterStartDate = filterEndDate.subtract(const Duration(days: 7));
      } else if (selectedPeriod.value == '30days') {
        filterEndDate = DateTime.now();
        filterStartDate = filterEndDate.subtract(const Duration(days: 30));
      } else if (selectedPeriod.value == '90days') {
        filterEndDate = DateTime.now();
        filterStartDate = filterEndDate.subtract(const Duration(days: 90));
      }

      // Fetch paginated data from repository
      final response = await paymentRepo.fetchPaginatedTransactions(
        page: page,
        itemsPerPage: itemsPerPage.value,
        status: selectedStatus.value,
        startDate: filterStartDate,
        endDate: filterEndDate,
        searchQuery: searchController.text.trim().isEmpty
            ? null
            : searchController.text.trim(),
      );

      _updateCache(cacheKey, response.transactions, response.totalCount);

      displayedTransactions.assignAll(response.transactions);
      totalCount.value = response.totalCount;
      _calculateTotalPages();

      // 如果已经有排序状态，保持当前页排序
      if (displayedTransactions.isNotEmpty) {
        _applySortingOnCurrentPage();
      }

      // Load plan data for displayed transactions
      await _loadPlanDataForTransactions(response.transactions);

      if (preloadNext && page < totalPages.value) {
        _preloadPage(page + 1);
      }
    } catch (e) {
      print('Error loading page $page: $e');
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load transactions: ${e.toString()}',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Preload page in background（只更新 cache，不动 UI）
  Future<void> _preloadPage(int page) async {
    if (!canViewTransactions) return;

    try {
      final cacheKey = _getCacheKey(page);
      if (_pageCache.containsKey(cacheKey)) return;

      DateTime? filterStartDate;
      DateTime? filterEndDate;

      if (startDate.value != null && endDate.value != null) {
        filterStartDate = startDate.value;
        filterEndDate = endDate.value;
      } else if (selectedPeriod.value == '7days') {
        filterEndDate = DateTime.now();
        filterStartDate = filterEndDate.subtract(const Duration(days: 7));
      } else if (selectedPeriod.value == '30days') {
        filterEndDate = DateTime.now();
        filterStartDate = filterEndDate.subtract(const Duration(days: 30));
      } else if (selectedPeriod.value == '90days') {
        filterEndDate = DateTime.now();
        filterStartDate = filterEndDate.subtract(const Duration(days: 90));
      }

      final response = await paymentRepo.fetchPaginatedTransactions(
        page: page,
        itemsPerPage: itemsPerPage.value,
        status: selectedStatus.value,
        startDate: filterStartDate,
        endDate: filterEndDate,
        searchQuery: searchController.text.trim().isEmpty
            ? null
            : searchController.text.trim(),
      );

      _updateCache(cacheKey, response.transactions, response.totalCount);
    } catch (e) {
      print('Error preloading page $page: $e');
    }
  }

  /// Update cache with LRU strategy
  void _updateCache(
      String key, List<PaymentTransactionModel> transactions, int total) {
    if (_pageCache.length >= _maxCachedPages) {
      final sortedEntries = _pageCache.entries.toList()
        ..sort((a, b) => a.value.cachedAt.compareTo(b.value.cachedAt));

      final toRemove = _pageCache.length - _maxCachedPages + 1;
      for (var i = 0; i < toRemove; i++) {
        _pageCache.remove(sortedEntries[i].key);
        print('🗑️ Removed old cache: ${sortedEntries[i].key}');
      }
    }

    _pageCache[key] = CachedTransactionPage(
      transactions: List<PaymentTransactionModel>.from(transactions),
      cachedAt: DateTime.now(),
      totalCount: total,
    );
    print('💾 Cached page: $key (${_pageCache.length}/$_maxCachedPages)');
  }

  /// Clear all cache
  void _clearCache() {
    _pageCache.clear();
    print('🧹 Cache cleared');
  }

  /// Calculate total pages
  void _calculateTotalPages() {
    if (itemsPerPage.value > 0) {
      totalPages.value = (totalCount.value / itemsPerPage.value).ceil();
      if (totalPages.value == 0) totalPages.value = 1;
    }
  }

  /// Load plan data for transactions
  Future<void> _loadPlanDataForTransactions(
      List<PaymentTransactionModel> transactions) async {
    try {
      for (var transaction in transactions) {
        final subscriptionId =
        await paymentRepo.getSubscriptionIdByTransactionId(
          transaction.transactionId,
        );

        if (subscriptionId != null) {
          final subscription =
          await subscriptionRepo.getSubscriptionById(subscriptionId);
          if (subscription != null &&
              !planData.containsKey(
                  subscription.subscriptionPlan.subscriptionPlanId)) {
            planData[subscription.subscriptionPlan.subscriptionPlanId] =
                subscription.subscriptionPlan;
          }
        }
      }
    } catch (e) {
      print('Error loading plan data: $e');
    }
  }

  /// Calculate statistics
  Future<void> _calculateStatistics() async {
    try {
      DateTime start, end;

      if (startDate.value != null && endDate.value != null) {
        start = startDate.value!;
        end = endDate.value!;
      } else if (selectedPeriod.value == '7days') {
        end = DateTime.now();
        start = end.subtract(const Duration(days: 7));
      } else if (selectedPeriod.value == '30days') {
        end = DateTime.now();
        start = end.subtract(const Duration(days: 30));
      } else if (selectedPeriod.value == '90days') {
        end = DateTime.now();
        start = end.subtract(const Duration(days: 90));
      } else {
        // All time - get first transaction date
        start = DateTime(2020, 1, 1);
        end = DateTime.now();
      }

      final stats = await paymentRepo.getTransactionStats(start, end);

      totalRevenue.value = stats['totalRevenue'] ?? 0.0;
      successfulTransactions.value = stats['successfulTransactions'] ?? 0;
      failedTransactions.value = stats['failedTransactions'] ?? 0;
      averageTransaction.value =
          stats['averageTransactionValue'] ?? 0.0;
    } catch (e) {
      print('Error calculating statistics: $e');
    }
  }

  /// Handle search input changes with debounce（和 Community 一样）
  void _onSearchChanged() {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      _clearCache();
      currentPage.value = 1;
      _loadPage(1, preloadNext: true);
    });
  }

  /// Change page
  void changePage(int page) {
    if (page >= 1 && page <= totalPages.value && page != currentPage.value) {
      currentPage.value = page;
      _loadPage(page, preloadNext: true);
    }
  }

  /// Change items per page
  void changeItemsPerPage(int? items) {
    if (items != null && items != itemsPerPage.value) {
      itemsPerPage.value = items;
      _clearCache();
      currentPage.value = 1;
      _loadPage(1, preloadNext: true);
    }
  }

  /// Change status filter
  void changeStatusFilter(PaymentStatus? status) {
    if (selectedStatus.value != status) {
      selectedStatus.value = status;
      _clearCache();
      currentPage.value = 1;
      _loadPage(1, preloadNext: true);
      _calculateStatistics();
    }
  }

  /// Change plan filter
  void changePlanFilter(String? planId) {
    if (selectedPlanId.value != planId) {
      selectedPlanId.value = planId;
      _clearCache();
      currentPage.value = 1;
      _loadPage(1, preloadNext: true);
    }
  }

  /// Change period filter
  void changePeriodFilter(String period) {
    if (selectedPeriod.value != period) {
      selectedPeriod.value = period;

      if (period == 'all') {
        startDate.value = null;
        endDate.value = null;
      } else if (period == '7days') {
        endDate.value = DateTime.now();
        startDate.value = endDate.value!.subtract(const Duration(days: 7));
      } else if (period == '30days') {
        endDate.value = DateTime.now();
        startDate.value = endDate.value!.subtract(const Duration(days: 30));
      } else if (period == '90days') {
        endDate.value = DateTime.now();
        startDate.value = endDate.value!.subtract(const Duration(days: 90));
      }

      _clearCache();
      currentPage.value = 1;
      _loadPage(1, preloadNext: true);
      _calculateStatistics();
    }
  }

  /// Set custom date range
  Future<void> setCustomDateRange(DateTime start, DateTime end) async {
    startDate.value = start;
    endDate.value = end;
    selectedPeriod.value = 'custom';

    _clearCache();
    currentPage.value = 1;
    await _loadPage(1, preloadNext: true);
    await _calculateStatistics();
  }

  /// Sort transactions —— 和 Community 一样：只排序当前页
  void sortTransactions(int columnIndex, bool ascending) {
    sortColumnIndex.value = columnIndex;
    sortAscending.value = ascending;
    _applySortingOnCurrentPage();
  }

  void _applySortingOnCurrentPage() {
    displayedTransactions.sort((a, b) {
      dynamic valueA, valueB;

      switch (sortColumnIndex.value) {
        case 0: // Transaction ID
          valueA = a.transactionId;
          valueB = b.transactionId;
          break;
        case 1: // Amount
          valueA = a.amount;
          valueB = b.amount;
          break;
        case 2: // Date
          valueA = a.transactionDateTime;
          valueB = b.transactionDateTime;
          break;
        case 3: // Status
          valueA = a.status.value;
          valueB = b.status.value;
          break;
        case 4: // Payment Method
          valueA = a.paymentMethod;
          valueB = b.paymentMethod;
          break;
        default:
          valueA = a.transactionDateTime;
          valueB = b.transactionDateTime;
      }

      int comparison = 0;
      if (valueA is String && valueB is String) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is num && valueB is num) {
        comparison = valueA.compareTo(valueB);
      } else if (valueA is DateTime && valueB is DateTime) {
        comparison = valueA.compareTo(valueB);
      }

      return sortAscending.value ? comparison : -comparison;
    });
  }

  /// Refresh transactions
  Future<void> refreshTransactions({bool showMessage = true}) async {
    _clearCache();
    currentPage.value = 1;

    await _loadPage(1, preloadNext: true);
    await _calculateStatistics();

    if (showMessage) {
      TLoaders.successSnackBar(
        title: 'Refreshed',
        message: 'Transaction data has been refreshed.',
      );
    }
  }

  /// Get highlighted text for search
  List<TextSpan> getHighlightedText(
      String text,
      String query, {
        Color? textColor,
      }) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: TextStyle(color: textColor))];
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();
    int start = 0;

    while (true) {
      final int index = lowerText.indexOf(lowerQuery, start);
      if (index == -1) {
        spans.add(TextSpan(
            text: text.substring(start),
            style: TextStyle(color: textColor)));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
            text: text.substring(start, index),
            style: TextStyle(color: textColor)));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          backgroundColor: TAdminColors.warning.withOpacity(0.3),
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return spans;
  }

  /// Get plan name for transaction
  Future<String> getPlanNameForTransaction(
      PaymentTransactionModel transaction) async {
    try {
      final subscriptionId =
      await paymentRepo.getSubscriptionIdByTransactionId(
        transaction.transactionId,
      );

      if (subscriptionId != null) {
        final subscription =
        await subscriptionRepo.getSubscriptionById(subscriptionId);
        return subscription?.subscriptionPlan.planName ?? 'Unknown Plan';
      }

      return 'Unknown Plan';
    } catch (e) {
      print('Error getting plan name: $e');
      return 'Unknown Plan';
    }
  }
}