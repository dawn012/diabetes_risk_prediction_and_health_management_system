import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/notification/notification_repository.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../common/loaders/loaders.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/web_image_helper.dart';
import '../../authentication/models/admin_model.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../personalization/controllers/user_controller.dart';
import '../views/manager_management/add_manager_dialog.dart';
import '../views/manager_management/edit_manager_dialog.dart';

class ManagerManagementController extends GetxController {
  static ManagerManagementController get instance => Get.find();

  // Repositories
  final userRepository = UserRepository.instance;
  final authRepository = AuthenticationRepository.instance;
  final notificationRepository = NotificationRepository.instance;
  final userController = UserController.instance;

  // Form Key for validation
  final addManagerFormKey = GlobalKey<FormState>();

  // Controllers
  final searchController = TextEditingController();
  final addUsernameController = TextEditingController();
  final addEmailController = TextEditingController();
  final editUsernameController = TextEditingController();

  // Observable variables
  final isLoading = false.obs;
  final currentPage = 1.obs;
  final itemsPerPage = 10.obs;
  final totalPages = 1.obs;
  final allManagers = <AdminModel>[].obs;
  final filteredManagers = <AdminModel>[].obs;
  final selectedManagers = <AdminModel>[].obs;
  final selectedTabIndex = 0.obs; // 0: Active, 1: Banned, 2: Inactive
  final currentUserRole = ''.obs;

  // Sorting
  final sortColumnIndex = 0.obs;
  final sortAscending = true.obs;

  // Add/Edit manager
  final isAddingManager = false.obs;
  final isEditingManager = false.obs;
  final editingManager = Rx<AdminModel?>(null);
  final selectedImageBytes = Rx<Uint8List?>(null);
  final selectedRole = Rx<String>('user manager');
  final selectedEditRole = Rx<String>('user manager');

  // Error messages for form validation
  final usernameDuplicateError = ''.obs;
  final emailDuplicateError = ''.obs;

  Timer? _searchTimer;
  StreamSubscription? _managersStreamSubscription;

  // Constants
  final List<int> itemsPerPageOptions = [5, 10, 25, 50];
  final List<String> managerRoles = [
    'user manager',
    'community manager',
    'achievement manager',
    'reward manager'
  ];

  @override
  void onInit() {
    super.onInit();
    _loadCurrentUserRole();
    _subscribeToManagers();
    searchController.addListener(_onSearchChanged);
  }

  @override
  void onClose() {
    searchController.dispose();
    addUsernameController.dispose();
    addEmailController.dispose();
    editUsernameController.dispose();
    _managersStreamSubscription?.cancel();
    _searchTimer?.cancel();
    super.onClose();
  }

  Future<void> _loadCurrentUserRole() async {
    try {
      final role = await authRepository.getUserRole();
      currentUserRole.value = role;
    } catch (e) {
      print("Error loading user role: $e");
      currentUserRole.value = "user"; // fallback
    }
  }

  bool hasPermission(List<String> allowedRoles) {
    return allowedRoles.contains(currentUserRole.value.toLowerCase());
  }

  void _subscribeToManagers() {
    _managersStreamSubscription = userRepository.streamAllManagers().listen(
      (managers) {
        allManagers.assignAll(managers);
        filterManagers();
      },
      onError: (error) {
        TLoaders.errorSnackBar(
          title: 'Error',
          message: 'Failed to load managers: $error',
        );
      },
    );
  }

  void _onSearchChanged() {
    if (_searchTimer?.isActive ?? false) _searchTimer!.cancel();
    _searchTimer = Timer(Duration(milliseconds: 300), () {
      filterManagers();
    });
  }

  void filterManagers() {
    List<AdminModel> filtered = allManagers.where((manager) {
      bool statusMatch;
      switch (selectedTabIndex.value) {
        case 0: // Active managers
          statusMatch = manager.accountAvailable && !manager.isDeleted;
          break;
        case 1: // Banned managers
          statusMatch = !manager.accountAvailable && !manager.isDeleted;
          break;
        case 2: // Inactive (deleted by user) managers
          statusMatch = manager.isDeleted;
          break;
        default:
          statusMatch = true;
      }

      if (!statusMatch) return false;

      final query = searchController.text.toLowerCase().trim();
      if (query.isEmpty) return true;

      return manager.username.toLowerCase().contains(query) ||
          manager.email.toLowerCase().contains(query) ||
          manager.phoneNumber.toLowerCase().contains(query) ||
          manager.userId.toLowerCase().contains(query) ||
          manager.userType.toLowerCase().contains(query);
    }).toList();

    _applySorting(filtered);
    filteredManagers.assignAll(filtered);
    selectedManagers.clear();
    _updatePagination();
  }

