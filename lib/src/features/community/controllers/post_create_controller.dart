import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

import '../../../common/widgets/camera/media_picker.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/helpers/media_helper.dart';
import '../../../utils/validators/community_validator.dart';
import '../models/post_media_item.dart';
import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/helpers/image_helper.dart';
import '../../../utils/helpers/video_helper.dart';
import '../../../data/repositories/community/post_repository.dart';
import '../models/post_model.dart';
import '../views/create_post/widgets/media_preview_screen.dart';
import 'post_controller.dart';

class PostCreateController extends GetxController {
  static PostCreateController get instance => Get.find();

  // Form controllers
  final contentController = TextEditingController();
  final characterCount = 0.obs;

  // Observables
  final selectedPostType = 'General Discussion'.obs;
  final mediaItems = <PostMediaItem>[].obs;
  final isCreatingPost = false.obs;
  final isProcessingMedia = false.obs;

  // Editing state
  final isEditingMode = false.obs;
  String? editingPostId;
  bool wasDisabledBeforeEdit = false; // Track if post was disabled
  String _originalContent = '';
  String _originalPostType = 'General Discussion';
  List<String> _originalMediaUrls = [];
  final hasChanges = false.obs;

  // Add this for real-time validation
  final canSubmit = false.obs;

  // Constants
  static const int maxMediaCount = 10;

  // Post types
  final List<String> postTypes = [
    'General Discussion',
    'Tips & Tricks',
    'Meal or Recipe',
    'Success Story',
  ];

  // Repository
  final _postRepo = Get.put(PostRepository());

  @override
  void onInit() {
    super.onInit();
    contentController.addListener(_onContentChanged);
  }

  @override
  void onClose() {
    contentController.dispose();
    _cleanupTempFiles();
    super.onClose();
  }

  bool _hasUnsavedChanges = false;

  void _onContentChanged() {
    final newCount = contentController.text.length;

    // 更新响应式字符计数
    if (characterCount.value != newCount) {
      characterCount.value = newCount;
    }

    _hasUnsavedChanges = contentController.text.trim().isNotEmpty || mediaItems.isNotEmpty;
    _updateCanSubmit();
    _checkForChanges();
  }

  void _updateCanSubmit() {
    final hasContent = contentController.text.trim().isNotEmpty;
    final hasProcessingMedia = mediaItems.any((item) => item.isProcessing);
    final hasFailedDownloads = isEditingMode.value &&
        mediaItems.any((item) => item.isExisting && item.isDownloadFailed);
    final isUploading = isCreatingPost.value;

    // 编辑模式下：需要内容且没有处理中的媒体，并且有变化
    // 创建模式下：需要内容且没有处理中的媒体
    final canSubmitNow = hasContent &&
        !hasProcessingMedia &&
        !hasFailedDownloads &&
        !isUploading &&
        (isEditingMode.value ? hasChanges.value : true);

    canSubmit.value = canSubmitNow;
  }

  /// 检查是否有任何修改
  void _checkForChanges() {
    if (!isEditingMode.value) {
      hasChanges.value = contentController.text.trim().isNotEmpty || mediaItems.isNotEmpty;
      return;
    }

    // 检查内容是否改变
    final contentChanged = contentController.text.trim() != _originalContent;

    // 检查帖子类型是否改变
    final typeChanged = selectedPostType.value != _originalPostType;

    // 检查媒体是否改变
    final mediaChanged = _hasMediaChanges();

    hasChanges.value = contentChanged || typeChanged || mediaChanged;
    _updateCanSubmit();
  }

  /// 检查媒体是否有变化
  bool _hasMediaChanges() {
    // 如果媒体数量不同，肯定有变化
    if (mediaItems.length != _originalMediaUrls.length) {
      return true;
    }

    // 检查现有的媒体URL是否有变化
    final currentExistingUrls = mediaItems
        .where((item) => item.existingUrl != null)
        .map((item) => item.existingUrl!)
        .toList();

    // 如果现有URL数量不同
    if (currentExistingUrls.length != _originalMediaUrls.length) {
      return true;
    }

    // 检查URL是否相同（顺序不重要）
    final originalSet = _originalMediaUrls.toSet();
    final currentSet = currentExistingUrls.toSet();

    if (originalSet.length != currentSet.length) {
      return true;
    }

    // 检查是否有新增的媒体文件（非现有URL的媒体）
    final hasNewMedia = mediaItems.any((item) =>
    item.existingUrl == null && item.file != null);

    return !originalSet.containsAll(currentSet) || hasNewMedia;
  }

