import 'package:get/get.dart';

import '../../../data/repositories/community/post_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../models/post_model.dart';

class PostController extends GetxController {
  static PostController get instance => Get.find();

  final postRepo = Get.put(PostRepository());

  final posts = <PostModel>[].obs;
  final isFetching = false.obs;
  final errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPosts();
  }

  /// 绑定 Firestore Stream
  void _bindPostsStream() {
    posts.bindStream(postRepo.fetchPosts());
  }

  /// 手动 Retry：清空错误并重新绑定 Stream
  Future<void> fetchPosts() async {
    isFetching.value = true;
    errorMessage.value = '';

    try {
      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        errorMessage.value = TTexts.networkErrorMessage;
        return;
      }

      // _bindPostsStream(); // 重新订阅 Firestore 数据
      posts.bindStream(postRepo.fetchPosts());
    } catch (e) {
      errorMessage.value = 'Failed to load posts. Please try again.';
    } finally {
      isFetching.value = false;
    }
  }

  List<PostModel> get videos => posts.where((post) => post.postType == 'video').toList();

  Future<void> toggleLike(String postId, List<String> likes) async {
    try {
      await postRepo.likeDislikePost(postId: postId, likes: likes);
    } catch (e) {
      Get.snackbar(TTexts.error, "Failed to update like.");
    }
  }
}