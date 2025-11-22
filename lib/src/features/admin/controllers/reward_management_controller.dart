import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/authentication/authentication_repository.dart';
import '../../../data/repositories/reward/reward_reporsitory.dart';
import '../../../data/repositories/user/user_repository.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/helpers/web_image_helper.dart';
import '../../../utils/validators/reward_validator.dart';
import '../../reward/models/reward_model.dart';
import '../views/reward_management/add_reward_dialog.dart';
import '../views/reward_management/edit_reward_dialog.dart';
import '../views/reward_management/reward_detail_dialog.dart';

class RewardManagementController extends GetxController {
  static RewardManagementController get instance => Get.find();

  // Repositories
  final _rewardRepo = Get.put(RewardRepository());
  final _userRepo = Get.put(UserRepository());
  final _authRepo = AuthenticationRepository.instance;

  // Observables
  final isLoading = false.obs;
  final currentPage = 1.obs;
  final itemsPerPage = 10.obs;
  final totalPages = 1.obs;
  final showingActiveRewards = true.obs;
  final selectedRewardType = 'all'.obs;
  final sortColumnIndex = 5.obs; // Default sort by updatedAt
  final sortAscending = false.obs; // Newest first

  // Add/Edit Dialog State
  final addFormKey = GlobalKey<FormState>();
  final editFormKey = GlobalKey<FormState>();
  final addTitleController = TextEditingController();
  final addDescriptionController = TextEditingController();
  final addCostPointsController = TextEditingController();
  final addAvailableQuantityController = TextEditingController();
  final editTitleController = TextEditingController();
  final editDescriptionController = TextEditingController();
  final editCostPointsController = TextEditingController();
  final editAvailableQuantityController = TextEditingController();

  final addSelectedType = Rx<RewardType?>(null);
  final editSelectedType = Rx<RewardType?>(null);
  final addSelectedImageBytes = Rx<Uint8List?>(null);
  final editSelectedImageBytes = Rx<Uint8List?>(null);
  final addIsLoading = false.obs;
  final editIsLoading = false.obs;
  final isEditingReward = false.obs;
  final editingReward = Rx<RewardModel?>(null);
  final hasImageChanged = false.obs;

  // Field errors
  final addTitleError = Rx<String?>(null);
  final addDescriptionError = Rx<String?>(null);
  final addCostPointsError = Rx<String?>(null);
  final addQuantityError = Rx<String?>(null);
  final addImageError = Rx<String?>(null);
  final editTitleError = Rx<String?>(null);
  final editDescriptionError = Rx<String?>(null);
  final editCostPointsError = Rx<String?>(null);
  final editQuantityError = Rx<String?>(null);
  final editImageError = Rx<String?>(null);

  // Data
  final allRewards = <RewardModel>[].obs;
  final filteredRewards = <RewardModel>[].obs;
  final selectedRewards = <RewardModel>[].obs;
  final paginatedRewards = <RewardModel>[].obs;

  // Controllers
  final searchController = TextEditingController();

  // Stream subscriptions
  StreamSubscription<List<RewardModel>>? _rewardsSubscription;

  // Constants
  final List<int> itemsPerPageOptions = [5, 10, 25, 50];
  final List<String> rewardTypes = ['all', 'avatarFrame', 'virtualItem', 'coupon'];

  @override
  void onInit() {
    super.onInit();
    checkPermissionAndLoad();
    setupSearchListener();
  }

  @override
  void onClose() {
    addTitleController.dispose();
    addDescriptionController.dispose();
    addCostPointsController.dispose();
    addAvailableQuantityController.dispose();
    editTitleController.dispose();
    editDescriptionController.dispose();
    editCostPointsController.dispose();
    editAvailableQuantityController.dispose();
    searchController.dispose();
    _rewardsSubscription?.cancel();
    super.onClose();
  }

  void setupSearchListener() {
    searchController.addListener(() {
      filterRewards();
    });
  }

