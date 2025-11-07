import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/sizes.dart';
import '../../../utils/helpers/helper_functions.dart';
import '../controllers/community_menu_controller.dart';
import '../controllers/post_controller.dart';
import 'my_posts/my_posts_screen.dart';
import 'posts/posts_screen.dart';

class CommunityMenu extends StatelessWidget {
  const CommunityMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommunityController());
    final postController = Get.put(PostController());
    final isDark = THelperFunctions.isDarkMode(context);

    return Scaffold(
      backgroundColor: isDark ? TColors.dark : TColors.primaryBackground,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? TColors.darkContainer : TColors.white,
        title: Row(
          children: [
            // App icon with gradient background
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [TColors.primary, TColors.primary.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.groups_rounded,
                color: TColors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: TSizes.md),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: isDark ? TColors.white : TColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Connect & Share',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark ? TColors.lightGrey : TColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Spacer(),
            // My Posts button
            IconButton(
              onPressed: () => Get.to(() => const MyPostsScreen()),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: TColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: TColors.primary.withOpacity(0.3),
                  ),
                ),
                child: Icon(
                  Icons.person_outline,
                  color: TColors.primary,
                  size: 20,
                ),
              ),
              tooltip: 'My Posts',
            ),
          ],
        ),
      ),
      body: const PostsScreen(),
    );
  }
}