  /// Initialize controller for editing existing post
  void initializeForEditing(PostModel post) async {
    isEditingMode.value = true;
    editingPostId = post.postId;
    wasDisabledBeforeEdit = post.isDisable; // Track original status

    // 保存原始数据用于比较
    _originalContent = post.postContent;
    _originalPostType = post.postType.displayName;
    _originalMediaUrls = List.from(post.mediaUrls);

    // Set content
    contentController.text = post.postContent;

    // Set post type
    selectedPostType.value = post.postType.displayName;

    // Clear any existing media
    mediaItems.clear();

    // Load existing media
    if (post.mediaUrls.isNotEmpty) {
      _loadExistingMediaFromPost(post);
    }

    _hasUnsavedChanges = false;
    _checkForChanges();
    _updateCanSubmit();
  }

  /// Load existing media from post
  void _loadExistingMediaFromPost(PostModel post) {
    try {
      for (int i = 0; i < post.mediaUrls.length; i++) {
        final url = post.mediaUrls[i];
        final mediaId = const Uuid().v4();

        final isVideo = url.toLowerCase().contains('/videos/') ||
            url.toLowerCase().contains('.mp4') ||
            url.toLowerCase().contains('.mov');
        final mediaType = isVideo ? 'video' : 'image';

        final mediaItem = PostMediaItem(
          id: mediaId,
          file: null,
          type: mediaType,
          isProcessing: false,
          existingUrl: url,
          isDownloaded: true,
        );

        mediaItems.add(mediaItem);
      }

      _updateCanSubmit();
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error Loading Media',
        message: 'Failed to load existing media files.',
      );
    }
  }

  void _checkAllMediaProcessed() {
    final allProcessed = mediaItems.every((item) => !item.isProcessing);
    if (allProcessed) {
      isProcessingMedia.value = false;
    }
    _updateCanSubmit();
  }

  void _cleanupTempFiles() {
    for (final item in mediaItems) {
      try {
        item.thumbnail?.deleteSync();
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }

  /// Check if user has unsaved changes
  Future<bool> checkUnsavedChanges() async {
    if (_hasUnsavedChanges) {
      return await TDialog.keepWriting(
        title: 'Discard Changes?',
        message: 'You have unsaved changes. Are you sure you want to leave? Your content will be lost.',
      );
    }
    return true;
  }

  /// Show post type bottom sheet
  void showPostTypeSelector() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Select Post Type',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...postTypes.map((type) => Obx(() => ListTile(
              title: Text(
                type,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selectedPostType.value == type
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
              leading: Radio<String>(
                value: type,
                groupValue: selectedPostType.value,
                onChanged: (value) {
                  if (value != null) {
                    selectedPostType.value = value;
                    _checkForChanges();
                    Get.back();
                  }
                },
              ),
              onTap: () {
                selectedPostType.value = type;
                _checkForChanges();
                Get.back();
              },
            ))).toList(),
            SizedBox(height: 20),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  /// Add media from camera
  Future<void> addMediaFromCamera({required bool isVideo}) async {
    if (mediaItems.length >= maxMediaCount) {
      TLoaders.warningSnackBar(
        title: 'Media Limit Reached',
        message: 'You can only add up to $maxMediaCount media files.',
      );
      return;
    }

    try {
      final File? file;

      if (isVideo) {
        file = await VideoHelper.recordVideo();
      } else {
        file = await ImageHelper.takePhoto();
      }

      if (file != null) {
        final validationError = await MediaUtils.validateMediaFile(file);
        if (validationError != null) {
          TLoaders.errorSnackBar(
            title: 'File Error',
            message: validationError,
          );

          try {
            await file.delete();
          } catch (e) {
            // Ignore cleanup error
          }
          return;
        }

        await _processMediaFile(file);
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to capture ${isVideo ? 'video' : 'image'}. Please try again.',
      );
    }
  }

  /// Add media from gallery
  Future<void> addMediaFromGallery() async {
    if (mediaItems.length >= maxMediaCount) {
      TLoaders.warningSnackBar(
        title: 'Media Limit Reached',
        message: 'You can only add up to $maxMediaCount media files.',
      );
      return;
    }

    try {
      final availableSlots = maxMediaCount - mediaItems.length;

      final List<File> files = await ImageHelper.pickMultipleMedia(
        limit: availableSlots,
      );

      if (files.isEmpty) return;

      int successCount = 0;
      int invalidCount = 0;
      int skippedDueToLimit = 0;
      List<String> invalidFileNames = [];

      for (final file in files) {
        if (mediaItems.length >= maxMediaCount) {
          skippedDueToLimit = files.length - files.indexOf(file);
          break;
        }

        final validationError = await MediaUtils.validateMediaFile(file);

        if (validationError != null) {
          invalidCount++;
          final fileName = path.basename(file.path);
          invalidFileNames.add(fileName);
          continue;
        }

        try {
          await _processMediaFile(file);
          successCount++;
        } catch (e) {
          invalidCount++;
          invalidFileNames.add(path.basename(file.path));
        }
      }

      _showMediaAdditionResult(
        successCount: successCount,
        invalidCount: invalidCount,
        skippedDueToLimit: skippedDueToLimit,
        invalidFileNames: invalidFileNames,
      );

    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to select media files. Please try again.',
      );
    }
  }

  void _showMediaAdditionResult({
    required int successCount,
    required int invalidCount,
    required int skippedDueToLimit,
    required List<String> invalidFileNames,
  }) {
    if (successCount == 0 && invalidCount == 0 && skippedDueToLimit == 0) {
      return;
    }

    if (successCount == 0 && invalidCount > 0 && skippedDueToLimit == 0) {
      String message;
      if (invalidCount == 1) {
        message = 'The selected file has an invalid format: ${invalidFileNames.first}';
      } else if (invalidCount <= 3) {
        message = 'Invalid files: ${invalidFileNames.join(', ')}';
      } else {
        message = '$invalidCount files have invalid formats. Only images (max 5MB) and videos (max 20MB) are allowed.';
      }

      TLoaders.warningSnackBar(
        title: 'Invalid Files',
        message: message,
      );
      return;
    }

    if (successCount > 0 && (invalidCount > 0 || skippedDueToLimit > 0)) {
      List<String> messageParts = [];
      messageParts.add('$successCount file(s) added');

      if (invalidCount > 0) {
        if (invalidCount == 1) {
          messageParts.add('1 file skipped (invalid format)');
        } else {
          messageParts.add('$invalidCount files skipped (invalid format)');
        }
      }

      if (skippedDueToLimit > 0) {
        messageParts.add('$skippedDueToLimit file(s) skipped (limit reached)');
      }

      TLoaders.warningSnackBar(
        title: 'Partial Success',
        message: messageParts.join(', ') + '.',
      );
      return;
    }

    if (successCount > 0 && skippedDueToLimit > 0 && invalidCount == 0) {
      TLoaders.warningSnackBar(
        title: 'Media Limit',
        message: '$successCount file(s) added. $skippedDueToLimit file(s) skipped due to $maxMediaCount files limit.',
      );
      return;
    }

    if (successCount > 0 && invalidCount == 0 && skippedDueToLimit == 0) {
      TLoaders.successSnackBar(
        title: 'Success',
        message: '$successCount file(s) added successfully.',
      );
      return;
    }

    if (successCount == 0 && skippedDueToLimit > 0) {
      TLoaders.warningSnackBar(
        title: 'Media Limit Reached',
        message: 'Cannot add more files. Maximum $maxMediaCount files per post.',
      );
    }
  }

  /// Process media file
  Future<void> _processMediaFile(File file) async {
    if (mediaItems.length >= maxMediaCount) {
      TLoaders.warningSnackBar(
        title: 'Media Limit Reached',
        message: 'Maximum $maxMediaCount files allowed.',
      );
      return;
    }

    final mediaId = Uuid().v4();
    final mediaType = MediaUtils.getMediaType(file.path);

    if (mediaType == 'unknown') {
      TLoaders.errorSnackBar(
        title: 'Invalid File',
        message: 'Please select only image or video files.',
      );
      return;
    }

    final validationError = await MediaUtils.validateMediaFile(file);
    if (validationError != null) {
      TLoaders.errorSnackBar(
        title: 'File Error',
        message: validationError,
      );
      return;
    }

    final processingItem = PostMediaItem(
      id: mediaId,
      file: file,
      type: mediaType,
      isProcessing: true,
    );
    mediaItems.add(processingItem);
    _hasUnsavedChanges = true;
    _checkForChanges();
    _updateCanSubmit();

    try {
      isProcessingMedia.value = true;

      File? processedFile;
      File? thumbnail;
      Duration? duration;

      if (mediaType == 'image') {
        processedFile = await ImageHelper.compressImageToWebP(file);
      } else if (mediaType == 'video') {
        processedFile = await VideoHelper.compressVideoToMP4(file);
        if (processedFile != null) {
          thumbnail = await VideoHelper.getVideoThumbnailFile(processedFile);
          duration = await VideoHelper.getVideoDuration(processedFile);

          if (thumbnail == null) {
            print('Primary thumbnail generation failed, trying alternative method');
          }
        }
      }

      if (processedFile != null) {
        final index = mediaItems.indexWhere((item) => item.id == mediaId);
        if (index != -1) {
          mediaItems[index] = processingItem.copyWith(
            file: processedFile,
            thumbnail: thumbnail,
            duration: duration,
            isProcessing: false,
          );
        }
      } else {
        throw Exception('Failed to process $mediaType');
      }
    } catch (e) {
      final index = mediaItems.indexWhere((item) => item.id == mediaId);
      if (index != -1) {
        mediaItems[index] = processingItem.copyWith(
          isProcessing: false,
          error: 'Failed to process $mediaType: ${e.toString()}',
        );
      }
    } finally {
      _checkAllMediaProcessed();
    }
  }

  /// Remove media item
  void removeMediaItem(String mediaId) {
    final index = mediaItems.indexWhere((item) => item.id == mediaId);
    if (index != -1) {
      final item = mediaItems[index];
      try {
        item.thumbnail?.deleteSync();
      } catch (e) {
        // Ignore cleanup errors
      }

      mediaItems.removeAt(index);
      _hasUnsavedChanges = contentController.text.trim().isNotEmpty || mediaItems.isNotEmpty;
      _checkForChanges();
      _updateCanSubmit();
    }
  }

  /// Open media preview
  void openMediaPreview(int initialIndex) {
    if (mediaItems.isEmpty || initialIndex < 0 || initialIndex >= mediaItems.length) {
      return;
    }

    Get.to(
          () => MediaPreviewScreen(
        mediaItems: mediaItems.toList(),
        initialIndex: initialIndex,
        onDeleteMedia: removeMediaItem,
      ),
      transition: Transition.fadeIn,
      duration: Duration(milliseconds: 300),
    );
  }

  /// Show media options bottom sheet
  void showMediaOptions() {
    MediaPicker.showMediaOptions(
      context: Get.context!,
      title: 'Add Media',
    ).then((option) {
      if (option != null) {
        switch (option.type) {
          case MediaOptionType.gallery:
            addMediaFromGallery();
            break;
          case MediaOptionType.camera:
            addMediaFromCamera(isVideo: false);
            break;
          case MediaOptionType.video:
            addMediaFromCamera(isVideo: true);
            break;
        }
      }
    });
  }

  /// Create post
  Future<void> createPost() async {
    final contentError = CommunityValidator.validatePostContent(contentController.text);
    if (contentError != null) {
      TLoaders.errorSnackBar(
        title: 'Invalid Content',
        message: contentError,
      );
      return;
    }

    final typeError = CommunityValidator.validatePostType(selectedPostType.value);
    if (typeError != null) {
      TLoaders.errorSnackBar(
        title: 'Invalid Post Type',
        message: typeError,
      );
      return;
    }

    final content = contentController.text.trim();

    if (mediaItems.length > maxMediaCount) {
      TLoaders.errorSnackBar(
        title: 'Too Many Media Files',
        message: 'Maximum $maxMediaCount files allowed. Please remove ${mediaItems.length - maxMediaCount} file(s).',
      );
      return;
    }

    if (mediaItems.any((item) => item.isProcessing)) {
      TLoaders.warningSnackBar(
        title: 'Processing Media',
        message: 'Please wait for media processing to complete.',
      );
      return;
    }

    if (mediaItems.any((item) => item.hasError)) {
      TLoaders.warningSnackBar(
        title: 'Media Error',
        message: 'Please remove media files with errors before posting.',
      );
      return;
    }

    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: TTexts.networkErrorMessage,
      );
      return;
    }

    try {
      isCreatingPost.value = true;
      _updateCanSubmit();

      final postType = PostType.fromDisplayName(selectedPostType.value);

      final mediaFiles = mediaItems
          .where((item) => item.isReady && item.file != null)
          .take(maxMediaCount)
          .map((item) => item.file!)
          .toList();

      await _postRepo.createPost(
        content: content,
        postType: postType,
        mediaFiles: mediaFiles.isNotEmpty ? mediaFiles : null,
      );

      contentController.clear();
      mediaItems.clear();
      selectedPostType.value = 'General Discussion';
      _hasUnsavedChanges = false;

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Post created successfully!',
      );

      if (Get.isRegistered<PostController>()) {
        await PostController.instance.refreshPosts();
      }

      if (Get.context != null) {
        Navigator.of(Get.context!, rootNavigator: true).pop(true);
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: e.toString(),
      );
    } finally {
      isCreatingPost.value = false;
      _updateCanSubmit();
    }
  }

  /// Update existing post
  Future<void> updatePost() async {
    final contentError = CommunityValidator.validatePostContent(contentController.text);
    if (contentError != null) {
      TLoaders.errorSnackBar(
        title: 'Invalid Content',
        message: contentError,
      );
      return;
    }

    final typeError = CommunityValidator.validatePostType(selectedPostType.value);
    if (typeError != null) {
      TLoaders.errorSnackBar(
        title: 'Invalid Post Type',
        message: typeError,
      );
      return;
    }

    final content = contentController.text.trim();

    if (mediaItems.length > maxMediaCount) {
      TLoaders.errorSnackBar(
        title: 'Too Many Media Files',
        message: 'Maximum $maxMediaCount files allowed. Please remove ${mediaItems.length - maxMediaCount} file(s).',
      );
      return;
    }

    if (editingPostId == null) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Post ID is missing for editing.',
      );
      return;
    }

    if (mediaItems.any((item) => item.isProcessing)) {
      TLoaders.warningSnackBar(
        title: 'Processing Media',
        message: 'Please wait for media processing to complete.',
      );
      return;
    }

    if (mediaItems.any((item) => item.hasError)) {
      TLoaders.warningSnackBar(
        title: 'Media Error',
        message: 'Please remove media files with errors before updating.',
      );
      return;
    }

    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: TTexts.networkErrorMessage,
      );
      return;
    }

    try {
      isCreatingPost.value = true;
      _updateCanSubmit();

      final postType = PostType.fromDisplayName(selectedPostType.value);

      final existingMediaUrls = mediaItems
          .where((item) => item.existingUrl != null)
          .map((item) => item.existingUrl!)
          .toList();

      final newMediaFiles = mediaItems
          .where((item) => item.existingUrl == null && item.isReady && item.file != null)
          .map((item) => item.file!)
          .toList();

      await _postRepo.updatePostWithMedia(
        postId: editingPostId!,
        content: content,
        postType: postType.name,
        newMediaFiles: newMediaFiles.isNotEmpty ? newMediaFiles : null,
        existingMediaUrls: existingMediaUrls,
      );

      // If post was disabled before editing, enable it after successful update
      if (wasDisabledBeforeEdit) {
        try {
          await _postRepo.enablePostAfterEdit(editingPostId!);
          print('✅ Post automatically enabled after edit');
        } catch (e) {
          print('⚠️ Failed to auto-enable post: $e');
          // Don't fail the entire operation if auto-enable fails
        }
      }

      contentController.clear();
      mediaItems.clear();
      selectedPostType.value = 'General Discussion';
      _hasUnsavedChanges = false;
      isEditingMode.value = false;
      editingPostId = null;
      wasDisabledBeforeEdit = false;

      TLoaders.successSnackBar(
        title: 'Success',
        message: wasDisabledBeforeEdit
            ? 'Post updated and enabled successfully!'
            : 'Post updated successfully!',
      );

      if (Get.isRegistered<PostController>()) {
        await PostController.instance.refreshPosts();
      }

      if (Get.context != null) {
        Navigator.of(Get.context!, rootNavigator: true).pop(true);
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: e.toString(),
      );
    } finally {
      isCreatingPost.value = false;
      _updateCanSubmit();
    }
  }

  /// Submit post (create or update based on mode)
  Future<void> submitPost() async {
    if (isEditingMode.value) {
      await updatePost();
    } else {
      await createPost();
    }
  }

  /// Reset editing state when leaving the screen
  void resetEditingState() {
    if (isEditingMode.value) {
      _originalContent = '';
      _originalPostType = 'General Discussion';
      _originalMediaUrls.clear();
      isEditingMode.value = false;
      editingPostId = null;
      wasDisabledBeforeEdit = false;
      hasChanges.value = false;
    }
  }

  /// Check if form is valid for submission (kept for backward compatibility)
  bool get canSubmitPost => canSubmit.value;

  /// Check if user is currently uploading/processing
  bool get isUploading => isCreatingPost.value;

  /// Get remaining media slots
  int get remainingMediaSlots => maxMediaCount - mediaItems.length;

  /// Check if can add more media
  bool get canAddMoreMedia => remainingMediaSlots > 0;

  /// Get ready media items count
  int get readyMediaCount => mediaItems.where((item) => item.isReady).length;

  /// Get processing media items count
  int get processingMediaCount => mediaItems.where((item) => item.isProcessing).length;

  /// Get error media items count
  int get errorMediaCount => mediaItems.where((item) => item.hasError).length;
}