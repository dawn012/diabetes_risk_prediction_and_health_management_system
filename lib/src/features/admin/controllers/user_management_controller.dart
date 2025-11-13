import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/user/user_repository.dart';
import '../../../common/loaders/loaders.dart';
import '../../authentication/models/user_model.dart';

class UserManagementController extends GetxController {
  static UserManagementController get instance => Get.find();

  // Repositories
  final userRepository = Get.put(UserRepository());

  // Controllers
  final searchController = TextEditingController();

  // Observable variables
  final isLoading = false.obs;
  final currentPage = 1.obs;
  final itemsPerPage = 10.obs;
  final totalPages = 1.obs;
  final allUsers = <UserModel>[].obs;
  final filteredUsers = <UserModel>[].obs;
  final selectedUsers = <UserModel>[].obs;
  final showingActiveUsers = true.obs;

  // Sorting
  final sortColumnIndex = 0.obs;
  final sortAscending = true.obs;

  Timer? _searchTimer;

  // Constants
  final List<int> itemsPerPageOptions = [5, 10, 25, 50];

  @override
  void onInit() {
    super.onInit();
    loadUsers();

    // Listen to search changes with debounce
    searchController.addListener(_onSearchChanged);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  // Debounced search to improve performance
  void _onSearchChanged() {
    // Clear any existing timer
    if (_searchTimer?.isActive ?? false) _searchTimer!.cancel();

    // Start new timer
    _searchTimer = Timer(Duration(milliseconds: 300), () {
        filterUsers();
    });
  }

  /// Load all users from repository
  Future<void> loadUsers() async {
    try {
      isLoading.value = true;
      final users = await userRepository.getAllUsers();
      allUsers.assignAll(users);
      filterUsers();
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to load users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Filter users based on search query and active/banned status
  void filterUsers() {
    List<UserModel> filtered = allUsers.where((user) {
      // Filter by active/banned status
      bool statusMatch = showingActiveUsers.value
          ? user.accountAvailable
          : !user.accountAvailable;

      if (!statusMatch) return false;

      // Filter by search query
      final query = searchController.text.toLowerCase().trim();
      if (query.isEmpty) return true;

      return user.username.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.userId.toLowerCase().contains(query) ||
          user.phoneNumber.toLowerCase().contains(query);
    }).toList();

    // Apply sorting
    _applySorting(filtered);

    filteredUsers.assignAll(filtered);

    // Clear selections when data changes
    selectedUsers.clear();
  }

  /// Apply sorting to the filtered users list
  void _applySorting(List<UserModel> users) {
    users.sort((a, b) {
      dynamic aValue, bValue;

      switch (sortColumnIndex.value) {
        case 0: // User ID
          aValue = a.userId;
          bValue = b.userId;
          break;
        case 2: // Username
          aValue = a.username;
          bValue = b.username;
          break;
        case 3: // Email
          aValue = a.email;
          bValue = b.email;
          break;
        case 4: // Phone
          aValue = a.phoneNumber;
          bValue = b.phoneNumber;
          break;
        case 5: // Join Date
          aValue = a.joinDate;
          bValue = b.joinDate;
          break;
        case 6: // Status (isVerify)
          aValue = a.isVerify ? 1 : 0;
          bValue = b.isVerify ? 1 : 0;
          break;
        case 7: // Total Score
          aValue = a.totalScore;
          bValue = b.totalScore;
          break;
        default:
          return 0;
      }

      int result;
      if (aValue is String && bValue is String) {
        result = aValue.toLowerCase().compareTo(bValue.toLowerCase());
      } else {
        result = Comparable.compare(aValue, bValue);
      }

      return sortAscending.value ? result : -result;
    });
  }

  void _updatePagination() {
    final itemCount = filteredUsers.length;
    totalPages.value = (itemCount / itemsPerPage.value).ceil().clamp(1, double.infinity).toInt();

    if (currentPage.value > totalPages.value) {
      currentPage.value = totalPages.value;
    }
  }

  /// Sort users by column
  void sortUsers(int columnIndex, bool ascending) {
    sortColumnIndex.value = columnIndex;
    sortAscending.value = ascending;
    filterUsers();
  }

  void changeItemsPerPage(int? items) {
    if (items != null) {
      itemsPerPage.value = items;
      currentPage.value = 1;
      _updatePagination();
    }
  }

  void changePage(int page) {
    currentPage.value = page;
  }

  /// Show active users
  void showActiveUsers() {
    if (!showingActiveUsers.value) {
      showingActiveUsers.value = true;
      currentPage.value = 1;
      filterUsers(); // This will automatically update the content
    }
  }

  /// Show banned users
  void showBannedUsers() {
    if (showingActiveUsers.value) {
      showingActiveUsers.value = false;
      currentPage.value = 1;
      filterUsers(); // This will automatically update the content
    }
  }

  /// Check if user is selected
  // bool isUserSelected(UserModel user) {
  //   return selectedUsers.contains(user);
  // }

  /// Toggle user selection with proper state management
  void toggleUserSelection(UserModel user, bool selected) {
    print('toggleUserSelection: ${user.username} -> $selected');
    print('selectedUsers before: ${selectedUsers.length}');

    if (selected) {
      if (!selectedUsers.contains(user)) {
        selectedUsers.add(user);
      }
    } else {
      selectedUsers.removeWhere((u) => u.userId == user.userId);
    }

    print('selectedUsers after: ${selectedUsers.length}');
    selectedUsers.refresh();
  }

  /// Toggle select all users
  void toggleSelectAll(bool selected) {
    if (selected) {
      // 全选当前筛选的用户
      selectedUsers.assignAll(filteredUsers.toList());
    } else {
      // 清空选择
      selectedUsers.clear();
    }

    selectedUsers.refresh();
  }

  /// Get select all checkbox state
  bool? getSelectAllState() {
    if (filteredUsers.isEmpty) return false;
    if (selectedUsers.isEmpty) return false;

    // 检查当前筛选的用户中有多少被选中
    int selectedCount = 0;
    for (UserModel user in filteredUsers) {
      if (selectedUsers.any((selected) => selected.userId == user.userId)) {
        selectedCount++;
      }
    }

    if (selectedCount == 0) return false;
    if (selectedCount == filteredUsers.length) return true;
    return null; // Mixed state (部分选中)
  }

  /// Ban a user
  Future<void> banUser(UserModel user) async {
    try {
      await userRepository.banUser(user.userId);

      // Update local data
      final index = allUsers.indexWhere((u) => u.userId == user.userId);
      if (index != -1) {
        allUsers[index] = UserModel(
          userId: user.userId,
          username: user.username,
          userType: user.userType,
          email: user.email,
          phoneNumber: user.phoneNumber,
          profileImg: user.profileImg,
          joinDate: user.joinDate,
          totalScore: user.totalScore,
          isVerify: user.isVerify,
          accountAvailable: false,
        );
      }

      filterUsers();
      TLoaders.successSnackBar(title: 'Success', message: 'User banned successfully');
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to ban user: $e');
    }
  }

  /// Restore a user
  Future<void> restoreUser(UserModel user) async {
    try {
      await userRepository.restoreUser(user.userId);

      // Update local data
      final index = allUsers.indexWhere((u) => u.userId == user.userId);
      if (index != -1) {
        allUsers[index] = UserModel(
          userId: user.userId,
          username: user.username,
          userType: user.userType,
          email: user.email,
          phoneNumber: user.phoneNumber,
          profileImg: user.profileImg,
          joinDate: user.joinDate,
          totalScore: user.totalScore,
          isVerify: user.isVerify,
          accountAvailable: true,
        );
      }

      filterUsers();
      TLoaders.successSnackBar(title: 'Success', message: 'User restored successfully');
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to restore user: $e');
    }
  }

  /// Batch ban users
  Future<void> batchBanUsers() async {
    if (selectedUsers.isEmpty) return;

    try {
      isLoading.value = true;
      final usersToProcess = List<UserModel>.from(selectedUsers);

      for (final user in usersToProcess) {
        await userRepository.banUser(user.userId);

        // Update local data
        final index = allUsers.indexWhere((u) => u.userId == user.userId);
        if (index != -1) {
          allUsers[index] = UserModel(
            userId: user.userId,
            username: user.username,
            userType: user.userType,
            email: user.email,
            phoneNumber: user.phoneNumber,
            profileImg: user.profileImg,
            joinDate: user.joinDate,
            totalScore: user.totalScore,
            isVerify: user.isVerify,
            accountAvailable: false,
          );
        }
      }

      filterUsers();
      TLoaders.successSnackBar(
          title: 'Success',
          message: '${usersToProcess.length} users banned successfully'
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to ban users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Batch restore users
  Future<void> batchRestoreUsers() async {
    if (selectedUsers.isEmpty) return;

    try {
      isLoading.value = true;
      final usersToProcess = List<UserModel>.from(selectedUsers);

      for (final user in usersToProcess) {
        await userRepository.restoreUser(user.userId);

        // Update local data
        final index = allUsers.indexWhere((u) => u.userId == user.userId);
        if (index != -1) {
          allUsers[index] = UserModel(
            userId: user.userId,
            username: user.username,
            userType: user.userType,
            email: user.email,
            phoneNumber: user.phoneNumber,
            profileImg: user.profileImg,
            joinDate: user.joinDate,
            totalScore: user.totalScore,
            isVerify: user.isVerify,
            accountAvailable: true,
          );
        }
      }

      filterUsers();
      TLoaders.successSnackBar(
          title: 'Success',
          message: '${usersToProcess.length} users restored successfully'
      );
    } catch (e) {
      TLoaders.errorSnackBar(title: 'Error', message: 'Failed to restore users: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Edit user (placeholder for now)
  void editUser(UserModel user) {
    // TODO: Implement edit user functionality
    TLoaders.warningSnackBar(title: 'Info', message: 'Edit user functionality coming soon');
  }

  /// Add new user (placeholder for now)
  void addUser() {
    // TODO: Implement add user functionality
    TLoaders.warningSnackBar(title: 'Info', message: 'Add user functionality coming soon');
  }

  /// Get highlighted text for search with proper TextSpan generation
  List<TextSpan> getHighlightedText(String text, String query, {Color? textColor}) {
    if (query.isEmpty) {
      return [TextSpan(
        text: text,
        style: TextStyle(color: textColor),
      )];
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    int start = 0;
    int indexOfHighlight;

    do {
      indexOfHighlight = lowerText.indexOf(lowerQuery, start);
      if (indexOfHighlight < 0) {
        // Add remaining text
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: TextStyle(color: textColor),
          ));
        }
        break;
      }

      // Add text before highlight
      if (indexOfHighlight > start) {
        spans.add(TextSpan(
          text: text.substring(start, indexOfHighlight),
          style: TextStyle(color: textColor),
        ));
      }

      // Add highlighted text with adaptive color
      spans.add(TextSpan(
        text: text.substring(indexOfHighlight, indexOfHighlight + query.length),
        style: TextStyle(
          backgroundColor: Colors.yellow.withOpacity(0.8),
          fontWeight: FontWeight.bold,
          color: Colors.black87, // 在黄色背景上黑色文字更清晰
        ),
      ));

      start = indexOfHighlight + query.length;
    } while (true);

    return spans;
  }

  /// Refresh users list
  Future<void> refreshUsers() async {
    currentPage.value = 1;
    await loadUsers();
  }

  /// Clear search
  void clearSearch() {
    searchController.clear();
    filterUsers();
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
    super.dispose();
  }
}