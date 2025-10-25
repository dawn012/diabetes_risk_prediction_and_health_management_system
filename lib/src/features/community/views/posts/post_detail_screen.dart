import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/loaders/circular_loader.dart';
import '../../../../common/widgets/error_screen/error_retry_screen.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/sizes.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/post_controller.dart';
import '../../models/post_model.dart';
import '../posts/widgets/post_tile.dart';

class PostDetailScreen extends StatefulWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  final postController = Get.put(PostController());
  PostModel? post;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPost();
  }

  Future<void> _loadPost() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 首先尝试从缓存中获取
      final cachedPost = postController.getPostById(widget.postId);

      if (cachedPost != null) {
        setState(() {
          post = cachedPost;
          isLoading = false;
        });
      } else {
        // 如果缓存中没有，从仓库获取
        final fetchedPost = await postController.postRepo.getPost(widget.postId);

        if (fetchedPost != null) {
          setState(() {
            post = fetchedPost;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = 'Post not found';
            isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load post: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.primaryBackground,
      appBar: AppBar(
        title: Text(
          'Post Details',
          style: TextStyle(
            color: isDark ? TColors.white : TColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: isDark ? TColors.darkContainer : TColors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? TColors.white : TColors.textPrimary,
          ),
          onPressed: () => Get.back(),
        ),
      ),
      body: _buildBody(isDark),
    );
  }

  Widget _buildBody(bool isDark) {
    if (isLoading) {
      return const Center(child: CircularLoader());
    }

    if (errorMessage != null) {
      return Center(
        child: ErrorRetryScreen(
          message: errorMessage!,
          onRetry: _loadPost,
        ),
      );
    }

    if (post == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.post_add_outlined,
              size: 64,
              color: isDark ? TColors.darkGrey : TColors.grey,
            ),
            const SizedBox(height: TSizes.md),
            Text(
              'Post Not Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isDark ? TColors.lightGrey : TColors.textSecondary,
              ),
            ),
            const SizedBox(height: TSizes.sm),
            Text(
              'This post may have been deleted or is no longer available.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isDark ? TColors.darkGrey : TColors.textSecondary,
              ),
            ),
            const SizedBox(height: TSizes.lg),
            ElevatedButton(
              onPressed: () => Get.back(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPost,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            const SizedBox(height: TSizes.sm),
            // 显示帖子
            PostTile(post: post!, isInMyPosts: false,),
            const SizedBox(height: TSizes.md),

            // 可以在这里添加评论区
            // CommentsSection(postId: widget.postId),
          ],
        ),
      ),
    );
  }
}