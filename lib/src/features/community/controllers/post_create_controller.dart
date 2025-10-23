import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../utils/constants/enums.dart';
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

class PostCreateController extends GetxController {
  static PostCreateController get instance => Get.find();

  // Form controllers
  final contentController = TextEditingController();

  // Observables
  final selectedPostType = 'General Discussion'.obs;
  final mediaItems = <PostMediaItem>[].obs;
  final isCreatingPost = false.obs;
  final isProcessingMedia = false.obs;

  // Editing state
  final isEditingMode = false.obs;
  String? editingPostId;

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
    _hasUnsavedChanges = contentController.text
        .trim()
        .isNotEmpty || mediaItems.isNotEmpty;
  }

  /// Initialize controller for editing existing post
  void initializeForEditing(PostModel post) {
    isEditingMode.value = true;
    editingPostId = post.postId;

    // Set content
    contentController.text = post.postContent;

    // Set post type
    selectedPostType.value = post.postType.displayName;

    // Load existing media (create PostMediaItem from URLs)
    for (String url in post.mediaUrls) {
      final mediaId = const Uuid().v4();
      final mediaType = url.toLowerCase().contains('videos') ? 'video' : 'image';

      // Create a media item with the URL
      // Note: We don't have the actual file, so we'll use the URL
      mediaItems.add(PostMediaItem(
        id: mediaId,
        file: File(''), // Empty file as placeholder
        type: mediaType,
        isProcessing: false,
        existingUrl: url, // Store the existing URL
      ));
    }

    _hasUnsavedChanges = false;
  }

  void _cleanupTempFiles() {
    // Clean up any temporary files
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
            // Handle bar
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

            // Title
            Text(
              'Select Post Type',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),

            // Post type options
            ...postTypes.map((type) =>
                Obx(() =>
                    ListTile(
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
                            Get.back();
                          }
                        },
                      ),
                      onTap: () {
                        selectedPostType.value = type;
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
        await _processMediaFile(file);
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to capture ${isVideo
            ? 'video'
            : 'image'}. Please try again.',
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
      final List<File> files = await ImageHelper.pickMultipleMedia(
        limit: maxMediaCount - mediaItems.length,
      );

      if (files.isNotEmpty) {
        for (final file in files) {
          await _processMediaFile(file);
        }
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to select media files. Please try again.',
      );
    }
  }

  /// Process media file
  Future<void> _processMediaFile(File file) async {
    final mediaId = Uuid().v4();
    final mediaType = _getMediaType(file.path);

    if (mediaType == 'unknown') {
      TLoaders.errorSnackBar(
        title: 'Invalid File',
        message: 'Please select only image or video files.',
      );
      return;
    }

    // Validate file
    final validationError = await _validateMediaFile(file);
    if (validationError != null) {
      TLoaders.errorSnackBar(
        title: 'File Error',
        message: validationError,
      );
      return;
    }

    // Add processing item
    final processingItem = PostMediaItem(
      id: mediaId,
      file: file,
      type: mediaType,
      isProcessing: true,
    );
    mediaItems.add(processingItem);
    _hasUnsavedChanges = true;

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
          thumbnail = await VideoHelper.getVideoThumbnail(processedFile);
          duration = await VideoHelper.getVideoDuration(processedFile);
        }
      }

      if (processedFile != null) {
        // Update with processed file
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
      // Update with error
      final index = mediaItems.indexWhere((item) => item.id == mediaId);
      if (index != -1) {
        mediaItems[index] = processingItem.copyWith(
          isProcessing: false,
          error: 'Failed to process $mediaType',
        );
      }
    } finally {
      isProcessingMedia.value = false;
    }
  }

  /// Get media type from file path
  String _getMediaType(String path) {
    final extension = path
        .toLowerCase()
        .split('.')
        .last;

    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'wmv', 'flv', '3gp'];

    if (imageExtensions.contains(extension)) {
      return 'image';
    } else if (videoExtensions.contains(extension)) {
      return 'video';
    }

    return 'unknown';
  }

  /// Validate media file
  Future<String?> _validateMediaFile(File file) async {
    try {
      final fileSizeBytes = await file.length();
      final fileSizeMB = fileSizeBytes / (1024 * 1024);

      final fileType = _getMediaType(file.path);

      // Check file size limits
      if (fileType == 'image' && fileSizeMB > 10) {
        return 'Image file size must be less than 10MB';
      }

      if (fileType == 'video' && fileSizeMB > 100) {
        return 'Video file size must be less than 100MB';
      }

      // Check if file exists and is readable
      if (!await file.exists()) {
        return 'File does not exist';
      }

      return null; // No errors
    } catch (e) {
      return 'Failed to validate file: ${e.toString()}';
    }
  }

  /// Remove media item
  void removeMediaItem(String mediaId) {
    final index = mediaItems.indexWhere((item) => item.id == mediaId);
    if (index != -1) {
      final item = mediaItems[index];
      // Clean up thumbnail file if it exists
      try {
        item.thumbnail?.deleteSync();
      } catch (e) {
        // Ignore cleanup errors
      }

      mediaItems.removeAt(index);
      _hasUnsavedChanges = contentController.text
          .trim()
          .isNotEmpty || mediaItems.isNotEmpty;
    }
  }

  /// Open media preview
  void openMediaPreview(int initialIndex) {
    if (mediaItems.isEmpty || initialIndex < 0 ||
        initialIndex >= mediaItems.length) {
      return;
    }

    Get.to(
          () =>
          MediaPreviewScreen(
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
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Title
            Text(
              'Add Media',
              style: Get.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),

            // Options
            _buildMediaOption(
              icon: Icons.photo_library,
              title: 'From Gallery',
              subtitle: 'Select photos and videos',
              onTap: () {
                Get.back();
                addMediaFromGallery();
              },
            ),

            _buildMediaOption(
              icon: Icons.camera_alt,
              title: 'Take Photo',
              subtitle: 'Capture with camera',
              onTap: () {
                Get.back();
                addMediaFromCamera(isVideo: false);
              },
            ),

            _buildMediaOption(
              icon: Icons.videocam,
              title: 'Record Video',
              subtitle: 'Capture video with camera',
              onTap: () {
                Get.back();
                addMediaFromCamera(isVideo: true);
              },
            ),

            SizedBox(height: 10),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  Widget _buildMediaOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Get.theme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Get.theme.primaryColor),
      ),
      title: Text(
        title,
        style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
      ),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 14)),
      onTap: onTap,
    );
  }

  /// Create post
  Future<void> createPost() async {
    final content = contentController.text.trim();

    if (content.isEmpty) {
      TLoaders.warningSnackBar(
        title: 'Content Required',
        message: 'Please enter some content for your post.',
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

      // Convert display post type to internal type
      final postType = PostType.fromDisplayName(selectedPostType.value);

      // Get ready media files
      final mediaFiles = mediaItems
          .where((item) => item.isReady)
          .map((item) => item.file)
          .toList();

      await _postRepo.createPost(
        content: content,
        postType: postType,
        mediaFiles: mediaFiles.isNotEmpty ? mediaFiles : null,
      );

      // Clear form
      contentController.clear();
      mediaItems.clear();
      selectedPostType.value = 'General Discussion';
      _hasUnsavedChanges = false;

      TLoaders.successSnackBar(
        title: 'Success',
        message: 'Post created successfully!',
      );

      Get.back(); // Return to previous screen
    } catch (e) {
      TLoaders.errorSnackBar(
        title: TTexts.error,
        message: e.toString(),
      );
    } finally {
      isCreatingPost.value = false;
    }
  }

  /// Get remaining media slots
  int get remainingMediaSlots => maxMediaCount - mediaItems.length;

  /// Check if can add more media
  bool get canAddMoreMedia => remainingMediaSlots > 0;

  /// Get ready media items count
  int get readyMediaCount =>
      mediaItems
          .where((item) => item.isReady)
          .length;

  /// Get processing media items count
  int get processingMediaCount =>
      mediaItems
          .where((item) => item.isProcessing)
          .length;

  /// Get error media items count
  int get errorMediaCount =>
      mediaItems
          .where((item) => item.hasError)
          .length;

  /// Check if form is valid for submission
  bool get canSubmitPost {
    return contentController.text
        .trim()
        .isNotEmpty &&
        !mediaItems.any((item) => item.isProcessing) &&
        !mediaItems.any((item) => item.hasError) &&
        !isCreatingPost.value;
  }
}