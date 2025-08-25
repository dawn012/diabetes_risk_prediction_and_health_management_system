import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../common/widgets/buttons/round_button.dart';
import '../../../../utils/constants/colors.dart';
import '../../controllers/post_create_controller.dart';
import 'widgets/profile_info.dart';
import 'widgets/image_video_view.dart';
import 'widgets/pick_file.dart';

class CreatePostScreen extends StatelessWidget {
  const CreatePostScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(PostCreateController());

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: controller.makePost2,
            child: const Text('Post'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProfileInfo(),

              // Post text field
              TextField(
                controller: controller.postContent,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: "What's on your mind?",
                  hintStyle: TextStyle(
                    fontSize: 18,
                    color: TColors.darkGrey,
                  ),
                ),
                keyboardType: TextInputType.multiline,
                minLines: 1,
                maxLines: 10,
              ),
              const SizedBox(height: 20),

              // Text(
              //   'Select Post Type',
              //   style: TextStyle(fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 10),
              // Obx(() => DropdownButton<String>(
              //   isExpanded: true,
              //   value: controller.selectedPostType.value,
              //   items: controller.postTypes
              //       .map((type) => DropdownMenuItem<String>(
              //     value: type,
              //     child: Text(type),
              //   ))
              //       .toList(),
              //   onChanged: (value) {
              //     if (value != null) controller.selectedPostType.value = value;
              //   },
              // )),
              // const SizedBox(height: 20),

              // Monitor file changes
              Obx(() {
                return Column(
                  children: [
                    controller.file.value != null
                        ? ImageVideoView(
                      file: controller.file.value!,
                      fileType: controller.fileType.value,
                    )
                        : PickFileWidget(
                      pickImage: controller.pickImage,
                      pickVideo: controller.pickVideo,
                    ),
                    const SizedBox(height: 20),
                    RoundButton(
                      onPressed: controller.makePost2,
                      label: 'Post',
                    ),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
