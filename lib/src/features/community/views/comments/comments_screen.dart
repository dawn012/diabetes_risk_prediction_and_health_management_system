import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/appbar/appbar.dart';
import '../../../../utils/constants/colors.dart';
import '../../../../utils/constants/text_strings.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../controllers/comment_controller.dart';
import 'widgets/comment_text_field.dart';
import 'widgets/comments_list.dart';

class CommentsScreen extends StatelessWidget {
  const CommentsScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommentController(postId: postId));
    final isDark = THelperFunctions.isDarkMode(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        controller.handleNavigation(() => Get.back());
      },
      child: Scaffold(
        backgroundColor: isDark ? TColors.dark : TColors.primaryBackground,

        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Obx(() {
            final isEditing = controller.isEditing;

            return Stack(
              children: [
                // Dark overlay when editing
                if (isEditing)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    height: kToolbarHeight + MediaQuery.of(context).padding.top,
                  ),

                // App bar
                TAppBar(
                  title: Text(
                    "${TTexts.comment}s",
                    style: TextStyle(
                      color: isEditing ? Colors.white : null,
                    ),
                  ),
                  showBackArrow: true,
                  backgroundColor: isEditing ? Colors.transparent : null,
                  iconTheme: IconThemeData(
                    color: isEditing ? Colors.white : null,
                  ),
                  actions: [
                    // Sort menu
                    PopupMenuButton<String>(
                      icon: Icon(
                        Icons.sort,
                        color: isEditing ? Colors.white : (isDark ? TColors.lightGrey : TColors.textPrimary),
                      ),
                      offset: const Offset(-15, 40),
                      onSelected: (String value) {
                        controller.sortComments(value);
                      },
                      itemBuilder: (BuildContext context) => [
                        _buildSortMenuItem(
                          context: context,
                          value: 'newest',
                          label: 'Newest First',
                          isSelected: controller.currentSort.value == 'newest',
                          isDark: isDark,
                        ),
                        _buildSortMenuItem(
                          context: context,
                          value: 'top',
                          label: 'Top Comments',
                          isSelected: controller.currentSort.value == 'top',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          }),
        ),

        body: Stack(
          children: [
            // Main content
            Column(
              children: [
                const Expanded(child: CommentsList()),
              ],
            ),

            // Dark overlay when editing (excludes text field area)
            Obx(() {
              final isEditing = controller.isEditing;
              return isEditing
                  ? Positioned.fill(
                child: GestureDetector(
                  onTap: () => controller.cancelEdit(),
                  child: Container(
                    color: Colors.black.withOpacity(0.5),
                    margin: const EdgeInsets.only(bottom: 80), // Leave space for text field
                  ),
                ),
              )
                  : const SizedBox.shrink();
            }),

            // Bottom text field
            const Align(
              alignment: Alignment.bottomCenter,
              child: CommentTextField(),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _buildSortMenuItem({
    required BuildContext context,
    required String value,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    return PopupMenuItem(
      value: value,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? TColors.primary.withOpacity(0.2) : TColors.primary.withOpacity(0.1))
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? TColors.primary
                      : (isDark ? TColors.lightGrey : TColors.textPrimary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check,
                color: TColors.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}