  // Permission Check
  Future<void> checkPermissionAndLoad() async {
    try {
      isLoading.value = true;

      final userRole = await _authRepo.getUserRole();

      if (userRole != 'admin' && userRole != 'reward manager') {
        TLoaders.errorSnackBar(
          title: 'Access Denied',
          message: 'You do not have permission to access reward management',
        );
        Get.back();
        return;
      }

      await loadRewards();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to verify permissions: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  bool get hasPermission {
    final userRole = _authRepo.userRole.value;
    return userRole == 'admin';
  }

  // Data Loading with Streams
  Future<void> loadRewards() async {
    try {
      isLoading.value = true;

      _rewardsSubscription?.cancel();
      _rewardsSubscription = _rewardRepo
          .getAllRewardsForAdminStream()
          .listen(
            (rewards) {
          allRewards.value = rewards;
          filterRewards();
        },
        onError: (error) {
          TLoaders.errorSnackBar(
            title: 'Error',
            message: 'Failed to load rewards: $error',
          );
        },
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to load rewards: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> refreshRewards() async {
    currentPage.value = 1;
    selectedRewards.clear();
    _updatePaginatedData();
    TLoaders.successSnackBar(
      title: 'Success',
      message: 'Rewards refreshed successfully',
    );
  }

  // Get paginated data for current page
  void _updatePaginatedData() {
    final startIndex = (currentPage.value - 1) * itemsPerPage.value;
    final endIndex = (currentPage.value * itemsPerPage.value)
        .clamp(0, filteredRewards.length);

    paginatedRewards.value = filteredRewards.sublist(
      startIndex,
      endIndex,
    );
  }

  // Filtering and Searching
  void filterRewards() {
    List<RewardModel> filtered = allRewards.where((reward) {
      // Filter by status
      bool statusMatch = showingActiveRewards.value
          ? reward.isActive
          : !reward.isActive;

      // Filter by type
      bool typeMatch = selectedRewardType.value == 'all' ||
          reward.rewardType.name == selectedRewardType.value;

      // Filter by search query
      bool searchMatch = true;
      if (searchController.text.isNotEmpty) {
        final query = searchController.text.toLowerCase();
        searchMatch = reward.title.toLowerCase().contains(query) ||
            reward.description.toLowerCase().contains(query) ||
            reward.rewardId.toLowerCase().contains(query);
      }

      return statusMatch && typeMatch && searchMatch;
    }).toList();

    // Apply sorting
    _sortRewards(filtered);

    filteredRewards.value = filtered;
    selectedRewards.clear();
    _updatePagination();
    _updatePaginatedData();
  }

  void _sortRewards(List<RewardModel> rewards) {
    rewards.sort((a, b) {
      dynamic aValue, bValue;

      switch (sortColumnIndex.value) {
        case 0: // Title
          aValue = a.title;
          bValue = b.title;
          break;
        case 1: // Type
          aValue = a.rewardType.name;
          bValue = b.rewardType.name;
          break;
        case 2: // Cost Points
          aValue = a.costPoints;
          bValue = b.costPoints;
          break;
        case 3: // Available Quantity
          aValue = a.availableQuantity ?? 999999;
          bValue = b.availableQuantity ?? 999999;
          break;
        case 4: // Status
          aValue = a.isActive ? 1 : 0;
          bValue = b.isActive ? 1 : 0;
          break;
        case 5: // Updated date (default)
          aValue = a.updatedAt;
          bValue = b.updatedAt;
          break;
        default:
          aValue = a.updatedAt;
          bValue = b.updatedAt;
      }

      int comparison;
      if (aValue is String && bValue is String) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is num && bValue is num) {
        comparison = aValue.compareTo(bValue);
      } else if (aValue is DateTime && bValue is DateTime) {
        comparison = aValue.compareTo(bValue);
      } else {
        comparison = aValue.toString().compareTo(bValue.toString());
      }

      return sortAscending.value ? comparison : -comparison;
    });
  }

  void _updatePagination() {
    final itemCount = filteredRewards.length;
    totalPages.value = (itemCount / itemsPerPage.value).ceil().clamp(1, double.infinity).toInt();

    if (currentPage.value > totalPages.value) {
      currentPage.value = totalPages.value;
    }

    if (currentPage.value < 1 && totalPages.value > 0) {
      currentPage.value = 1;
    }
  }

  // UI State Management
  void showActiveRewards() {
    showingActiveRewards.value = true;
    currentPage.value = 1;
    selectedRewards.clear();
    filterRewards();
  }

  void showDisabledRewards() {
    showingActiveRewards.value = false;
    currentPage.value = 1;
    selectedRewards.clear();
    filterRewards();
  }

  void changeRewardTypeFilter(String type) {
    selectedRewardType.value = type;
    currentPage.value = 1;
    selectedRewards.clear();
    filterRewards();
  }

  void changeItemsPerPage(int? items) {
    if (items != null) {
      itemsPerPage.value = items;
      currentPage.value = 1;
      _updatePagination();
      _updatePaginatedData();
    }
  }

  void changePage(int page) {
    currentPage.value = page;
    _updatePaginatedData();
  }

  void sortRewards(int columnIndex, bool ascending) {
    sortColumnIndex.value = columnIndex;
    sortAscending.value = ascending;
    filterRewards();
  }

  // Selection Management
  void toggleRewardSelection(RewardModel reward, bool selected) {
    if (selected) {
      if (!selectedRewards.contains(reward)) {
        selectedRewards.add(reward);
      }
    } else {
      selectedRewards.remove(reward);
    }
    selectedRewards.refresh();
  }

  void toggleSelectAll(bool selectAll) {
    if (selectAll) {
      selectedRewards.clear();
      selectedRewards.addAll(paginatedRewards);
    } else {
      selectedRewards.clear();
    }
    selectedRewards.refresh();
  }

  // Get reward count by type
  int getRewardCountByType(String type) {
    if (type == 'all') {
      return allRewards.length;
    }
    return allRewards.where((reward) =>
    reward.rewardType.name == type
    ).length;
  }

  // Image Handling for Add Dialog
  Future<void> pickAddRewardImage() async {
    try {
      final imageBytes = await WebImageHelper.pickImage();

      if (imageBytes != null) {
        if (!WebImageHelper.isImageBytes(imageBytes)) {
          addImageError.value = 'Please select a valid image file.';
          return;
        }

        if (!WebImageHelper.isImageSizeValid(imageBytes)) {
          addImageError.value = 'Image size must be less than 5MB.';
          return;
        }

        TLoaders.customToast(message: 'Processing image...');

        final compressedImage = await WebImageHelper.compressImageToWebP(imageBytes);

        if (compressedImage != null) {
          addSelectedImageBytes.value = compressedImage;
          addImageError.value = null;
        } else {
          addImageError.value = 'Failed to process image.';
        }
      }
    } catch (e) {
      addImageError.value = 'Failed to select image: ${e.toString()}.';
    }
  }

  void removeAddImage() {
    addSelectedImageBytes.value = null;
    addImageError.value = null;
  }

  // Image Handling for Edit Dialog
  Future<void> pickEditRewardImage() async {
    try {
      final imageBytes = await WebImageHelper.pickImage();

      if (imageBytes != null) {
        if (!WebImageHelper.isImageBytes(imageBytes)) {
          editImageError.value = 'Please select a valid image file.';
          return;
        }

        if (!WebImageHelper.isImageSizeValid(imageBytes)) {
          editImageError.value = 'Image size must be less than 5MB.';
          return;
        }

        TLoaders.customToast(message: 'Processing image...');

        final compressedImage = await WebImageHelper.compressImageToWebP(imageBytes);

        if (compressedImage != null) {
          editSelectedImageBytes.value = compressedImage;
          hasImageChanged.value = true;
          editImageError.value = null;
        } else {
          editImageError.value = 'Failed to process image.';
        }
      }
    } catch (e) {
      editImageError.value = 'Failed to select image: ${e.toString()}.';
    }
  }

  void removeEditImage() {
    editSelectedImageBytes.value = null;
    hasImageChanged.value = true;
    editImageError.value = null;
  }

  // Check for duplicate title
  Future<bool> checkDuplicateTitle(String title, {String? excludeRewardId}) async {
    final normalizedTitle = title.trim().toLowerCase();
    return allRewards.any((reward) =>
    reward.title.trim().toLowerCase() == normalizedTitle &&
        reward.rewardId != excludeRewardId
    );
  }

  // Validate add form fields
  void validateAddField(String field) {
    switch (field) {
      case 'title':
        addTitleError.value = RewardValidator.validateRewardTitle(
            addTitleController.text);
        break;
      case 'description':
        addDescriptionError.value = RewardValidator.validateDescription(
            addDescriptionController.text);
        break;
      case 'costPoints':
        final points = int.tryParse(addCostPointsController.text);
        addCostPointsError.value = RewardValidator.validateCostPoints(points);
        break;
      case 'quantity':
        final quantity = addAvailableQuantityController.text.isEmpty
            ? null
            : int.tryParse(addAvailableQuantityController.text);
        addQuantityError.value = RewardValidator.validateAvailableQuantity(
            quantity);
        break;
    }
  }

  // Validate edit form fields
  void validateEditField(String field) {
    switch (field) {
      case 'title':
        editTitleError.value = RewardValidator.validateRewardTitle(
            editTitleController.text);
        break;
      case 'description':
        editDescriptionError.value = RewardValidator.validateDescription(
            editDescriptionController.text);
        break;
      case 'costPoints':
        final points = int.tryParse(editCostPointsController.text);
        editCostPointsError.value = RewardValidator.validateCostPoints(points);
        break;
      case 'quantity':
        final quantity = editAvailableQuantityController.text.isEmpty
            ? null
            : int.tryParse(editAvailableQuantityController.text);
        editQuantityError.value = RewardValidator.validateAvailableQuantity(
            quantity);
        break;
    }
  }

  // Clear add form errors
  void clearAddErrors() {
    addTitleError.value = null;
    addDescriptionError.value = null;
    addCostPointsError.value = null;
    addQuantityError.value = null;
    addImageError.value = null;
  }

  // Clear edit form errors
  void clearEditErrors() {
    editTitleError.value = null;
    editDescriptionError.value = null;
    editCostPointsError.value = null;
    editQuantityError.value = null;
    editImageError.value = null;
  }

  // Open View Reward Detail Dialog
  void openViewRewardDetailDialog(RewardModel reward) {
    if (!hasPermission) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to view reward details',
      );
      return;
    }

    // Show dialog
    Get.dialog(
      RewardDetailDialog(
        reward: reward,
        controller: this,
      ),
    );
  }

  // Open Add Reward Dialog
  void openAddRewardDialog() {
    if (!hasPermission) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to add rewards',
      );
      return;
    }

    // Reset form
    addTitleController.clear();
    addDescriptionController.clear();
    addCostPointsController.clear();
    addAvailableQuantityController.clear();
    addSelectedType.value = RewardType.avatarFrame;
    addSelectedImageBytes.value = null;
    clearAddErrors();

    // Show dialog
    Get.dialog(
      AddRewardDialog(controller: this),
      barrierDismissible: false,
    );
  }

