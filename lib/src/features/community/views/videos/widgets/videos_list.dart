// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../../../../common/loaders/circular_loader.dart';
// import '../../../../../common/widgets/error_screen/error_retry_screen.dart';
// import '../../../controllers/post_controller.dart';
// import '../../posts/widgets/post_tile.dart';
//
// class VideosList extends StatelessWidget {
//   const VideosList({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final controller = PostController.instance;
//
//     return Obx(() {
//       if (controller.isFetching.value) {
//         return const SliverToBoxAdapter(child: CircularLoader());
//
//       } else if (controller.errorMessage.isNotEmpty) {
//         return SliverToBoxAdapter(
//           child: ErrorRetryScreen(message: controller.errorMessage.value, onRetry: controller.fetchPosts),
//         );
//
//       } else if (controller.videos.isEmpty) {
//         return const SliverToBoxAdapter(
//           child: Align(
//             alignment: Alignment.center,
//             child: Padding(
//               padding: EdgeInsets.symmetric(vertical: 50),
//               child: Text("No videos available"),
//             ),
//           ),
//         );
//
//       } else {
//         return SliverList.separated(
//           itemCount: controller.videos.length,
//           separatorBuilder: (context, index) => const SizedBox(height: 8),
//           itemBuilder: (context, index) {
//             final postId = controller.videos[index].postId; // 只传 postId
//             return PostTile(postId: postId);
//           },
//         );
//       }
//     });
//   }
// }