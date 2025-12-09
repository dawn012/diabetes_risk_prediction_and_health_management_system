import 'package:get/get.dart';

import '../../../data/repositories/subscription/subscription_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../features/authentication/models/user_model.dart';

class DashboardStatsController extends GetxController {
  static DashboardStatsController get instance => Get.find();

  final UserRepository _userRepository = UserRepository.instance;
  final SubscriptionRepository _subscriptionRepository = Get.put(SubscriptionRepository());

  var isLoading = false.obs;
  var totalUsers = 0.obs;
  var activeUsersThisMonth = 0.obs;
  var newUsersThisMonth = 0.obs;
  var totalSubscriptionUsers = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardStats();
  }

  Future<void> loadDashboardStats() async {
    try {
      isLoading.value = true;

      // Get all regular users
      final allUsers = await _userRepository.getRegularUsers();

      // Calculate date ranges
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      // Total users (excluding deleted and unavailable accounts)
      totalUsers.value = allUsers.where((user) =>
      !user.isDeleted && user.accountAvailable
      ).length;

      // Active users this month (users with lastActive this month)
      activeUsersThisMonth.value = allUsers.where((user) {
        if (user.lastActive == 0) return false;
        final lastActiveDate = DateTime.fromMillisecondsSinceEpoch(user.lastActive);
        return !user.isDeleted &&
            user.accountAvailable &&
            lastActiveDate.isAfter(startOfMonth) &&
            lastActiveDate.isBefore(endOfMonth);
      }).length;

      // New users this month (joined this month)
      newUsersThisMonth.value = allUsers.where((user) {
        final joinDate = user.joinDate;
        return !user.isDeleted &&
            user.accountAvailable &&
            joinDate.isAfter(startOfMonth) &&
            joinDate.isBefore(endOfMonth);
      }).length;

      // Get users with active subscriptions this month
      int subscriptionCount = 0;
      for (var user in allUsers) {
        if (!user.isDeleted && user.accountAvailable) {
          final hasActive = await _subscriptionRepository.hasActiveSubscription(user.userId);
          if (hasActive) {
            subscriptionCount++;
          }
        }
      }
      totalSubscriptionUsers.value = subscriptionCount;

    } catch (e) {
      print('Error loading dashboard stats: $e');
      totalUsers.value = 0;
      activeUsersThisMonth.value = 0;
      newUsersThisMonth.value = 0;
      totalSubscriptionUsers.value = 0;
    } finally {
      isLoading.value = false;
    }
  }

  String getChangePercentage(int current, int previous) {
    if (previous == 0) return '+100%';
    final change = ((current - previous) / previous * 100).toStringAsFixed(1);
    return change.startsWith('-') ? change : '+$change';
  }
}