  // Open Edit Reward Dialog
  void openEditRewardDialog(RewardModel reward) {
    if (!hasPermission) {
      TLoaders.errorSnackBar(
        title: 'Permission Denied',
        message: 'You do not have permission to edit rewards',
      );
      return;
    }

    editingReward.value = reward;
    initializeEditDialog(reward);
    isEditingReward.value = true;
    hasImageChanged.value = false;

    // Show dialog
    Get.dialog(
      EditRewardDialog(
        reward: reward,
        controller: this,
      ),
      barrierDismissible: false,
    );
  }

  // Initialize edit dialog
  void initializeEditDialog(RewardModel reward) {
    editTitleController.text = reward.title;
    editDescriptionController.text = reward.description;
    editCostPointsController.text = reward.costPoints.toString();
    editAvailableQuantityController.text = reward.availableQuantity?.toString() ?? '';
    editSelectedType.value = reward.rewardType;
    editSelectedImageBytes.value = null;
    clearEditErrors();
  }

  // Handle Add Reward
  Future<void> handleAddReward() async {
    // Clear previous errors
    clearAddErrors();

    // Validate all fields
    addTitleError.value = RewardValidator.validateRewardTitle(addTitleController.text);
    addDescriptionError.value = RewardValidator.validateDescription(addDescriptionController.text);

    final points = int.tryParse(addCostPointsController.text);
    addCostPointsError.value = RewardValidator.validateCostPoints(points);

    final quantity = addAvailableQuantityController.text.isEmpty
        ? null
        : int.tryParse(addAvailableQuantityController.text);
    addQuantityError.value = RewardValidator.validateAvailableQuantity(quantity);

    if (addSelectedType.value == null) {
      TLoaders.errorSnackBar(
        title: 'Validation Error',
        message: 'Please select a reward type',
      );
      return;
    }

    if (addSelectedImageBytes.value == null) {
      addImageError.value = 'Please select an image.';
      return;
    }

    // Check if there are any errors
    if (addTitleError.value != null ||
        addDescriptionError.value != null ||
        addCostPointsError.value != null ||
        addQuantityError.value != null ||
        addImageError.value != null) {
      return;
    }

    // Check duplicate title
    final isDuplicate = await checkDuplicateTitle(addTitleController.text);
    if (isDuplicate) {
      addTitleError.value = 'A reward with this title already exists.';
      return;
    }

    try {
      addIsLoading.value = true;

      // Upload image
      final imageUrl = await _uploadRewardImage(
        addSelectedImageBytes.value!,
        addSelectedType.value!,
      );

      if (imageUrl == null) {
        addImageError.value = 'Failed to upload image.';
        return;
      }

      // Create reward
      final reward = RewardModel(
        rewardId: '', // Will be set by repository
        rewardType: addSelectedType.value!,
        title: addTitleController.text.trim(),
        description: addDescriptionController.text.trim(),
        icon: imageUrl,
        costPoints: points!,
        availableQuantity: quantity,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _rewardRepo.createRewardForAdmin(reward);

      closeAddDialog();

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Reward created successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to create reward: $e',
      );
    } finally {
      addIsLoading.value = false;
    }
  }

