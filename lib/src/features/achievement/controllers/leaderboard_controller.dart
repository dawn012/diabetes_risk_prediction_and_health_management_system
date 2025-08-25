import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/colors.dart';

class LeaderboardController extends GetxController {
  static LeaderboardController get instance => Get.find();

  // Observable variables
  var isLoading = false.obs;
  var selectedTab = 0.obs; // 0: This Month, 1: Last Month
  var users = <UserModel>[].obs;
  var leaderboardData = <LeaderboardModel>[].obs;
  var currentUser = Rx<UserModel?>(null);
  var currentUserRankData = Rx<LeaderboardModel?>(null);

  @override
  void onInit() {
    super.onInit();
    loadLeaderboardData();
  }

  void changeTab(int index) {
    selectedTab.value = index;
    loadLeaderboardData();
  }

  Future<void> loadLeaderboardData() async {
    try {
      isLoading.value = true;

      // Simulate API call delay
      await Future.delayed(Duration(milliseconds: 800));

      // Sample data - replace with actual API call
      users.value = getSampleUsers();

      // Set current user (example: user with userId "current_user")
      currentUser.value = users.firstWhereOrNull((user) => user.userId == "current_user");

      // Generate leaderboard data with ranking comparisons
      leaderboardData.value = generateLeaderboardData();

      // Find current user's ranking data
      currentUserRankData.value = leaderboardData.firstWhereOrNull(
              (data) => data.user.userId == "current_user"
      );

    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to load leaderboard data',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: TColors.white,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshData() async {
    await loadLeaderboardData();
  }

  List<LeaderboardModel> generateLeaderboardData() {
    List<LeaderboardModel> data = [];

    // Sort users by totalScore in descending order
    users.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    for (int i = 0; i < users.length; i++) {
      final user = users[i];
      final currentRank = i + 1;

      // Generate random previous rank for demo (in real app, get from API)
      int? previousRank;
      RankChange? rankChange;

      if (selectedTab.value == 0) { // This month - compare with last month
        // Random previous rank for demo
        final prevRank = currentRank + ([-3, -2, -1, 0, 1, 2, 3]..shuffle()).first;
        if (prevRank > 0 && prevRank <= users.length + 5) {
          previousRank = prevRank;
          if (prevRank > currentRank) {
            rankChange = RankChange.up;
          } else if (prevRank < currentRank) {
            rankChange = RankChange.down;
          } else {
            rankChange = RankChange.same;
          }
        } else {
          rankChange = RankChange.new_entry;
        }
      }

      data.add(LeaderboardModel(
        user: user,
        currentRank: currentRank,
        previousRank: previousRank,
        rankChange: rankChange,
        isCurrentUser: user.userId == "current_user",
      ));
    }

    return data.take(20).toList(); // Take top 20
  }

  List<UserModel> getSampleUsers() {
    return [
      UserModel(
        userId: "user_1",
        userName: "Vatani",
        userType: "premium",
        email: "vatani@example.com",
        password: "",
        phone: "1234567890",
        profileImg: "https://i.pravatar.cc/150?img=1",
        joinDate: DateTime.now().subtract(Duration(days: 30)),
        totalScore: 1952,
        isVerify: true,
        loginAttempt: 0,
        lastAttemptTime: DateTime.now(),
        accountAvailable: true,
      ),
      UserModel(
        userId: "user_2",
        userName: "Jonathan",
        userType: "premium",
        email: "jonathan@example.com",
        password: "",
        phone: "1234567891",
        profileImg: "https://i.pravatar.cc/150?img=2",
        joinDate: DateTime.now().subtract(Duration(days: 25)),
        totalScore: 1631,
        isVerify: true,
        loginAttempt: 0,
        lastAttemptTime: DateTime.now(),
        accountAvailable: true,
      ),
      UserModel(
        userId: "current_user", // This will be highlighted as current user
        userName: "Iman",
        userType: "regular",
        email: "iman@example.com",
        password: "",
        phone: "1234567892",
        profileImg: "https://i.pravatar.cc/150?img=3",
        joinDate: DateTime.now().subtract(Duration(days: 20)),
        totalScore: 2078,
        isVerify: true,
        loginAttempt: 0,
        lastAttemptTime: DateTime.now(),
        accountAvailable: true,
      ),
      UserModel(
        userId: "user_4",
        userName: "Paul",
        userType: "regular",
        email: "paul@example.com",
        password: "",
        phone: "1234567893",
        profileImg: "https://i.pravatar.cc/150?img=4",
        joinDate: DateTime.now().subtract(Duration(days: 15)),
        totalScore: 1243,
        isVerify: true,
        loginAttempt: 0,
        lastAttemptTime: DateTime.now(),
        accountAvailable: true,
      ),
      UserModel(
        userId: "user_5",
        userName: "Robert",
        userType: "regular",
        email: "robert@example.com",
        password: "",
        phone: "1234567894",
        profileImg: "https://i.pravatar.cc/150?img=5",
        joinDate: DateTime.now().subtract(Duration(days: 12)),
        totalScore: 1109,
        isVerify: true,
        loginAttempt: 0,
        lastAttemptTime: DateTime.now(),
        accountAvailable: true,
      ),
      UserModel(
        userId: "user_6",
        userName: "Gwen",
        userType: "premium",
        email: "gwen@example.com",
        password: "",
        phone: "1234567895",
        profileImg: "https://i.pravatar.cc/150?img6",
        joinDate: DateTime.now().subtract(Duration(days: 10)),
        totalScore: 954,
        isVerify: true,
        loginAttempt: 0,
        lastAttemptTime: DateTime.now(),
        accountAvailable: true,
      ),
      UserModel(
        userId: "user_7",
        userName: "Emma",
        userType: "regular",
        email: "emma@example.com",
        password: "",
        phone: "1234567896",
        profileImg: "https://i.pravatar.cc/150?img=7",
        joinDate: DateTime.now().subtract(Duration(days: 8)),
        totalScore: 913,
        isVerify: true,
        loginAttempt: 0,
        lastAttemptTime: DateTime.now(),
        accountAvailable: true,
      ),
      UserModel(
        userId: "user_8",
        userName: "Sophia",
        userType: "premium",
        email: "sophia@example.com",
        password: "",
        phone: "1234567897",
        profileImg: "https://i.pravatar.cc/150?img=8",
        joinDate: DateTime.now().subtract(Duration(days: 7)),
        totalScore: 876,
        isVerify: true,
        loginAttempt: 0,
        lastAttemptTime: DateTime.now(),
        accountAvailable: true,
      ),
      UserModel(
        userId: "user_9",
        userName: "Mia",
        userType: "regular",
        email: "mia@example.com",
        password: "",
        phone: "1234567898",
        profileImg: "https://i.pravatar.cc/150?img=9",
        joinDate: DateTime.now().subtract(Duration(days: 6)),
        totalScore: 698,
        isVerify: true,
        loginAttempt: 0,
        lastAttemptTime: DateTime.now(),
        accountAvailable: true,
      ),
      UserModel(
        userId: "user_10",
        userName: "John",
        userType: "regular",
        email: "john@example.com",
        password: "",
        phone: "1234567899",
        profileImg: "https://i.pravatar.cc/150?img=10",
        joinDate: DateTime.now().subtract(Duration(days: 5)),
        totalScore: 649,
        isVerify: true,
        loginAttempt: 0,
        lastAttemptTime: DateTime.now(),
        accountAvailable: true,
      ),
      UserModel(
        userId: "user_11",
        userName: "You",
        userType: "premium",
        email: "you@example.com",
        password: "",
        phone: "1234567890",
        profileImg: "https://i.pravatar.cc/150?img=11",
        joinDate: DateTime.now().subtract(Duration(days: 4)),
        totalScore: 432,
        isVerify: true,
        loginAttempt: 0,
        lastAttemptTime: DateTime.now(),
        accountAvailable: true,
      ),
    ];
  }
}

// Leaderboard Model
class LeaderboardModel {
  final UserModel user;
  final int currentRank;
  final int? previousRank;
  final RankChange? rankChange;
  final bool isCurrentUser;

  LeaderboardModel({
    required this.user,
    required this.currentRank,
    this.previousRank,
    this.rankChange,
    required this.isCurrentUser,
  });

  int get rankDifference {
    if (previousRank == null) return 0;
    return previousRank! - currentRank;
  }
}

enum RankChange {
  up,
  down,
  same,
  new_entry,
}

// User Model
class UserModel {
  final String userId;
  final String userName;
  final String userType;
  final String email;
  final String password;
  final String phone;
  final String profileImg;
  final DateTime joinDate;
  final int totalScore;
  final bool isVerify;
  final int loginAttempt;
  final DateTime lastAttemptTime;
  final bool accountAvailable;

  UserModel({
    required this.userId,
    required this.userName,
    required this.userType,
    required this.email,
    required this.password,
    required this.phone,
    required this.profileImg,
    required this.joinDate,
    required this.totalScore,
    required this.isVerify,
    required this.loginAttempt,
    required this.lastAttemptTime,
    required this.accountAvailable,
  });
}