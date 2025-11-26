import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/user/user_repository.dart';
import '../../../common/loaders/loaders.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/web_image_helper.dart';
import '../../authentication/models/user_model.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../personalization/controllers/user_controller.dart';
import '../views/user_management/edit_user_dialog.dart';
import '../../../data/repositories/notification/notification_repository.dart';

class UserManagementController extends GetxController {
  static UserManagementController get instance => Get.find();

  // Repositories
  final userRepository = UserRepository.instance;
  final authRepository = AuthenticationRepository.instance;
  final userController = UserController.instance;
  final notificationRepository = NotificationRepository.instance;

  // Controllers
  final searchController = TextEditingController();
  final editUsernameController = TextEditingController();

  // Observable variables
  final isLoading = false.obs;
  final currentPage = 1.obs;
  final itemsPerPage = 10.obs;
  final totalPages = 1.obs;
  final allUsers = <UserModel>[].obs;
  final filteredUsers = <UserModel>[].obs;
  final selectedUsers = <UserModel>[].obs;
  final selectedTabIndex = 0.obs; // 0: Active, 1: Banned, 2: Inactive
  final currentUserRole = ''.obs;

  // Sorting
  final sortColumnIndex = 0.obs;
  final sortAscending = true.obs;

  // Edit user
  final isEditingUser = false.obs;
  final editingUser = Rx<UserModel?>(null);
  final selectedImageBytes = Rx<Uint8List?>(null);

  // Error messages for form validation
  final usernameError = Rx<String?>(null);

  Timer? _searchTimer;
  StreamSubscription? _usersStreamSubscription;

