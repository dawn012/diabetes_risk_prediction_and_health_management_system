import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../data/repositories/community/comment_repository.dart';
import '../../../data/repositories/community/reply_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../personalization/controllers/user_controller.dart';
import '../models/comment_model.dart';
import '../models/reply_model.dart';

class CommentController extends GetxController {
  final String postId;
  CommentController({required this.postId});

  static CommentController get instance => Get.find();

  final commentRepo = Get.put(CommentRepository());
  final replyRepo = Get.put(ReplyRepository());
  final userController = UserController.instance;

  // Comments state
  final comments = <CommentModel>[].obs;
  final isLoadingComments = false.obs;
  final hasMoreComments = true.obs;
  final commentsError = ''.obs;
  DocumentSnapshot? lastCommentDoc;

  // Replies state - Map of commentId -> replies
  final repliesMap = <String, RxList<ReplyModel>>{}.obs;
  final expandedReplies = <String, bool>{}.obs;
  final loadingReplies = <String, bool>{}.obs;
  final repliesError = <String, String>{}.obs;

  // UI state
  final commentText = TextEditingController();
  final isButtonEnabled = false.obs;
  final editingCommentId = RxnString();
  final editingReplyId = RxnString();
  final editingParentCommentId = RxnString();
  final originalText = ''.obs;
  final commentFocusNode = FocusNode();

  // Sorting
  final currentSort = 'newest'.obs; // 'newest' or 'top'

  @override
  void onInit() {
    super.onInit();
    fetchComments();
    commentText.addListener(_updateButtonState);
  }

  @override
  void onClose() {
    commentText.dispose();
    commentFocusNode.dispose();
    super.onClose();
  }

  /// =================== COMMENTS SECTION =================== ///

  /// Fetch comments with pagination
  Future<void> fetchComments({bool refresh = false}) async {
    if (refresh) {
      comments.clear();
      lastCommentDoc = null;
      hasMoreComments.value = true;
    }

    isLoadingComments.value = true;
    commentsError.value = '';

    try {
      final stream = currentSort.value == 'top'
          ? commentRepo.fetchTopComments(postId: postId, limit: 20)
          : commentRepo.fetchComments(postId: postId, limit: 20, startAfter: lastCommentDoc as DocumentSnapshot<Map<String, dynamic>>?);

      comments.bindStream(stream);

      await Future.delayed(const Duration(milliseconds: 100));
    } catch (e) {
      commentsError.value = 'Failed to load comments';
    } finally {
      isLoadingComments.value = false;
    }
  }

  /// Create new comment
  Future<void> createComment() async {
    final content = commentText.text.trim();
    if (content.isEmpty) return;

    if (!await _checkConnection()) return;

    try {
      await commentRepo.createComment(content: content, postId: postId);
      commentText.clear();
      TLoaders.successSnackBar(title: 'Success', message: 'Comment posted');
    } catch (e) {
      _showError(e.toString());
    }
  }

  /// Edit comment
  void editComment(CommentModel comment) async {
    if (_hasUnsavedChanges()) {
      final shouldDiscard = await _showDiscardDialog();
      if (!shouldDiscard) return;
    }

    editingCommentId.value = comment.commentId;
    editingReplyId.value = null;
    editingParentCommentId.value = null;
    originalText.value = comment.content;
    commentText.text = comment.content;
    _focusTextField();
  }

  /// Update comment
  Future<void> updateComment() async {
    final content = commentText.text.trim();
    if (editingCommentId.value == null || content.isEmpty || content == originalText.value) return;

    try {
      await commentRepo.updateComment(commentId: editingCommentId.value!, content: content);
      _clearEditingState();
      TLoaders.successSnackBar(title: 'Success', message: 'Comment updated');
    } catch (e) {
      _showError('Failed to update comment');
    }
  }

