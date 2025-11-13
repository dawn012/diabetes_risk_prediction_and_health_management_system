import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/colors.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/helpers/helper_functions.dart';

class MediaPicker {
  MediaPicker._();

  /// 图片选择器选项（仅图片，用于头像等）
  static Future<MediaOption?> showImagePickerOptions({
    required BuildContext context,
    String title = 'Choose Photo',
  }) async {
    return await showMediaOptions(
      context: context,
      title: title,
      allowImage: true,
      allowVideo: false, // 禁用视频
      allowCamera: true,
      allowGallery: true,
    );
  }

  /// 通用媒体选择底部弹窗
  static Future<MediaOption?> showMediaOptions({
    required BuildContext context,
    required String title,
    bool allowImage = true,
    bool allowVideo = true,
    bool allowCamera = true,
    bool allowGallery = true,
  }) async {
    final options = <MediaOption>[];

    // 构建可用的选项
    if (allowGallery && (allowImage || allowVideo)) {
      options.add(MediaOption(
        type: MediaOptionType.gallery,
        icon: Icons.photo_library,
        title: 'From Gallery',
        subtitle: allowImage && allowVideo
            ? 'Select photos and videos'
            : allowImage ? 'Select photos' : 'Select videos',
      ));
    }

    if (allowCamera) {
      if (allowImage) {
        options.add(MediaOption(
          type: MediaOptionType.camera,
          icon: Icons.camera_alt,
          title: 'Take Photo',
          subtitle: 'Capture with camera',
        ));
      }

      if (allowVideo) {
        options.add(MediaOption(
          type: MediaOptionType.video,
          icon: Icons.videocam,
          title: 'Record Video',
          subtitle: 'Capture video with camera',
        ));
      }
    }

    if (options.isEmpty) {
      return null;
    }

    return await Get.bottomSheet<MediaOption?>(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 拖动指示器
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // 标题
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // 选项列表
            ...options.map((option) => _buildMediaOption(
              icon: option.icon,
              title: option.title,
              subtitle: option.subtitle,
              onTap: () => Get.back(result: option),
            )),
            const SizedBox(height: 10),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  static Widget _buildMediaOption({
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
}

/// 媒体选项数据类
class MediaOption {
  final MediaOptionType type;
  final IconData icon;
  final String title;
  final String subtitle;

  const MediaOption({
    required this.type,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}