  void _applySorting(List<AdminModel> managers) {
    managers.sort((a, b) {
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
          aValue = a.userType;
          bValue = b.userType;
          break;
        case 5:
          aValue = a.joinDate;
          bValue = b.joinDate;
          break;
        case 6:
          aValue = a.isVerify ? 1 : 0;
          bValue = b.isVerify ? 1 : 0;
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
    final itemCount = filteredManagers.length;
    totalPages.value = (itemCount / itemsPerPage.value)
        .ceil()
        .clamp(1, double.infinity)
        .toInt();

    if (currentPage.value > totalPages.value) {
      currentPage.value = totalPages.value;
    }
  }

  void sortManagers(int columnIndex, bool ascending) {
    sortColumnIndex.value = columnIndex;
    sortAscending.value = ascending;
    filterManagers();
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
    filterManagers();
  }

  void toggleManagerSelection(AdminModel manager, bool selected) {
    if (selected) {
      if (!selectedManagers.contains(manager)) {
        selectedManagers.add(manager);
      }
    } else {
      selectedManagers.removeWhere((m) => m.userId == manager.userId);
    }
    selectedManagers.refresh();
  }

  void toggleSelectAll(bool selected) {
    if (selected) {
      selectedManagers.assignAll(filteredManagers.toList());
    } else {
      selectedManagers.clear();
    }
    selectedManagers.refresh();
  }

  bool? getSelectAllState() {
    if (filteredManagers.isEmpty) return false;
    if (selectedManagers.isEmpty) return false;

    int selectedCount = 0;
    for (AdminModel manager in filteredManagers) {
      if (selectedManagers
          .any((selected) => selected.userId == manager.userId)) {
        selectedCount++;
      }
    }

    if (selectedCount == 0) return false;
    if (selectedCount == filteredManagers.length) return true;
    return null;
  }

  /// Open add manager dialog
  void openAddManagerDialog() {
    if (!hasPermission(['admin'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'Only administrators can add managers',
      );
      return;
    }

    addUsernameController.clear();
    addEmailController.clear();
    selectedImageBytes.value = null;
    selectedRole.value = 'user manager';
    usernameDuplicateError.value = '';
    emailDuplicateError.value = '';
    isAddingManager.value = true;

    // 重置表单状态
    addManagerFormKey.currentState?.reset();

    isAddingManager.value = true;

    // Show dialog
    Get.dialog(
      AddManagerDialog(),
      barrierDismissible: false,
    );
  }

  /// Open edit manager dialog
  void openEditManagerDialog(AdminModel manager) {
    if (!hasPermission(['admin'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'Only administrators can edit managers',
      );
      return;
    }

    editingManager.value = manager;
    editUsernameController.text = manager.username;
    selectedEditRole.value = manager.userType;
    selectedImageBytes.value = null;
    isEditingManager.value = true;

    // Show dialog
    Get.dialog(
      EditManagerDialog(),
      barrierDismissible: false,
    );
  }

  Future<void> pickImage() async {
    try {
      // 使用 ImageHelper 选择图片
      final imageFile = await WebImageHelper.pickImage();
      if (imageFile != null) {
        // Show loading while processing image
        TLoaders.customToast(message: 'Processing image...');

        // 立即验证和压缩图片
        final processedImage =
            await userController.validateAndCompressImage(imageFile);

        if (processedImage != null) {
          // 处理成功，设置新图片
          selectedImageBytes.value = processedImage;
        }
        // 如果处理失败，selectedImage.value 保持不变（仍然是之前的图片或 null）
        // 错误信息已经在 validateAndCompressImage 中通过 SnackBar 显示
      }
    } catch (e) {
      print(e);
      TLoaders.errorSnackBar(
        title: 'Image Selection Failed',
        message: 'Failed to select image: $e',
      );
    }
  }

  /// Check if email is already taken
  Future<bool> checkEmailDuplicate(String email) async {
    try {
      final existingUser = await userRepository.getUserByEmail(email);
      return existingUser != null;
    } catch (e) {
      print('Error checking email duplicate: $e');
      return false;
    }
  }

  /// Add new manager
  Future<void> addManager() async {
    if (!hasPermission(['admin'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'Only administrators can add managers',
      );
      return;
    }

    try {
      isLoading.value = true;

      final username = addUsernameController.text.trim();
      final email = addEmailController.text.trim();
      final role = selectedRole.value;

      // 清除之前的错误
      usernameDuplicateError.value = '';
      emailDuplicateError.value = '';

      // 强制表单重新验证以清除之前的错误显示
      addManagerFormKey.currentState?.validate();

      // 同时检查用户名和邮箱重复
      bool hasErrors = false;

      // 检查用户名重复
      final isUsernameDuplicate =
          await userRepository.checkUsernameDuplicate(username, '');
      if (isUsernameDuplicate) {
        usernameDuplicateError.value = TTexts.usernameAlreadyBeenUsed;
        hasErrors = true;
      }

      // 检查邮箱重复
      final isEmailDuplicate = await checkEmailDuplicate(email);
      if (isEmailDuplicate) {
        emailDuplicateError.value = TTexts.emailAlreadyBeenUsed;
        hasErrors = true;
      }

      // 如果有任何重复错误，停止执行
      if (hasErrors) {
        // 强制重新验证表单以显示错误
        addManagerFormKey.currentState?.validate();
        isLoading.value = false;
        return;
      }

      // Upload profile image if selected - 必须在创建用户之前完成
      String profileImageUrl = '';
      if (selectedImageBytes.value != null) {
        final uploadResult = await userController.uploadCompressedImage(
            compressedImage: selectedImageBytes.value!, forAddManager: true);
        if (uploadResult == null) {
          isLoading.value = false;
          return;
        }
        profileImageUrl = uploadResult;
      }

      // Create user in Firebase Authentication and send verification email
      final result = await authRepository.createManagerWithCloudFunction(email, role, username);

      if (result['success'] == true) {
        final userId = result['userId'];

        // Create manager model
        final newManager = AdminModel(
          userId: userId,
          username: username,
          userType: role,
          email: email,
          profileImg: profileImageUrl,
          joinDate: DateTime.now(),
          isVerify: false,
          // Will be true after email verification
          accountAvailable: true,
        );

        // Save to Firestore
        await userRepository.saveAdminRecord(newManager);

        TLoaders.successSnackBar(
          title: 'Success',
          message: 'Manager added successfully. Verification email sent.',
        );

        closeAddDialog();
      } else {
        throw Exception(result['message'] ?? 'Failed to create manager');
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to add manager: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Save edited manager
  Future<void> saveEditedManager() async {
    if (editingManager.value == null) return;

    if (!hasPermission(['admin'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'Only administrators can edit managers',
      );
      return;
    }

    try {
      isLoading.value = true;

      final newUsername = editUsernameController.text.trim();
      final newRole = selectedEditRole.value;
      final currentManager = editingManager.value!;
      bool hasChanges = false;
      bool roleChanged = false;

      if (newUsername != currentManager.username) {
        final isDuplicate = await userRepository.checkUsernameDuplicate(
          newUsername,
          currentManager.userId,
        );

        if (isDuplicate) {
          TLoaders.errorSnackBar(
            title: 'Username Taken',
            message: 'This username is already in use',
          );
          return;
        }
        hasChanges = true;
      }

      if (newRole != currentManager.userType) {
        hasChanges = true;
        roleChanged = true;
      }

      // 处理图片上传
      String? newImageUrl = currentManager.profileImg;
      bool imageUploadFailed = false;

      if (selectedImageBytes.value != null) {
        final uploadResult = await userController.uploadCompressedImage(
            compressedImage: selectedImageBytes.value!,
            targetUserId: currentManager.userId);
        if (uploadResult != null) {
          newImageUrl = uploadResult;
          hasChanges = true;
        } else {
          // 图片上传失败
          imageUploadFailed = true;
        }
      }

      // 如果有图片上传失败，停止更新
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

      // 如果角色改变，调用 Cloud Function 更新角色
      if (roleChanged) {
        try {
          await authRepository.setUserRole(currentManager.userId, newRole);
          print(
              '✅ Role updated to "$newRole" for user: ${currentManager.userId}');
        } catch (e) {
          print('⚠️ Failed to update role via Cloud Function: $e');
          TLoaders.warningSnackBar(
            title: 'Role Update Warning',
            message:
                'Manager profile updated but role change may not have taken effect',
          );
        }
      }

      final updatedManager = currentManager.copyWith(
        username: newUsername,
        userType: newRole,
        profileImg: newImageUrl ?? currentManager.profileImg,
      );

      await userRepository.updateAdminDetails(updatedManager);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Manager updated successfully',
      );

      closeEditDialog();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update manager: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  void closeAddDialog() {
    addUsernameController.clear();
    addEmailController.clear();
    selectedImageBytes.value = null;
    selectedRole.value = 'user manager';
    usernameDuplicateError.value = '';
    emailDuplicateError.value = '';
    isAddingManager.value = false;
    addManagerFormKey.currentState?.reset();
    isAddingManager.value = false;

    if (Get.context != null) {
      Navigator.of(Get.context!, rootNavigator: true).pop(true);
    }
  }

  void closeEditDialog() {
    editingManager.value = null;
    editUsernameController.clear();
    selectedImageBytes.value = null;
    selectedEditRole.value = 'user manager';
    isEditingManager.value = false;

    if (Get.context != null) {
      Navigator.of(Get.context!, rootNavigator: true).pop(true);
    }
  }

  Future<void> banManager(AdminModel manager) async {
    if (!hasPermission(['admin'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'Only administrators can ban managers',
      );
      return;
    }

    try {
      await userRepository.banUser(manager.userId);
      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Manager banned successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to ban manager: $e',
      );
    }
  }

  Future<void> restoreManager(AdminModel manager) async {
    if (!hasPermission(['admin'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'Only administrators can restore managers',
      );
      return;
    }

    try {
      // Determine if restoring from banned or inactive
      final isFromBanned = !manager.accountAvailable && !manager.isDeleted;
      final isFromInactive = manager.isDeleted;

      if (isFromBanned) {
        await userRepository.restoreUser(manager.userId);
      } else if (isFromInactive) {
        await userRepository.restoreAccount(manager.userId);
      }

      // Send notification
      await notificationRepository.sendSystemNotification(
        userId: manager.userId,
        title: 'Account Restored',
        message:
            'Your account has been restored. You can now access all features again. Welcome back!',
      );

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Manager restored successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to restore manager: $e',
      );
    }
  }

  Future<void> batchBanManagers() async {
    if (selectedManagers.isEmpty) return;

    if (!hasPermission(['admin'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'Only administrators can ban managers',
      );
      return;
    }

    try {
      isLoading.value = true;
      final managersToProcess = List<AdminModel>.from(selectedManagers);

      for (final manager in managersToProcess) {
        await userRepository.banUser(manager.userId);
      }

      TLoaders.successSnackBar(
        title: 'Success',
        message: '${managersToProcess.length} managers banned successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to ban managers: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> batchRestoreManagers() async {
    if (selectedManagers.isEmpty) return;

    if (!hasPermission(['admin'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'Only administrators can restore managers',
      );
      return;
    }

    try {
      isLoading.value = true;
      final managersToProcess = List<AdminModel>.from(selectedManagers);

      for (final manager in managersToProcess) {
        if (!manager.accountAvailable && !manager.isDeleted) {
          await userRepository.restoreUser(manager.userId);
        } else if (manager.isDeleted) {
          await userRepository.restoreAccount(manager.userId);
        }

        await notificationRepository.sendSystemNotification(
          userId: manager.userId,
          title: 'Account Restored',
          message:
              'Your account has been restored. You can now access all features again. Welcome back!',
        );
      }

      TLoaders.successSnackBar(
        title: 'Success',
        message: '${managersToProcess.length} managers restored successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to restore managers: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  /// Resend set password email
  Future<void> resendSetPasswordEmail(AdminModel manager) async {
    if (!hasPermission(['admin'])) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to send verification emails',
      );
      return;
    }

    try {
      isLoading.value = true;

      await authRepository.sendPasswordResetEmail(manager.email);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Set password email sent to ${manager.email}',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to send set password email: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  List<TextSpan> getHighlightedText(String text, String query,
      {Color? textColor}) {
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

  Future<void> refreshManagers() async {
    currentPage.value = 1;
    filterManagers();
  }

  void clearSearch() {
    searchController.clear();
    filterManagers();
  }
}
