import 'dart:io';

import 'package:image_picker/image_picker.dart';

class VideoHelper {
  VideoHelper._();

  static Future<File?> pickVideo() async {
    File? video;
    final picker = ImagePicker();
    final file = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );

    if (file != null) {
      video = File(file.path);
    }

    return video;
  }
}