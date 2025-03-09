import 'package:diabetes_risk_prediction_and_health_management_system/src/common/loaders/loaders.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/widgets/dialogs/confirm_dialog.dart';
import '../../../data/repositories/community/comment_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../models/comment_model.dart';

class CommentController extends GetxController {
  final String postId;
  CommentController({required this.postId});

  static CommentController get instance => Get.find();

  final commentRepo = Get.put(CommentRepository());

  final comments = <CommentModel>[].obs;
  final isFetching = false.obs;
  final errorMessage = ''.obs;

  final replies = <String, RxList<CommentModel>>{}.obs; // 存储 `commentId` 对应的回复
  final expandedReplies = <String, bool>{}.obs; // 控制某个 `commentId` 的 `replies` 展开状态
  final loadingReplies = <String, bool>{}.obs; // 控制 `replies` 是否在加载

  final commentText = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    _bindCommentsStream();
  }

  /// 绑定 Firestore Stream
  void _bindCommentsStream() {
    comments.bindStream(commentRepo.fetchComments(postId));
  }

  void fetchComments() {
    isFetching.value = true;
    errorMessage.value = '';

    try {
      _bindCommentsStream(); // 重新订阅 Firestore 数据
    } catch (e) {
      errorMessage.value = 'Failed to load comments. Please try again.';
    } finally {
      isFetching.value = false;
    }
  }

  void fetchReplies(String parentCommentId) {
    if (replies.containsKey(parentCommentId)) {
      expandedReplies[parentCommentId] = !(expandedReplies[parentCommentId] ?? false);
      return; // 已经获取过，不再重复请求 Firestore
    }

    loadingReplies[parentCommentId] = true;

    try {
      // 绑定 Firestore Stream
      replies[parentCommentId] = <CommentModel>[].obs;
      replies[parentCommentId]!.bindStream(
        commentRepo.fetchReplies(parentCommentId),
      );

      expandedReplies[parentCommentId] = true;
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.error, message: "Failed to fetch replies.");
    } finally {
      loadingReplies[parentCommentId] = false;
    }
  }

  Future<void> toggleLike(String commentId, List<String> likes, String? parentCommentId) async {
    try {
      await commentRepo.likeDislikeComment(commentId: commentId, likes: likes, parentCommentId: parentCommentId);
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.error, message: TTexts.commonErrorMessage);
    }
  }

  Future<void> makeComment({String? postId, String? parentCommentId}) async {
    final text = commentText.text.trim();
    if (text.isNotEmpty) {
      // Check Internet Connectivity
      final isConnected = await NetworkManager.instance.isConnected();
      if (!isConnected) {
        TLoaders.errorSnackBar(title: TTexts.error, message: TTexts.networkErrorMessage);
        return;
      }

      commentText.clear();
      await commentRepo.makeComment(
        text: text,
        postId: postId,
        parentCommentId: parentCommentId, // 传递 parentCommentId
      );
    }
  }

  /// 询问用户是否要丢弃未保存的评论，并执行导航
  Future<void> handleCommentNavigation(void Function() navigate) async {
    final shouldConfirm = await _shouldConfirmBeforeLeaving();
    if (!shouldConfirm) {
      navigate(); // 直接执行跳转逻辑
      return;
    }

    final result = await Get.dialog<bool>(
      ConfirmDialog(
        title: "Unsaved Comment",
        message: "Do you want to keep writing or discard?",
      ),
    ) ?? true; // 默认返回 true (Keep Writing)

    if (!result) {
      _discardComment();

      /// 确保 Dialog 关闭后再执行跳转
      Future.delayed(Duration.zero, () {
        navigate();
      });
    }
  }

  Future<bool> _shouldConfirmBeforeLeaving() async {
    return commentText.text.trim().isNotEmpty;
  }

  void _discardComment() {
    commentText.clear();
  }
}