  // Constants
  final List<int> itemsPerPageOptions = [5, 10, 25, 50];

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUserRole();
    _subscribeToUsers();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void onClose() {
    searchController.dispose();
    editUsernameController.dispose();
    _usersStreamSubscription?.cancel();
    _searchTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadCurrentUserRole() async {
    try {
      final role = await authRepository.getUserRole();
      currentUserRole.value = role;
    } catch (e) {
      print("Error loading user role: $e");
      currentUserRole.value = "user";
    }
  }

  bool hasPermission(List<String> allowedRoles) {
    return allowedRoles.contains(currentUserRole.value.toLowerCase());
  }

  void _subscribeToUsers() {
    _usersStreamSubscription = userRepository.streamAllUsers().listen(
          (users) {
        allUsers.assignAll(users);
        filterUsers();
      },
      onError: (error) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to load users: $error',
        );
      },
    );
  }

  void _onSearchChanged() {
    if (_searchTimer?.isActive ?? false) _searchTimer!.cancel();
    _searchTimer = Timer(Duration(milliseconds: 300), () {
      filterUsers();
    });
  }

  void filterUsers() {
    List<UserModel> filtered = allUsers.where((user) {
      bool statusMatch;
      switch (selectedTabIndex.value) {
        case 0: // Active users
          statusMatch = user.accountAvailable && !user.isDeleted;
          break;
        case 1: // Banned users
          statusMatch = !user.accountAvailable && !user.isDeleted;
          break;
        case 2: // Inactive (deleted by user)
          statusMatch = user.isDeleted;
          break;
        default:
          statusMatch = true;
      }

      if (!statusMatch) return false;

      final query = searchController.text.toLowerCase().trim();
      if (query.isEmpty) return true;

      return user.username.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          user.phoneNumber.toLowerCase().contains(query) ||
          user.userId.toLowerCase().contains(query);
    }).toList();

    _applySorting(filtered);
    filteredUsers.assignAll(filtered);
    selectedUsers.clear();
    _updatePagination();
  }

  void _applySorting(List<UserModel> users) {
    users.sort((a, b) {
      dynamic aValue, bValue;

      switch (sortColumnIndex.value) {
        case 0:
          aValue = a.userId;
          bValue = b.userId;
          break;
        case 2:
          aValue = a.username;
          bValue = b.username;
          break;
        case 3:
          aValue = a.email;
          bValue = b.email;
          break;
        case 4:
          aValue = a.phoneNumber;
          bValue = b.phoneNumber;
          break;
        case 5:
          aValue = a.joinDate;
          bValue = b.joinDate;
          break;
        case 6:
          aValue = a.isVerify ? 1 : 0;
          bValue = b.isVerify ? 1 : 0;
          break;
        case 7:
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

  void changeTab(int index) {
    selectedTabIndex.value = index;
    currentPage.value = 1;
    filterUsers();
  }

  void toggleUserSelection(UserModel user, bool selected) {
    if (selected) {
      if (!selectedUsers.contains(user)) {
        selectedUsers.add(user);
      }
    } else {
      selectedUsers.removeWhere((u) => u.userId == user.userId);
    }
    selectedUsers.refresh();
  }

  void toggleSelectAll(bool selected) {
    if (selected) {
      selectedUsers.assignAll(filteredUsers.toList());
    } else {
      selectedUsers.clear();
    }
    selectedUsers.refresh();
  }

  bool? getSelectAllState() {
    if (filteredUsers.isEmpty) return false;
    if (selectedUsers.isEmpty) return false;

    int selectedCount = 0;
    for (UserModel user in filteredUsers) {
      if (selectedUsers.any((selected) => selected.userId == user.userId)) {
        selectedCount++;
      }
    }

    if (selectedCount == 0) return false;
    if (selectedCount == filteredUsers.length) return true;
    return null;
  }

  /// Open edit user dialog
  void openEditUserDialog(UserModel user) {
    if (!hasPermission(['admin', 'user manager'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to edit users',
      );
      return;
    }

    editingUser.value = user;
    editUsernameController.text = user.username;
    selectedImageBytes.value = null;
    usernameError.value = null;
    isEditingUser.value = true;

    Get.dialog(
      EditUserDialog(),
      barrierDismissible: false,
    );
  }

  Future<void> pickImage() async {
    try {
      final imageBytes = await WebImageHelper.pickImage();
      if (imageBytes != null) {
        TLoaders.customToast(message: 'Processing image...');
        final processedImage = await userController.validateAndCompressImage(imageBytes);
        if (processedImage != null) {
          selectedImageBytes.value = processedImage;
        }
      }
    } catch (e) {
      print(e);
      TLoaders.errorSnackBar(
        title: 'Image Selection Failed',
        message: 'Failed to select image: $e',
      );
    }
  }

  /// Save edited user
  Future<void> saveEditedUser() async {
    if (editingUser.value == null) return;

    if (!hasPermission(['admin', 'user manager'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to edit users',
      );
      return;
    }

    try {
      isLoading.value = true;

      final newUsername = editUsernameController.text.trim();
      final currentUser = editingUser.value!;
      bool hasChanges = false;
      bool usernameChanged = false;
      bool profileImageChanged = false;

      // 跟踪具体的变化
      final List<String> changes = [];

      if (newUsername != currentUser.username) {
        final isDuplicate = await userRepository.checkUsernameDuplicate(
          newUsername,
          currentUser.userId,
        );

        if (isDuplicate) {
          usernameError.value = TTexts.usernameAlreadyBeenUsed;
          isLoading.value = false;
          return;
        }
        hasChanges = true;
        usernameChanged = true;
        changes.add('username');
      }

      String? newImageUrl = currentUser.profileImg;
      bool imageUploadFailed = false;

      if (selectedImageBytes.value != null) {
        final uploadResult = await userController.uploadCompressedImage(
          compressedImage: selectedImageBytes.value!,
          targetUserId: currentUser.userId,
        );
        if (uploadResult != null) {
          newImageUrl = uploadResult;
          hasChanges = true;
          profileImageChanged = true;
          changes.add('profile picture');
        } else {
          imageUploadFailed = true;
        }
      }

      if (imageUploadFailed) {
        isLoading.value = false;
        return;
      }

      if (!hasChanges) {
        TLoaders.warningSnackBar(
          title: 'No Changes',
          message: 'No changes were made',
        );
        return;
      }

      final updatedUser = currentUser.copyWith(
        username: newUsername,
        profileImg: newImageUrl ?? currentUser.profileImg,
      );

      await userRepository.updateUserDetails(updatedUser);

      // 构建详细的通知消息
      String notificationMessage = notificationRepository.generateProfileUpdateMessage(
        usernameChanged: usernameChanged,
        profileImageChanged: profileImageChanged,
        oldUsername: currentUser.username,
        newUsername: newUsername,
      );

      // Send notification to user
      await notificationRepository.sendSystemNotification(
        userId: currentUser.userId,
        title: 'Account Updated',
        message: notificationMessage,
      );

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'User updated successfully',
      );

      closeEditDialog();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update user: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void closeEditDialog() {
    editingUser.value = null;
    editUsernameController.clear();
    selectedImageBytes.value = null;
    usernameError.value = null;
    isEditingUser.value = false;

    if (Get.context != null) {
      Navigator.of(Get.context!, rootNavigator: true).pop(true);
    }
  }

  Future<void> banUser(UserModel user) async {
    if (!hasPermission(['admin', 'user manager'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to ban users',
      );
      return;
    }

    try {
      await userRepository.banUser(user.userId);

      // Send notification
      await notificationRepository.sendSystemNotification(
        userId: user.userId,
        title: 'Account Suspended',
        message: 'Your account has been suspended by an administrator. If you believe this is an error, please contact support.',
      );

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'User banned successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to ban user: $e',
      );
    }
  }

  Future<void> restoreUser(UserModel user) async {
    if (!hasPermission(['admin', 'user manager'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to restore users',
      );
      return;
    }

    try {
      // Determine if restoring from banned or inactive
      final isFromBanned = !user.accountAvailable && !user.isDeleted;
      final isFromInactive = user.isDeleted;

      if (isFromBanned) {
        await userRepository.restoreUser(user.userId);
      } else if (isFromInactive) {
        await userRepository.restoreAccount(user.userId);
      }

      // Send notification
      await notificationRepository.sendSystemNotification(
        userId: user.userId,
        title: 'Account Restored',
        message: 'Your account has been restored. You can now access all features again. Welcome back!',
      );

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'User restored successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to restore user: $e',
      );
    }
  }

  Future<void> batchBanUsers() async {
    if (selectedUsers.isEmpty) return;

    if (!hasPermission(['admin', 'user manager'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to ban users',
      );
      return;
    }

    try {
      isLoading.value = true;
      final usersToProcess = List<UserModel>.from(selectedUsers);

      for (final user in usersToProcess) {
        await userRepository.banUser(user.userId);
        await notificationRepository.sendSystemNotification(
          userId: user.userId,
          title: 'Account Suspended',
          message: 'Your account has been suspended by an administrator. If you believe this is an error, please contact support.',
        );
      }

      TLoaders.successSnackBar(
        title: 'Success',
        message: '${usersToProcess.length} users banned successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to ban users: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> batchRestoreUsers() async {
    if (selectedUsers.isEmpty) return;

    if (!hasPermission(['admin', 'user manager'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to restore users',
      );
      return;
    }

    try {
      isLoading.value = true;
      final usersToProcess = List<UserModel>.from(selectedUsers);

      for (final user in usersToProcess) {
        if (!user.accountAvailable && !user.isDeleted) {
          await userRepository.restoreUser(user.userId);
        } else if (user.isDeleted) {
          await userRepository.restoreAccount(user.userId);
        }

        await notificationRepository.sendSystemNotification(
          userId: user.userId,
          title: 'Account Restored',
          message: 'Your account has been restored. You can now access all features again. Welcome back!',
        );
      }

      TLoaders.successSnackBar(
        title: 'Success',
        message: '${usersToProcess.length} users restored successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to restore users: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  List<TextSpan> getHighlightedText(String text, String query, {Color? textColor}) {
    if (query.isEmpty) {
      return [TextSpan(text: text, style: TextStyle(color: textColor))];
    }

    final List<TextSpan> spans = [];
    final String lowerText = text.toLowerCase();
    final String lowerQuery = query.toLowerCase();

    int start = 0;
    int indexOfHighlight;

    do {
      indexOfHighlight = lowerText.indexOf(lowerQuery, start);
      if (indexOfHighlight < 0) {
        if (start < text.length) {
          spans.add(TextSpan(
            text: text.substring(start),
            style: TextStyle(color: textColor),
          ));
        }
        break;
      }

      if (indexOfHighlight > start) {
        spans.add(TextSpan(
          text: text.substring(start, indexOfHighlight),
          style: TextStyle(color: textColor),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(indexOfHighlight, indexOfHighlight + query.length),
        style: TextStyle(
          backgroundColor: Colors.yellow.withOpacity(0.8),
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ));

      start = indexOfHighlight + query.length;
    } while (true);

    return spans;
  }

  Future<void> refreshUsers() async {
    currentPage.value = 1;
    filterUsers();
  }

  void clearSearch() {
    searchController.clear();
    filterUsers();
  }

  void clearUsernameError() {
    usernameError.value = null;
  }
}