  // Handle Edit Reward
  Future<void> handleEditReward(RewardModel originalReward) async {
    // Clear previous errors
    clearEditErrors();

    // Validate all fields
    editTitleError.value = RewardValidator.validateRewardTitle(editTitleController.text);
    editDescriptionError.value = RewardValidator.validateDescription(editDescriptionController.text);

    final points = int.tryParse(editCostPointsController.text);
    editCostPointsError.value = RewardValidator.validateCostPoints(points);

    final quantity = editAvailableQuantityController.text.isEmpty
        ? null
        : int.tryParse(editAvailableQuantityController.text);
    editQuantityError.value = RewardValidator.validateAvailableQuantity(quantity);

    // Check if there are any errors
    if (editTitleError.value != null ||
        editDescriptionError.value != null ||
        editCostPointsError.value != null ||
        editQuantityError.value != null ||
        editImageError.value != null) {
      return;
    }

    // Check duplicate title (excluding current reward)
    if (editTitleController.text.trim() != originalReward.title) {
      final isDuplicate = await checkDuplicateTitle(
        editTitleController.text,
        excludeRewardId: originalReward.rewardId,
      );
      if (isDuplicate) {
        editTitleError.value = 'A reward with this title already exists.';
        return;
      }
    }

    // Check if there are any changes
    if (!hasChanges(originalReward)) {
      TLoaders.warningSnackBar(
        title: 'No Changes',
        message: 'No changes were made to the reward',
      );
      return;
    }

    try {
      editIsLoading.value = true;

      String imageUrl = originalReward.icon;

      // Handle image change
      if (hasImageChanged.value) {
        if (editSelectedImageBytes.value != null) {
          // Upload new image
          final newImageUrl = await _uploadRewardImage(
            editSelectedImageBytes.value!,
            editSelectedType.value!,
          );

          if (newImageUrl == null) {
            editImageError.value = 'Failed to upload image';
            return;
          }

          // Delete old image
          if (originalReward.icon.isNotEmpty) {
            await _userRepo.deleteImage(originalReward.icon);
          }

          imageUrl = newImageUrl;
        } else {
          // Image was removed
          if (originalReward.icon.isNotEmpty) {
            await _userRepo.deleteImage(originalReward.icon);
          }
          imageUrl = '';
        }
      }

      // Update reward
      final updatedReward = originalReward.copyWith(
        title: editTitleController.text.trim(),
        description: editDescriptionController.text.trim(),
        rewardType: editSelectedType.value!,
        costPoints: points!,
        availableQuantity: quantity,
        icon: imageUrl,
        updatedAt: DateTime.now(),
      );

      await _rewardRepo.updateRewardForAdmin(updatedReward);

      closeEditDialog();

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Reward updated successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to update reward: $e',
      );
    } finally {
      editIsLoading.value = false;
    }
  }

  // Check if there are changes
  bool hasChanges(RewardModel originalReward) {
    if (editTitleController.text.trim() != originalReward.title) return true;
    if (editDescriptionController.text.trim() != originalReward.description) return true;
    if (editSelectedType.value != originalReward.rewardType) return true;

    final points = int.tryParse(editCostPointsController.text);
    if (points != originalReward.costPoints) return true;

    final quantity = editAvailableQuantityController.text.isEmpty
        ? null
        : int.tryParse(editAvailableQuantityController.text);
    if (quantity != originalReward.availableQuantity) return true;

    if (hasImageChanged.value) return true;

    return false;
  }

  // Upload reward image to storage
  Future<String?> _uploadRewardImage(Uint8List imageBytes, RewardType type) async {
    try {
      String storageRef;
      switch (type) {
        case RewardType.avatarFrame:
          storageRef = 'reward/avatar/images';
          break;
        case RewardType.virtualItem:
          storageRef = 'reward/virtualItem/images';
          break;
        case RewardType.coupon:
          storageRef = 'reward/coupon/images';
          break;
      }

      final tempFile = await _createTempFile(imageBytes);

      final imageUrl = await _userRepo.uploadImage(storageRef, tempFile);

      return imageUrl;
    } catch (e) {
      print('Error uploading reward image: $e');
      return null;
    }
  }

  // Create temporary XFile from Uint8List
  Future<XFile> _createTempFile(Uint8List bytes) async {
    return XFile.fromData(
      bytes,
      mimeType: 'image/webp',
      name: 'reward_${DateTime.now().millisecondsSinceEpoch}.webp',
    );
  }

  // Close dialogs
  void closeAddDialog() {
    addTitleController.clear();
    addDescriptionController.clear();
    addCostPointsController.clear();
    addAvailableQuantityController.clear();
    addSelectedType.value = null;
    addSelectedImageBytes.value = null;
    clearAddErrors();

    if (Get.context != null) {
      Navigator.of(Get.context!, rootNavigator: true).pop(true);
    }
  }

  void closeEditDialog() {
    editingReward.value = null;
    editTitleController.clear();
    editDescriptionController.clear();
    editCostPointsController.clear();
    editAvailableQuantityController.clear();
    editSelectedType.value = null;
    editSelectedImageBytes.value = null;
    hasImageChanged.value = false;
    clearEditErrors();
    isEditingReward.value = false;

    if (Get.context != null) {
      Navigator.of(Get.context!, rootNavigator: true).pop(true);
    }
  }

  // Enable/Disable Rewards
  Future<void> enableReward(RewardModel reward) async {
    if (!hasPermission) return;

    try {
      isLoading.value = true;
      await _rewardRepo.toggleRewardStatus(reward.rewardId, true);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Reward enabled successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to enable reward: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> disableReward(RewardModel reward) async {
    if (!hasPermission) return;

    try {
      isLoading.value = true;
      await _rewardRepo.toggleRewardStatus(reward.rewardId, false);

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Reward disabled successfully',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to disable reward: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Batch Actions
  Future<void> batchEnableRewards() async {
    if (!hasPermission) return;

    try {
      isLoading.value = true;
      final selectedIds = selectedRewards.map((r) => r.rewardId).toList();

      await _rewardRepo.batchToggleRewardStatus(selectedIds, true);

      selectedRewards.clear();

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Successfully enabled ${selectedIds.length} rewards',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to enable rewards: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> batchDisableRewards() async {
    if (!hasPermission) return;

    try {
      isLoading.value = true;
      final selectedIds = selectedRewards.map((r) => r.rewardId).toList();

      await _rewardRepo.batchToggleRewardStatus(selectedIds, false);

      selectedRewards.clear();

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Successfully disabled ${selectedIds.length} rewards',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to disable rewards: $e',
      );
    } finally {
      isLoading.value = false;
    }
  }

  // Search highlighting
  List<TextSpan> getHighlightedText(String text, String query, {Color? textColor}) {
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
          style: TextStyle(color: textColor),
        ));
        break;
      }

      if (index > start) {
        spans.add(TextSpan(
          text: text.substring(start, index),
          style: TextStyle(color: textColor),
        ));
      }

      spans.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: TextStyle(
          color: textColor,
          backgroundColor: Colors.yellow.withOpacity(0.3),
          fontWeight: FontWeight.bold,
        ),
      ));

      start = index + query.length;
    }

    return spans;
  }
}