  /// Delete comment
  void deleteCommentDialog(CommentModel comment) {
    TDialog.deleteDialog(
      title: 'Delete Comment',
      message: 'Are you sure you want to delete this comment?',
      onConfirm: () => _deleteComment(comment.commentId),
    );
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      await commentRepo.deleteComment(commentId);
      TLoaders.successSnackBar(title: 'Success', message: 'Comment deleted');
    } catch (e) {
      _showError('Failed to delete comment');
    }
  }

  /// Toggle comment like
  Future<void> toggleCommentLike(CommentModel comment) async {
    try {
      await commentRepo.toggleCommentLike(
        commentId: comment.commentId,
        currentLikes: comment.likes,
      );
    } catch (e) {
      _showError('Failed to update like');
    }
  }

  /// =================== REPLIES SECTION =================== ///

  /// Fetch replies for a comment
  void fetchReplies(String commentId) {
    if (repliesMap.containsKey(commentId)) {
      // Toggle expand/collapse
      expandedReplies[commentId] = !(expandedReplies[commentId] ?? false);
      return;
    }

    // First time loading replies
    loadingReplies[commentId] = true;
    repliesError[commentId] = '';

    try {
      repliesMap[commentId] = <ReplyModel>[].obs;
      repliesMap[commentId]!.bindStream(replyRepo.fetchReplies(parentCommentId: commentId));
      expandedReplies[commentId] = true;
    } catch (e) {
      repliesError[commentId] = 'Failed to load replies';
    } finally {
      loadingReplies[commentId] = false;
    }
  }

  /// Create new reply
  Future<void> createReply(String parentCommentId) async {
    final content = commentText.text.trim();
    if (content.isEmpty) return;

    if (!await _checkConnection()) return;

    try {
      await replyRepo.createReply(
        content: content,
        parentCommentId: parentCommentId,
      );
      commentText.clear();
      TLoaders.successSnackBar(title: 'Success', message: 'Reply posted');
    } catch (e) {
      _showError(e.toString());
    }
  }

  /// Edit reply
  void editReply(ReplyModel reply, String parentCommentId) async {
    if (_hasUnsavedChanges()) {
      final shouldDiscard = await _showDiscardDialog();
      if (!shouldDiscard) return;
    }

    editingReplyId.value = reply.replyId;
    editingCommentId.value = null;
    editingParentCommentId.value = parentCommentId;
    originalText.value = reply.content;
    commentText.text = reply.content;
    _focusTextField();
  }

  /// Update reply
  Future<void> updateReply() async {
    final content = commentText.text.trim();
    if (editingReplyId.value == null || editingParentCommentId.value == null ||
        content.isEmpty || content == originalText.value) return;

    try {
      await replyRepo.updateReply(
        replyId: editingReplyId.value!,
        parentCommentId: editingParentCommentId.value!,
        content: content,
      );
      _clearEditingState();
      TLoaders.successSnackBar(title: 'Success', message: 'Reply updated');
    } catch (e) {
      _showError('Failed to update reply');
    }
  }

  /// Delete reply
  void deleteReplyDialog(ReplyModel reply, String parentCommentId) {
    TDialog.deleteDialog(
      title: 'Delete Reply',
      message: 'Are you sure you want to delete this reply?',
      onConfirm: () => _deleteReply(reply.replyId, parentCommentId),
    );
  }

  Future<void> _deleteReply(String replyId, String parentCommentId) async {
    try {
      await replyRepo.deleteReply(replyId: replyId, parentCommentId: parentCommentId);
      TLoaders.successSnackBar(title: 'Success', message: 'Reply deleted');
    } catch (e) {
      _showError('Failed to delete reply');
    }
  }

  /// Toggle reply like
  Future<void> toggleReplyLike(ReplyModel reply, String parentCommentId) async {
    try {
      await replyRepo.toggleReplyLike(
        replyId: reply.replyId,
        parentCommentId: parentCommentId,
        currentLikes: reply.likes,
      );
    } catch (e) {
      _showError('Failed to update like');
    }
  }

  /// =================== UI ACTIONS =================== ///

  /// Handle comment/reply submission
  void handleSubmit({String? parentCommentId}) {
    if (!isButtonEnabled.value) return;

    if (editingCommentId.value != null) {
      updateComment();
    } else if (editingReplyId.value != null) {
      updateReply();
    } else if (parentCommentId != null) {
      createReply(parentCommentId);
    } else {
      createComment();
    }
  }

  /// Cancel editing
  Future<void> cancelEdit() async {
    if (_hasUnsavedChanges()) {
      final shouldDiscard = await _showDiscardDialog();
      if (!shouldDiscard) return;
    }
    _clearEditingState();
  }

  /// Sort comments
  void sortComments(String sortType) {
    if (currentSort.value == sortType) return;

    currentSort.value = sortType;
    fetchComments(refresh: true);
  }

  /// Handle back navigation with unsaved changes
  Future<void> handleNavigation(VoidCallback onNavigate) async {
    if (_hasUnsavedChanges()) {
      final shouldDiscard = await _showDiscardDialog();
      if (!shouldDiscard) return;
    }

    _clearEditingState();
    onNavigate();
  }

  /// =================== HELPER METHODS =================== ///

  bool isOwner(String authorId) => userController.user.value.userId == authorId;

  bool get isEditing => editingCommentId.value != null || editingReplyId.value != null;

  String get submitButtonText {
    if (editingCommentId.value != null) return 'Update';
    if (editingReplyId.value != null) return 'Update';
    return 'Post';
  }

  void _updateButtonState() {
    final text = commentText.text.trim();
    isButtonEnabled.value = text.isNotEmpty && text != originalText.value;
  }

  bool _hasUnsavedChanges() {
    return commentText.text.trim().isNotEmpty &&
        commentText.text.trim() != originalText.value;
  }

  void _focusTextField() {
    Future.delayed(const Duration(milliseconds: 300), () {
      commentText.selection = TextSelection.collapsed(offset: commentText.text.length);
      commentFocusNode.requestFocus();
    });
  }

  void _clearEditingState() {
    editingCommentId.value = null;
    editingReplyId.value = null;
    editingParentCommentId.value = null;
    originalText.value = '';
    commentText.clear();
    commentFocusNode.unfocus();
  }

  Future<bool> _showDiscardDialog() async {
    return await TDialog.keepWriting(
      title: "Unsaved Changes",
      message: "You have unsaved changes. Do you want to keep writing or discard?",
    );
  }

  Future<bool> _checkConnection() async {
    final isConnected = await NetworkManager.instance.isConnected();
    if (!isConnected) {
      _showError(TTexts.networkErrorMessage);
    }
    return isConnected;
  }

  void _showError(String message) {
    TLoaders.errorSnackBar(title: TTexts.error, message: message);
  }

  /// Get replies for a comment
  List<ReplyModel> getReplies(String commentId) {
    return repliesMap[commentId]?.toList() ?? [];
  }

  /// Check if replies are expanded for a comment
  bool areRepliesExpanded(String commentId) {
    return expandedReplies[commentId] ?? false;
  }

  /// Check if replies are loading for a comment
  bool areRepliesLoading(String commentId) {
    return loadingReplies[commentId] ?? false;
  }
}