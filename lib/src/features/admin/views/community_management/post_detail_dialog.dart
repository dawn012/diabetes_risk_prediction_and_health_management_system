import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:icons_plus/icons_plus.dart';

import '../../../../utils/constants/admin_colors.dart';
import '../../../../utils/constants/enums.dart'; // 导入枚举
import '../../../../utils/helpers/helper_functions.dart';
import '../../../authentication/models/user_model.dart';
import '../../../community/models/post_model.dart';

class PostDetailDialog extends StatelessWidget {
  final PostModel post;
  final UserModel? poster;

  PostDetailDialog({
    super.key,
    required this.post,
    this.poster,
  });

  @override
  Widget build(BuildContext context) {
    final darkMode = THelperFunctions.isDarkMode(context);
    final isWeb = THelperFunctions.screenWidth() > 800;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: isWeb ? 800 : MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: TAdminColors.getSurfaceColor(darkMode),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: darkMode ? Colors.black54 : Colors.grey.withOpacity(0.3),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            _buildHeader(darkMode),

            Divider(color: TAdminColors.getBorderColor(darkMode), height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Post Info
                    _buildPostInfo(darkMode),

                    SizedBox(height: 24),

                    // Poster Info
                    _buildPosterInfo(darkMode),

                    SizedBox(height: 24),

                    // Content
                    _buildContent(darkMode),

                    if (post.mediaUrls.isNotEmpty) ...[
                      SizedBox(height: 24),
                      _buildMediaSection(darkMode),
                    ],

                    SizedBox(height: 24),

                    // Stats
                    _buildStats(darkMode),
                  ],
                ),
              ),
            ),

            Divider(color: TAdminColors.getBorderColor(darkMode), height: 1),

            // Footer with actions
            _buildFooter(darkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool darkMode) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          Icon(
            Iconsax.document_text_1_bold,
            color: TAdminColors.primary,
            size: 24,
          ),
          SizedBox(width: 12),
          Text(
            'Post Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
          ),
          Spacer(),
          _buildStatusChip(darkMode),
          SizedBox(width: 16),
          IconButton(
            onPressed: () => Get.back(),
            icon: Icon(
              Iconsax.close_circle_bold,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
            style: IconButton.styleFrom(
              backgroundColor: TAdminColors.getSurfaceVariantColor(darkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(bool darkMode) {
    Color statusColor = post.isDisable ? TAdminColors.error : TAdminColors.success;
    String statusText = post.isDisable ? 'Disabled' : 'Active';
    IconData statusIcon = post.isDisable ? Iconsax.close_circle_bold : Iconsax.tick_circle_bold;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 14,
            color: statusColor,
          ),
          SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostInfo(bool darkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.info_circle_bold,
                color: TAdminColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Post Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoRow('Post ID', post.postId, Iconsax.hashtag_bold, darkMode),
          SizedBox(height: 12),
          _buildInfoRow('Type', post.postType.displayName, _getPostTypeIcon(post.postType), darkMode), // 使用 displayName
          SizedBox(height: 12),
          _buildInfoRow('Created', _formatDateTime(post.createdAt), Iconsax.calendar_bold, darkMode),
          SizedBox(height: 12),
          _buildInfoRow('Updated', _formatDateTime(post.updatedAt), Iconsax.clock_bold, darkMode),
        ],
      ),
    );
  }

  Widget _buildPosterInfo(bool darkMode) {
    if (poster == null) {
      return Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: TAdminColors.getSurfaceVariantColor(darkMode),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
        ),
        child: Row(
          children: [
            Icon(
              Iconsax.user_bold,
              color: TAdminColors.warning,
              size: 18,
            ),
            SizedBox(width: 8),
            Text(
              'Poster information unavailable',
              style: TextStyle(
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.user_bold,
                color: TAdminColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Poster Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: poster!.profileImg.isNotEmpty
                    ? NetworkImage(poster!.profileImg)
                    : null,
                backgroundColor: poster!.profileImg.isEmpty
                    ? TAdminColors.primary.withOpacity(0.2)
                    : null,
                child: poster!.profileImg.isEmpty
                    ? Icon(Iconsax.user_bold, size: 24, color: TAdminColors.primary)
                    : null,
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      poster!.username,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: TAdminColors.getOnSurfaceColor(darkMode),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      poster!.email,
                      style: TextStyle(
                        color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Iconsax.star_1_bold,
                          size: 14,
                          color: TAdminColors.warning,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '${poster!.totalScore} points',
                          style: TextStyle(
                            fontSize: 12,
                            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool darkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.document_text_bold,
                color: TAdminColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Post Content',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TAdminColors.getSurfaceColor(darkMode),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
            ),
            child: Text(
              post.postContent.isNotEmpty ? post.postContent : 'No content available',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: post.postContent.isNotEmpty
                    ? TAdminColors.getOnSurfaceColor(darkMode)
                    : TAdminColors.getOnSurfaceVariantColor(darkMode),
                fontStyle: post.postContent.isEmpty ? FontStyle.italic : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSection(bool darkMode) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getPostTypeIcon(post.postType), // 使用帖子类型图标
                color: TAdminColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Media Files (${post.mediaUrls.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: post.mediaUrls.asMap().entries.map((entry) {
              final index = entry.key;
              final mediaUrl = entry.value;
              return _buildMediaPreview(mediaUrl, index, darkMode);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPreview(String mediaUrl, int index, bool darkMode) {
    final isImage = mediaUrl.startsWith('http') && !mediaUrl.contains('text:');
    final isText = mediaUrl.startsWith('text:');

    return GestureDetector(
      onTap: () {
        _showMediaViewer(mediaUrl, isImage ? 'image' : isText ? 'text' : 'other');
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: TAdminColors.getSurfaceColor(darkMode),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            children: [
              // Media preview based on type
              if (isImage)
                Image.network(
                  mediaUrl,
                  width: 120,
                  height: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _buildMediaError(darkMode),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return _buildMediaLoading(darkMode);
                  },
                )
              else if (isText)
                _buildTextMediaPlaceholder(darkMode)
              else
                _buildMediaPlaceholder('other', darkMode),

              // Media type indicator
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isImage ? Iconsax.image_bold :
                        isText ? Iconsax.document_text_bold : Iconsax.document_bold,
                        size: 10,
                        color: Colors.white,
                      ),
                      SizedBox(width: 2),
                      Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Hover overlay for better interaction
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => _showMediaViewer(mediaUrl, isImage ? 'image' : isText ? 'text' : 'other'),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(
                          Iconsax.eye_bold,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextMediaPlaceholder(bool darkMode) {
    return Container(
      width: 120,
      height: 120,
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: TAdminColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.document_text_bold,
            color: TAdminColors.info,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            'Text Content',
            style: TextStyle(
              fontSize: 10,
              color: TAdminColors.info,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaLoading(bool darkMode) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: CircularProgressIndicator(
          color: TAdminColors.primary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildMediaError(bool darkMode) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: TAdminColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.close_circle_bold,
            color: TAdminColors.error,
            size: 24,
          ),
          SizedBox(height: 4),
          Text(
            'Failed to load',
            style: TextStyle(
              fontSize: 10,
              color: TAdminColors.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaPlaceholder(String mediaType, bool darkMode) {
    IconData icon;
    Color color;

    switch (mediaType) {
      case 'video':
        icon = Iconsax.video_play_bold;
        color = TAdminColors.info;
        break;
      case 'audio':
        icon = Iconsax.music_bold;
        color = TAdminColors.success;
        break;
      default:
        icon = Iconsax.document_bold;
        color = TAdminColors.warning;
    }

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
          ),
          SizedBox(height: 8),
          Text(
            mediaType.capitalizeFirst!,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStats(bool darkMode) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceVariantColor(darkMode),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.chart_bold,
                color: TAdminColors.primary,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Post Statistics',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: TAdminColors.getOnSurfaceColor(darkMode),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Likes',
                  post.likes.length.toString(),
                  Iconsax.heart_bold,
                  TAdminColors.error,
                  darkMode,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Media Files',
                  post.mediaUrls.length.toString(),
                  _getPostTypeIcon(post.postType), // 使用帖子类型图标
                  TAdminColors.info,
                  darkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color, bool darkMode) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TAdminColors.getSurfaceColor(darkMode),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TAdminColors.getBorderColor(darkMode)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: TAdminColors.getOnSurfaceVariantColor(darkMode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool darkMode) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Row(
        children: [
          // Post info
          Expanded(
            child: Text(
              'Post ID: ${post.postId}',
              style: TextStyle(
                fontSize: 12,
                color: TAdminColors.getOnSurfaceVariantColor(darkMode),
                fontFamily: 'monospace',
              ),
            ),
          ),

          // Action buttons
          Row(
            children: [
              OutlinedButton(
                onPressed: () => Get.back(),
                child: Text('Close'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  // Handle action
                  Get.back();
                  _handlePostAction();
                },
                icon: Icon(
                  post.isDisable ? Iconsax.tick_circle_bold : Iconsax.close_circle_bold,
                  size: 16,
                ),
                label: Text(post.isDisable ? 'Enable Post' : 'Disable Post'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: post.isDisable ? TAdminColors.success : TAdminColors.error,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, bool darkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: TAdminColors.getOnSurfaceVariantColor(darkMode),
        ),
        SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: TAdminColors.getOnSurfaceVariantColor(darkMode),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: TAdminColors.getOnSurfaceColor(darkMode),
            ),
          ),
        ),
      ],
    );
  }

  // Helper methods - 修改为接受 PostType 枚举
  IconData _getPostTypeIcon(PostType type) {
    switch (type) {
      case PostType.general:
        return Iconsax.messages_1_bold;
      case PostType.tips:
        return Iconsax.lamp_bold;
      case PostType.recipe:
        return Iconsax.cake_bold;
      case PostType.story:
        return Iconsax.book_1_bold;
    }
  }

  IconData _getMediaIcon(String type) {
    switch (type) {
      case 'image':
        return Iconsax.gallery_bold;
      case 'video':
        return Iconsax.video_bold;
      case 'audio':
        return Iconsax.music_bold;
      default:
        return Iconsax.document_bold;
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // Action handlers
  void _showMediaViewer(String mediaUrl, String mediaType) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.black87,
        child: Container(
          width: Get.width * 0.8,
          height: Get.height * 0.8,
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Media Viewer',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      onPressed: () => Get.back(),
                      icon: Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: mediaType == 'image'
                      ? Image.network(
                    mediaUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) =>
                        Text('Failed to load media', style: TextStyle(color: Colors.white)),
                  )
                      : Container(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _getMediaIcon(mediaType),
                          color: Colors.white,
                          size: 64,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Media preview not available',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePostAction() {
    print('Post action triggered for post: ${post.postId}');
  }
}