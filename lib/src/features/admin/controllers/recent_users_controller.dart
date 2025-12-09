import 'package:get/get.dart';

import '../../../data/repositories/subscription/subscription_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../features/authentication/models/user_model.dart';

class RecentUsersController extends GetxController {
  static RecentUsersController get instance => Get.find();

  final UserRepository _userRepository = UserRepository.instance;
  final SubscriptionRepository _subscriptionRepository = Get.put(SubscriptionRepository());

  var isLoading = false.obs;
  var recentUsers = <UserModel>[].obs;
  final RxMap<String, bool> activeSubscriptions = <String, bool>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadRecentUsers();
  }

  Future<void> loadRecentUsers() async {
    try {
      isLoading.value = true;

      // Get all regular users
      final allUsers = await _userRepository.getRegularUsers();

      // Filter out deleted and unavailable accounts
      final activeUsers = allUsers.where((user) =>
      !user.isDeleted && user.accountAvailable
      ).toList();

      // Sort by join date (most recent first)
      activeUsers.sort((a, b) => b.joinDate.compareTo(a.joinDate));

      // Take only the 10 most recent users
      recentUsers.value = activeUsers.take(10).toList();

      // 为这些 user 预取订阅状态
      await _preloadSubscriptionsForRecentUsers();

    } catch (e) {
      print('Error loading recent users: $e');
      recentUsers.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _preloadSubscriptionsForRecentUsers() async {
    final futures = <Future<void>>[];

    for (final user in recentUsers) {
      futures.add(_subscriptionRepository
          .hasActiveSubscription(user.userId)
          .then((isActive) {
        activeSubscriptions[user.userId] = isActive;
      }));
    }

    await Future.wait(futures);
  }

  bool isActiveSync(String userId) {
    return activeSubscriptions[userId] ?? false;
  }
}