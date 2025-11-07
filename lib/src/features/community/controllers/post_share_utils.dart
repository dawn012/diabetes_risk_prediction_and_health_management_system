import 'dart:io';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../../common/loaders/loaders.dart';
import '../../../services/deep_link_service.dart';
import '../../../utils/helpers/video_helper.dart';
import '../models/post_model.dart';

class PostShareUtils {
  /// 复制帖子链接到剪贴板
  static Future<void> copyPostLink(String postId) async {
    try {
      final deepLink = DeepLinkService.instance.generatePostDeepLink(postId);
      await Clipboard.setData(ClipboardData(text: deepLink));

      TLoaders.modernSnackBar(
        title: 'Link Copied',
        message: 'Post link copied to clipboard',
      );
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to copy link: ${e.toString()}',
      );
    }
  }

  /// 分享帖子
  static Future<void> sharePost(PostModel post) async {
    try {
      final deepLink = DeepLinkService.instance.generatePostDeepLink(post.postId);
      String shareText = _buildShareText(post, deepLink);

      // 如果有媒体文件，下载第一个并分享
      if (post.mediaUrls.isNotEmpty) {
        await _sharePostWithMedia(post, shareText, deepLink);
      } else {
        // 只分享文本和链接
        await Share.share(
          shareText,
          subject: 'Check out this post from DiaTrack Community',
        );
      }
    } catch (e) {
      TLoaders.errorSnackBar(
        title: 'Error',
        message: 'Failed to share post: ${e.toString()}',
      );
    }
  }

  /// 构建分享文本（简化版，因为会附带媒体）
  static String _buildShareText(PostModel post, String deepLink) {
    final buffer = StringBuffer();

    // 添加帖子类型标签
    buffer.write('📱 ${post.postType.shortLabel}\n\n');

    // 添加帖子内容
    if (post.postContent.isNotEmpty) {
      String content = post.postContent;
      // WhatsApp 分享时，如果内容太长会影响体验
      if (content.length > 150) {
        content = '${content.substring(0, 150)}...';
      }
      buffer.write('$content\n\n');
    }

    // 添加统计信息（简化）
    if (post.likes.isNotEmpty || post.commentCount > 0) {
      buffer.write('👍 ${post.likes.length} likes • 💬 ${post.commentCount} comments\n\n');
    }

    // 添加深度链接
    buffer.write('View in app: $deepLink\n\n');

    // 添加应用标识
    buffer.write('Shared from DiaTrack Community');

    return buffer.toString();
  }

  /// 分享带媒体的帖子
  static Future<void> _sharePostWithMedia(PostModel post, String text, String deepLink) async {
    try {
      // 显示加载提示
      TLoaders.modernSnackBar(
        title: 'Preparing',
        message: 'Downloading media...',
      );

      // 下载第一个媒体文件
      final mediaUrl = post.mediaUrls.first;
      final isVideo = VideoHelper.isVideoFile(mediaUrl);

      // 下载文件到临时目录
      final file = await _downloadFile(mediaUrl, isVideo);

      if (file != null) {
        // 使用 XFile 分享（支持图片和视频）
        final xFile = XFile(file.path);

        await Share.shareXFiles(
          [xFile],
          text: text,
          subject: 'Check out this post from DiaTrack Community',
        );
      } else {
        // 下载失败，降级为只分享文本
        await Share.share(text);
      }
    } catch (e) {
      print('Failed to share with media: $e');
      // 降级为只分享文本
      await Share.share(text);
    }
  }

  /// 下载文件到临时目录
  static Future<File?> _downloadFile(String url, bool isVideo) async {
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final extension = isVideo ? 'mp4' : 'jpg';
        final fileName = 'share_${DateTime.now().millisecondsSinceEpoch}.$extension';
        final file = File('${tempDir.path}/$fileName');

        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
      return null;
    } catch (e) {
      print('Error downloading file: $e');
      return null;
    }
  }
}