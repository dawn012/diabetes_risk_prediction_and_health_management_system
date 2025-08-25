import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../data/repositories/community/post_repository.dart';
import '../../../utils/constants/image_strings.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/image_helper.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/helpers/video_helper.dart';
import '../../../utils/popups/full_screen_loader.dart';
import '../views/posts/posts_screen.dart';

class PostCreateController extends GetxController {
  static PostCreateController get instance => Get.find();

  final postRepo = Get.put(PostRepository());

  final postTitle = TextEditingController();
  final postContent = TextEditingController();

  final selectedPostType = 'General Discussion'.obs;
  final postTypes = ['General Discussion', 'Tips & Tricks', 'Meal or Recipe', 'Success Story'].obs;

  var file = Rxn<File>();
  final fileType = 'image'.obs;
  final isLoading = false.obs;

  ///-- Select Image
  Future<void> pickImage() async {
    fileType.value = 'image';
    file.value = await ImageHelper.pickImage();
  }

  ///-- Select Video
  Future<void> pickVideo() async {
    fileType.value = 'video';
    file.value = await VideoHelper.pickVideo();
  }

  ///-- Make Post
  Future<void> makePost() async {
    if (file.value == null) return;

    isLoading.value = true;

    try {
      await postRepo.makePost(
        content: postContent.text,
        file: file.value!,
        postType: fileType.value,
      );

      Get.off(() => PostsScreen());
    } catch (e) {
      // Show some generic error to the user
      TLoaders.errorSnackBar(title: TTexts.error, message: e.toString());
    } finally {
      isLoading.value = false;
    }
  }

  ///-- Make Post
  Future<void> makePost2() async {
    if (file.value == null) return;

    try {
      // Start Loading
      TFullScreenLoader.openLoadingDialog(
          'We are processing your community...', TImages.loadingAnimation);

      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        // Remove loader
        TFullScreenLoader.stopLoading();
        return;
      }

      // Save the community in the db
      await postRepo.makePost(
        content: postContent.text,
        file: file.value!,
        postType: fileType.value,
      );

      // Remove loader
      TFullScreenLoader.stopLoading();

      // Show Success Message
      TLoaders.successSnackBar(title: TTexts.congratulations, message: TTexts.postSuccessMessage);

      // Back to previous page
      Get.off(() => PostsScreen());
    } catch (e) {
      // Remove loader
      TFullScreenLoader.stopLoading();
      // Show some generic error to the user
      TLoaders.errorSnackBar(title: TTexts.error, message: e.toString());
    }
  }
}