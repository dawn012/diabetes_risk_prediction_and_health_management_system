import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../data/repositories/community/comment_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../personalization/controllers/user_controller.dart';
import '../models/comment_model.dart';

class CommentController extends GetxController {
  final String postId;
  CommentController({required this.postId});

  static CommentController get instance => Get.find();
  final commentRepo = Get.put(CommentRepository());
  final userController = Get.find<UserController>();

  final comments = <CommentModel>[].obs;
  final replies = <String, RxList<CommentModel>>{}.obs;
  final isFetching = false.obs;
  final errorMessage = ''.obs;
  final expandedReplies = <String, bool>{}.obs;
  final loadingReplies = <String, bool>{}.obs;

  final commentText = TextEditingController();
  final isButtonEnabled = false.obs;
  final editingCommentId = RxnString();
  final originalCommentText = ''.obs;
  FocusNode commentFocusNode = FocusNode();

  var currentSort = 'newest'.obs;

  @override
  void onInit() {
    super.onInit();
    _bindCommentsStream();
    commentText.addListener(_updateButtonState);
  }

  void sortCommentsBy(String sortType) {
    currentSort.value = sortType;

    if (sortType == 'top') {
      comments.sort((a, b) => b.likes.length.compareTo(a.likes.length));
    } else if (sortType == 'newest') {
      comments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
  }

  /// =================== READ =================== ///
  void _bindCommentsStream() => comments.bindStream(commentRepo.fetchComments(postId));

  void fetchComments() {
    isFetching.value = true;
    errorMessage.value = '';
    try {
      _bindCommentsStream();
    } catch (e) {
      errorMessage.value = 'Failed to load comments. Please try again.';
    } finally {
      isFetching.value = false;
    }
  }

  void fetchReplies(String parentCommentId) {
    if (replies.containsKey(parentCommentId)) {
      expandedReplies[parentCommentId] = !(expandedReplies[parentCommentId] ?? false);
      return;  // 已经获取过，不再重复请求 Firestore
    }

    loadingReplies[parentCommentId] = true;
    try {
      // 绑定 Firestore Stream
      replies[parentCommentId] = <CommentModel>[].obs;
      replies[parentCommentId]!.bindStream(commentRepo.fetchReplies(parentCommentId));
      expandedReplies[parentCommentId] = true;
    } catch (e) {
      _showErrorSnackBar("Failed to fetch replies.");
    } finally {
      loadingReplies[parentCommentId] = false;
    }
  }

  /// =================== CREATE =================== ///
  Future<void> makeComment({String? postId, String? parentCommentId}) async {
    final content = commentText.text.trim();
    if (content.isEmpty) return;

    if (!await _checkInternetConnection()) return;

    commentText.clear();

    await (parentCommentId != null
        ? commentRepo.makeReply(content: content, parentCommentId: parentCommentId)
        : commentRepo.makeComment(content: content, postId: postId!));

    sortCommentsBy(currentSort.value);
  }

  void handleCommentSubmit(String? postId, String? parentCommentId) {
    if (!isButtonEnabled.value) return;
    editingCommentId.value != null ? updateComment(parentCommentId) : makeComment(postId: postId, parentCommentId: parentCommentId);
  }

  /// =================== UPDATE =================== ///
  void editComment(CommentModel comment) async {
    final shouldConfirm = _shouldConfirmBeforeLeaving();
    if (shouldConfirm) {
      final result = await TDialog.keepWriting(
        title: "Unsaved Comment",
        message: "Do you want to keep writing or discard?",
      );
      if (!result) _discardComment();
    }

    editingCommentId.value = comment.commentId;
    originalCommentText.value = comment.content;
    commentText.text = comment.content;

    Future.delayed(Duration(milliseconds: 300), () {
      commentText.selection = TextSelection.collapsed(offset: commentText.text.length);
      commentFocusNode.requestFocus();
    });
  }

  Future<void> updateComment(String? parentCommentId) async {
    if (editingCommentId.value == null || commentText.text.trim().isEmpty || commentText.text.trim() == originalCommentText.value) return;

    try {
      await (parentCommentId != null
          ? commentRepo.updateReplySingleField(replyId: editingCommentId.value!, parentCommentId: parentCommentId, json: {'text': commentText.text.trim()})
          : commentRepo.updateSingleField(commentId: editingCommentId.value!, json: {'text': commentText.text.trim()}));

      _clearEditingState();
    } catch (e) {
      _showErrorSnackBar("Failed to update comment.");
    } finally {
      sortCommentsBy(currentSort.value);
    }
  }

  Future<void> cancelEdit() async {
    final shouldConfirm = _shouldConfirmBeforeLeaving();
    if (shouldConfirm) {
      final result = await TDialog.keepWriting(
        title: "Discard edits?",
        message: "Your changes will be lost.",
      );
      if (!result) {
        commentFocusNode.unfocus();
        _clearEditingState();
      }
    }
  }

  /// =================== DELETE =================== ///
  /// Delete Comment Warning
  void deleteCommentWarningPopup(CommentModel comment, bool isComment) {
    TDialog.deleteDialog(
      title: 'Delete Comment',
      message: 'Delete your comment permanently?',
      onConfirm: () {
        deleteComment(comment, isComment);
        Get.back();
      },
    );
  }

  /// Delete Comment
  Future<void> deleteComment(CommentModel comment, bool isComment) async {
    try {
      isComment ? await commentRepo.removeComment(comment.commentId) : await commentRepo.removeReply(parentCommentId: comment.parentCommentId!, replyId: comment.commentId);
      TLoaders.successSnackBar(title: 'Success', message: 'Comment deleted successfully');
    } catch (e) {
      _showErrorSnackBar(e.toString());
    } finally {
      sortCommentsBy(currentSort.value);
    }
  }

  /// =================== TOGGLE LIKE =================== ///
  Future<void> toggleLike(String commentId, List<String> likes, String? parentCommentId) async {
    try {
      await commentRepo.likeDislikeComment(commentId: commentId, likes: likes, parentCommentId: parentCommentId);
    } catch (e) {
      TLoaders.errorSnackBar(title: TTexts.error, message: TTexts.commonErrorMessage);
    } finally {
      sortCommentsBy(currentSort.value);
    }
  }

  /// =================== UTILS =================== ///
  bool isOwner(String authorId) => userController.user.value.userId == authorId;

  /// 询问用户是否要丢弃未保存的评论，并执行导航
  Future<void> handleCommentNavigation(void Function() navigate) async {
    if (!_shouldConfirmBeforeLeaving()) {
      navigate();  // 直接执行跳转逻辑
      return;
    }

    final result = await TDialog.keepWriting(title: "Unsaved Comment", message: "Do you want to keep writing or discard?");
    if (!result) {
      commentFocusNode.unfocus();
      _discardComment();
      // 确保 Dialog 关闭后再执行跳转
      Future.delayed(Duration(milliseconds: 200), navigate);
    }
  }

  void _updateButtonState() {
    isButtonEnabled.value = commentText.text.trim().isNotEmpty && commentText.text.trim() != originalCommentText.value;
  }

  bool _shouldConfirmBeforeLeaving() => commentText.text.trim().isNotEmpty;

  void _discardComment() => commentText.clear();

  /// 清空编辑状态
  void _clearEditingState() {
    editingCommentId.value = null;
    originalCommentText.value = '';
    commentText.clear();
  }

  Future<bool> _checkInternetConnection() async {
    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) _showErrorSnackBar(TTexts.networkErrorMessage);
    return isConnected;
  }

  void _showErrorSnackBar(String message) {
    TLoaders.errorSnackBar(title: TTexts.error, message: message);
  }
}
