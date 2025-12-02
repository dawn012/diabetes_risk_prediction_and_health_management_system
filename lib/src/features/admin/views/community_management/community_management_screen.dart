import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../common/widgets/dialogs/common_confirmation_dialog.dart';
import '../../../../common/widgets/dialogs/media_lightbox.dart';
import '../../../../common/widgets/pagination/pagination_widget.dart';
import '../../../../common/widgets/table/reusable_data_table.dart';
import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/constants/enums.dart';
import '../../../../utils/formatters/formatter.dart';
import '../../../../utils/helpers/helper_functions.dart';
import '../../../community/models/post_model.dart';
import '../../controllers/community_management_controller.dart';
import 'post_detail_dialog.dart';
import 'post_report_dialog.dart';
import 'widgets/community_batch_action_bar.dart';
import 'widgets/community_management_header.dart';

class CommunityManagementScreen extends StatelessWidget {
  const CommunityManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommunityManagementController());
    final darkMode = THelperFunctions.isDarkMode(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final headerHeight = 200.0;
            final bannerHeight = 60.0;
            final batchActionsHeight = 60.0;
            final paginationHeight = 80.0;
            final padding = 48.0;
            final availableTableHeight = constraints.maxHeight -
                headerHeight - bannerHeight - batchActionsHeight - paginationHeight - padding;

            return SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CommunityManagementHeader(controller: controller),
                    const SizedBox(height: 16),

                    Obx(() {
                      return controller.newPostsCount.value > 0
                          ? Column(
                        children: [
                          _buildNewPostsBanner(controller, darkMode),
                          const SizedBox(height: 16),
                        ],
                      )
                          : const SizedBox.shrink();
                    }),

                    Obx(() {
                      return controller.selectedPosts.isNotEmpty
                          ? Column(
                        children: [
                          CommunityBatchActionsBar(controller: controller),
                          const SizedBox(height: 16),
                        ],
                      )
                          : const SizedBox.shrink();
                    }),

                    Container(
                      height: availableTableHeight.clamp(400.0, double.infinity),
                      decoration: BoxDecoration(
                        color: TAdminColors.getSurfaceColor(darkMode),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: darkMode ? Colors.black26 : Colors.grey.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Obx(() {
                              return ReusableDataTable<PostModel>(
                                data: controller.displayedPosts,
                                columns: _getPostTableColumns(controller, darkMode),
                                isLoading: controller.isLoading.value,
                                onSelectAll: (selected) => controller.toggleSelectAll(selected),
                                selectedItems: controller.selectedPosts,
                                onItemSelect: (post, selected) => controller.togglePostSelection(post, selected),
                                searchQuery: controller.searchController.text,
                                sortColumnIndex: controller.sortColumnIndex.value,
                                sortAscending: controller.sortAscending.value,
                                onSort: (columnIndex, ascending) => controller.sortPosts(columnIndex, ascending),
                              );
                            }),
                          ),

                          Obx(() => PaginationWidget(
                            currentPage: controller.currentPage.value,
                            totalPages: controller.totalPages.value,
                            onPageChanged: controller.changePage,
                            totalItems: controller.totalCount.value,
                            itemsPerPage: controller.itemsPerPage.value,
                            startIndex: ((controller.currentPage.value - 1) * controller.itemsPerPage.value) + 1,
                            endIndex: (controller.currentPage.value * controller.itemsPerPage.value).clamp(0, controller.totalCount.value),
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNewPostsBanner(CommunityManagementController controller, bool darkMode) {
    return Obx(() {
      final count = controller.newPostsCount.value;
      if (count == 0) return const SizedBox.shrink();

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => controller.refreshPosts(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    TAdminColors.info,
                    TAdminColors.info.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: TAdminColors.info.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.8 + (value * 0.2),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.notification_bing_bold,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 16),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New Posts Available',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$count new post${count > 1 ? 's' : ''} ${count > 1 ? 'have' : 'has'} been published',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Iconsax.refresh_bold,
                          color: TAdminColors.info,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Refresh',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: TAdminColors.info,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  List<DataTableColumn<PostModel>> _getPostTableColumns(CommunityManagementController controller, bool darkMode) {
    return [
      DataTableColumn<PostModel>(
        label: 'Post ID',
        field: 'postId',
        minWidth: 100,
        flex: 2,
        sortable: true,
        builder: (post) {
          final query = controller.searchController.text;
          return RichText(
            text: TextSpan(
              children: controller.getHighlightedText(post.postId, query),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
            ),
          );
        },
      ),
      DataTableColumn<PostModel>(
        label: 'Poster',
        field: 'poster',
        minWidth: 140,
        flex: 3,
        sortable: true,
        builder: (post) {
          final poster = controller.posterData[post.posterId];
          final query = controller.searchController.text;

          return Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundImage: poster?.profileImg != null && poster!.profileImg.isNotEmpty
                    ? NetworkImage(poster.profileImg)
                    : null,
                backgroundColor: TAdminColors.primary.withOpacity(0.2),
                child: poster?.profileImg == null || poster!.profileImg.isEmpty
                    ? Icon(Iconsax.user_bold, size: 14, color: TAdminColors.primary)
                    : null,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: controller.getHighlightedText(
                          poster?.username ?? 'Unknown User',
                          query,
                          textColor: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: TAdminColors.getOnSurfaceColor(darkMode),
                        ),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (poster != null)
                      Text(
                        poster.email,
                        style: TextStyle(
                          fontSize: 10,
                          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      DataTableColumn<PostModel>(
        label: 'Type',
        field: 'postType',
        minWidth: 140,
        flex: 3,
        sortable: true,
        builder: (post) => _buildTypeChip(post.postType, darkMode),
      ),
      DataTableColumn<PostModel>(
        label: 'Media',
        field: 'mediaCount',
        minWidth: 80,
        flex: 2,
        sortable: true,
        builder: (post) => _buildMediaButton(post, controller, darkMode),
      ),
      DataTableColumn<PostModel>(
        label: 'Likes',
        field: 'likes',
        minWidth: 60,
        flex: 2,
        sortable: true,
        builder: (post) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.heart_bold,
              size: 14,
              color: TAdminColors.error.withOpacity(0.7),
            ),
            SizedBox(width: 4),
            Text(
              '${post.likes.length}',
              style: TextStyle(
                color: TAdminColors.getOnSurfaceColor(darkMode),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      DataTableColumn<PostModel>(
        label: 'Created/Updated',
        field: 'updatedAt',
        minWidth: 140,
        flex: 2,
        sortable: true,
        builder: (post) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${post.updatedAt.day}/${post.updatedAt.month}/${post.updatedAt.year}',
              style: TextStyle(
                fontSize: 12,
                color: TAdminColors.getOnSurfaceColor(darkMode),
              ),
            ),
            Text(
              TFormatter.formatElapsedTime(post.updatedAt),
              style: TextStyle(
                fontSize: 10,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
              ),
            ),
          ],
        ),
      ),
      DataTableColumn<PostModel>(
        label: 'Reports',
        field: 'pendingReportCount',
        minWidth: 110,
        flex: 2,
        sortable: true,
        builder: (post) => _buildReportsIndicator(post, controller, darkMode),
      ),
      // DataTableColumn<PostModel>(
      //   label: 'Status',
      //   field: 'status',
      //   minWidth: 85,
      //   flex: 2,
      //   sortable: true,
      //   builder: (post) => _buildStatusChip(post, darkMode),
      // ),
      DataTableColumn<PostModel>(
        label: 'Actions',
        field: 'actions',
        minWidth: 120,
        flex: 2,
        sortable: false,
        builder: (post) => _buildActionButtons(post, controller, darkMode),
      ),
    ];
  }

  Widget _buildMediaButton(PostModel post, CommunityManagementController controller, bool darkMode) {
    if (post.mediaUrls.isEmpty) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Iconsax.document_bold,
            size: 14,
            color: TAdminColors.getOnSurfaceVariantColor(darkMode).withOpacity(0.5),
          ),
          SizedBox(width: 4),
          Text(
            '0',
            style: TextStyle(
              color: TAdminColors.getOnSurfaceVariantColor(darkMode).withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    List<String> imageTypes = [];
    List<String> videoTypes = [];
    List<String> textTypes = [];

    for (String mediaFile in post.mediaUrls) {
      if (mediaFile.startsWith('text:')) {
        textTypes.add(mediaFile);
      } else if (mediaFile.contains('.mp4') || mediaFile.contains('video')) {
        videoTypes.add(mediaFile);
      } else {
        imageTypes.add(mediaFile);
      }
    }

    return InkWell(
      onTap: () => _showMediaLightbox(post),
      borderRadius: BorderRadius.circular(8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 120),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: TAdminColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: TAdminColors.primary.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageTypes.isNotEmpty) ...[
                  Icon(
                    Iconsax.gallery_bold,
                    size: 12,
                    color: TAdminColors.primary,
                  ),
                  if (imageTypes.length > 1 || videoTypes.isNotEmpty || textTypes.isNotEmpty) SizedBox(width: 2),
                ],
                if (videoTypes.isNotEmpty) ...[
                  Icon(
                    Iconsax.video_bold,
                    size: 12,
                    color: TAdminColors.primary,
                  ),
                  if (videoTypes.length > 1 || textTypes.isNotEmpty) SizedBox(width: 2),
                ],
                if (textTypes.isNotEmpty) ...[
                  Icon(
                    Iconsax.document_text_bold,
                    size: 12,
                    color: TAdminColors.primary,
                  ),
                ],
                SizedBox(width: 4),
                Text(
                  '${post.mediaUrls.length}',
                  style: TextStyle(
                    color: TAdminColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMediaLightbox(PostModel post) {
    List<MediaItem> mediaItems = [];

    for (String mediaFile in post.mediaUrls) {
      if (mediaFile.startsWith('text:')) {
        mediaItems.add(MediaItem(
          type: 'text',
          content: mediaFile.substring(5),
        ));
      } else if (mediaFile.contains('.mp4') || mediaFile.contains('video')) {
        mediaItems.add(MediaItem(
          type: 'video',
          url: mediaFile,
          thumbnail: mediaFile,
        ));
      } else {
        mediaItems.add(MediaItem(
          type: 'image',
          url: mediaFile,
          thumbnail: mediaFile,
        ));
      }
    }

    if (mediaItems.isNotEmpty) {
      showMediaLightbox(mediaItems);
    }
  }

  Widget _buildTypeChip(PostType postType, bool darkMode) {
    Color chipColor;
    IconData chipIcon;

    switch (postType) {
      case PostType.general:
        chipColor = TAdminColors.info;
        chipIcon = Iconsax.messages_1_bold;
        break;
      case PostType.tips:
        chipColor = TAdminColors.warning;
        chipIcon = Iconsax.lamp_bold;
        break;
      case PostType.recipe:
        chipColor = TAdminColors.success;
        chipIcon = Iconsax.cake_bold;
        break;
      case PostType.story:
        chipColor = TAdminColors.secondary;
        chipIcon = Iconsax.book_1_bold;
        break;
      default:
        chipColor = TAdminColors.getOnSurfaceVariantColor(darkMode);
        chipIcon = Iconsax.document_bold;
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 150),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: chipColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: chipColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                chipIcon,
                size: 12,
                color: chipColor,
              ),
              SizedBox(width: 4),
              Text(
                postType.displayName,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: chipColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportsIndicator(PostModel post, CommunityManagementController controller, bool darkMode) {
    if (post.pendingReportCount == 0) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Iconsax.document_bold,
              size: 14,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode).withOpacity(0.5),
            ),
            SizedBox(width: 4),
            Text(
              '0',
              style: TextStyle(
                color: TAdminColors.getOnSurfaceVariantColor(darkMode).withOpacity(0.5),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: () => _showPostReportsDialog(post),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3), // 减少 vertical padding
          decoration: BoxDecoration(
            color: TAdminColors.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: TAdminColors.warning.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Iconsax.warning_2_bold,
                size: 12, // 减小图标大小
                color: TAdminColors.warning,
              ),
              SizedBox(width: 4),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${post.pendingReportCount}',
                    style: TextStyle(
                      fontSize: 12, // 减小字体大小
                      fontWeight: FontWeight.w600,
                      color: TAdminColors.warning,
                    ),
                  ),
                  if (post.latestReportTime != null)
                    Text(
                      TFormatter.formatElapsedTime(post.latestReportTime!),
                      style: TextStyle(
                        fontSize: 8, // 减小字体大小
                        color: TAdminColors.warning.withOpacity(0.8),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPostReportsDialog(PostModel post) {
    Get.dialog(
      PostReportsDialog(post: post),
      barrierDismissible: false,
    );
  }

  Widget _buildStatusChip(PostModel post, bool darkMode) {
    Color statusColor = post.isDisable ? TAdminColors.error : TAdminColors.success;
    String statusText = post.isDisable ? 'Disabled' : 'Active';
    IconData statusIcon = post.isDisable ? Iconsax.eye_slash_bold : Iconsax.eye_bold;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 85),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                statusIcon,
                size: 12,
                color: statusColor,
              ),
              const SizedBox(width: 4),
              Text(
                statusText,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(PostModel post, CommunityManagementController controller, bool darkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: () => _showPostDetailDialog(post, controller),
          icon: const Icon(Iconsax.eye_bold, size: 16),
          tooltip: 'View Details',
          style: IconButton.styleFrom(
            backgroundColor: TAdminColors.info.withOpacity(0.1),
            foregroundColor: TAdminColors.info,
            minimumSize: const Size(32, 32),
          ),
        ),
        const SizedBox(width: 4),
        // if (post.pendingReportCount > 0 || (controller.postReports[post.postId]?.isNotEmpty ?? false)) ...[
          IconButton(
            onPressed: () => _showPostReportsDialog(post),
            icon: const Icon(Iconsax.document_text_bold, size: 16),
            tooltip: 'View Reports',
            style: IconButton.styleFrom(
              backgroundColor: TAdminColors.warning.withOpacity(0.1),
              foregroundColor: TAdminColors.warning,
              minimumSize: const Size(32, 32),
            ),
          ),
          const SizedBox(width: 4),
        // ],
        if (!post.isDisable) ...[
          IconButton(
            onPressed: () {
              ConfirmationDialog.show(
                title: 'Disable Post',
                message: 'Are you sure you want to disable this post? It will be hidden from users.',
                confirmButtonText: 'Disable',
                customIcon: Iconsax.eye_slash_bold,
                iconColor: TAdminColors.error,
                confirmButtonColor: TAdminColors.error,
                onConfirm: () => controller.disablePost(post),
              );
            },
            icon: const Icon(Iconsax.eye_slash_bold, size: 16),
            tooltip: 'Disable Post',
            style: IconButton.styleFrom(
              backgroundColor: TAdminColors.error.withOpacity(0.1),
              foregroundColor: TAdminColors.error,
              minimumSize: const Size(32, 32),
            ),
          ),
        ] else ...[
          IconButton(
            onPressed: () {
              ConfirmationDialog.show(
                title: 'Enable Post',
                message: 'Are you sure you want to enable this post? It will be visible to users again.',
                confirmButtonText: 'Enable',
                customIcon: Iconsax.eye_bold,
                iconColor: TAdminColors.success,
                confirmButtonColor: TAdminColors.success,
                onConfirm: () => controller.enablePost(post),
              );
            },
            icon: const Icon(Iconsax.eye_bold, size: 16),
            tooltip: 'Enable Post',
            style: IconButton.styleFrom(
              backgroundColor: TAdminColors.success.withOpacity(0.1),
              foregroundColor: TAdminColors.success,
              minimumSize: const Size(32, 32),
            ),
          ),
        ],
      ],
    );
  }

  void _showPostDetailDialog(PostModel post, CommunityManagementController controller) {
    final poster = controller.posterData[post.posterId];
    Get.dialog(PostDetailDialog(post: post, poster: poster));
  }
}