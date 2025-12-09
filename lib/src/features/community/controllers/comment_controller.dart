import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../common/loaders/loaders.dart';
import '../../../common/widgets/dialogs/dialog.dart';
import '../../../data/repositories/community/comment_repository.dart';
import '../../../data/repositories/community/reply_repository.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/helpers/network_manager.dart';
import '../../../utils/validators/community_validator.dart';
import '../../personalization/controllers/avatar_frame_controller.dart';
import '../../personalization/controllers/user_controller.dart';
import '../models/comment_model.dart';
import '../models/reply_model.dart';
import 'post_controller.dart';

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
  // Scroll controller for pagination
  final ScrollController scrollController = ScrollController();

  // Stream subscription for real-time updates (only for newest sort)
  StreamSubscription? _commentsStreamSubscription;

  // Replies state
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
  final currentSort = 'newest'.obs; // 'newest', 'oldest', 'top'

  @override
  void onInit() {
    super.onInit();
    fetchComments();
    commentText.addListener(_updateButtonState);
    scrollController.addListener(_onScroll);
  }

  @override
  void onClose() {
    _commentsStreamSubscription?.cancel();
    commentText.dispose();
    commentFocusNode.dispose();
    scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.onClose();
  }

  Future<void> _preloadAuthorsForComments(List<CommentModel> list) async {
    final frameController = AvatarFrameController.instance;
    final authorIds = list.map((c) => c.authorId).toSet().toList();

    await Future.wait([
      // 预加载用户资料（如果你也想保证名字/头像是最新的）
      ...authorIds.map((id) => userController.fetchUserRecordById(id)),
      // 预加载头像框
      ...authorIds.map((id) => frameController.fetchUserAvatarFramesFor(id)),
    ]);
  }


  /// =================== COMMENTS SECTION =================== ///

  /// Fetch comments based on current sort mode
  Future<void> fetchComments({bool refresh = false}) async {
    if (refresh) {
      comments.clear();
      lastCommentDoc = null;
      hasMoreComments.value = true;
      _commentsStreamSubscription?.cancel();
    }

    isLoadingComments.value = true;
    commentsError.value = '';

    try {
      if (currentSort.value == 'newest') {
        // Use Stream for real-time updates (only for first page)
        if (lastCommentDoc == null) {
          _setupRealtimeComments();
        } else {
          // Pagination for older comments (non-realtime)
          await _fetchPaginatedComments();
        }
      } else if (currentSort.value == 'top') {
        // Fetch top comments (no real-time)
        await _fetchTopComments();
      } else if (currentSort.value == 'oldest') {
        // Fetch oldest first (no real-time)
        await _fetchOldestComments();
      }
    } catch (e) {
      commentsError.value = 'Failed to load comments';
    } finally {
      isLoadingComments.value = false;
    }
  }

  /// Setup real-time listener for newest comments (first page only)
  void _setupRealtimeComments() {
    _commentsStreamSubscription?.cancel();

    final stream = commentRepo.fetchComments(
      postId: postId,
      limit: 20,
      startAfter: null,
    );

    _commentsStreamSubscription = stream.listen((newComments) async {
      comments.value = newComments;
      isLoadingComments.value = false;

      await _preloadAuthorsForComments(newComments);

      // 初始化分页游标和 hasMoreComments
      if (newComments.isNotEmpty) {
        final snapshot = await commentRepo.fetchCommentsPaginated(
          postId: postId,
          limit: 20,
          startAfter: null,
        );
        if (snapshot.docs.isNotEmpty) {
          lastCommentDoc = snapshot.docs.last;
          hasMoreComments.value = snapshot.docs.length == 20;
        } else {
          hasMoreComments.value = false;
        }
      } else {
        hasMoreComments.value = false;
      }
    }, onError: (error) {
      commentsError.value = 'Failed to load comments';
      isLoadingComments.value = false;
    });
  }

  /// Fetch paginated comments (for older data)
  Future<void> _fetchPaginatedComments() async {
    final snapshot = await commentRepo.fetchCommentsPaginated(
      postId: postId,
      limit: 20,
      startAfter: lastCommentDoc,
    );

    if (snapshot.docs.isEmpty) {
      hasMoreComments.value = false;
      return;
    }

    final newComments = snapshot.docs
        .map((doc) => CommentModel.fromSnapshot(doc))
        .toList();

    newComments.sort((a, b) {
      final aTime = a.updatedAt.isAfter(a.createdAt) ? a.updatedAt : a.createdAt;
      final bTime = b.updatedAt.isAfter(b.createdAt) ? b.updatedAt : b.createdAt;
      return bTime.compareTo(aTime);
    });

    await _preloadAuthorsForComments(newComments);

    comments.addAll(newComments);
    lastCommentDoc = snapshot.docs.last;
    hasMoreComments.value = snapshot.docs.length == 20;
  }

  /// Fetch top comments (sorted by popularity score)
  Future<void> _fetchTopComments() async {
    final snapshot = await commentRepo.fetchTopCommentsPaginated(
      postId: postId,
      limit: 20,
      startAfter: lastCommentDoc,
    );

    if (snapshot.docs.isEmpty) {
      hasMoreComments.value = false;
      return;
    }

    final newComments = snapshot.docs
        .map((doc) => CommentModel.fromSnapshot(doc))
        .toList();

    // Sort by score = likes * 3 + replies * 1.5 - hours_since_posted * 0.1
    newComments.sort((a, b) => b.popularityScore.compareTo(a.popularityScore));

    await _preloadAuthorsForComments(newComments);

    if (lastCommentDoc == null) {
      comments.value = newComments;
    } else {
      comments.addAll(newComments);
    }

    lastCommentDoc = snapshot.docs.last;
    hasMoreComments.value = snapshot.docs.length == 20;
  }

  /// Fetch oldest comments
  Future<void> _fetchOldestComments() async {
    final snapshot = await commentRepo.fetchCommentsPaginated(
      postId: postId,
      limit: 20,
      startAfter: lastCommentDoc,
    );

    if (snapshot.docs.isEmpty) {
      hasMoreComments.value = false;
      return;
    }

    final newComments = snapshot.docs
        .map((doc) => CommentModel.fromSnapshot(doc))
        .toList();

    newComments.sort((a, b) {
      final aTime = a.updatedAt.isAfter(a.createdAt) ? a.updatedAt : a.createdAt;
      final bTime = b.updatedAt.isAfter(b.createdAt) ? b.updatedAt : b.createdAt;
      return aTime.compareTo(bTime); // ascending: older first
    });

    await _preloadAuthorsForComments(newComments);

    if (lastCommentDoc == null) {
      comments.value = newComments;
    } else {
      comments.addAll(newComments);
    }

    lastCommentDoc = snapshot.docs.last;
    hasMoreComments.value = snapshot.docs.length == 20;
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;
    final maxScroll = scrollController.position.maxScrollExtent;
    final current = scrollController.position.pixels;

    if (current >= maxScroll - 200) {
      loadMoreComments();
    }
  }

  Future<void> loadMoreComments() async {
    if (!hasMoreComments.value || isLoadingComments.value) return;

    if (currentSort.value == 'newest') {
      await _fetchPaginatedComments();
    } else if (currentSort.value == 'top') {
      await _fetchTopComments();
    } else if (currentSort.value == 'oldest') {
      await _fetchOldestComments();
    }
  }

  /// Create new comment with optimistic update
  Future<void> createComment() async {
    final contentError = CommunityValidator.validateCommentContent(commentText.text);
    if (contentError != null) {
      TLoaders.warningSnackBar(title: 'Invalid Comment', message: contentError);
      return;
    }

    final content = commentText.text.trim();
    if (!await _checkConnection()) return;

    // Optimistic update - Add to local list immediately
    final tempComment = CommentModel(
      commentId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      authorId: userController.user.value.userId,
      content: content,
      likes: const [],
      replyCount: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      isOptimistic: true, // Flag for UI
    );

    comments.insert(0, tempComment);
    commentText.clear();

    try {
      final actualCommentId = await commentRepo.createComment(
        content: content,
        postId: postId,
      );

      // Replace temp comment with actual one (if not using stream)
      if (currentSort.value != 'newest') {
        final index = comments.indexWhere((c) => c.commentId == tempComment.commentId);
        if (index != -1) {
          comments[index] = tempComment.copyWith(
            commentId: actualCommentId ?? tempComment.commentId,
            isOptimistic: false,
          );
        }
      }
      // If using stream, it will auto-update

      // 本地同步帖子上的 commentCount（乐观 + 与仓库里的 FieldValue.increment 对齐）
      PostController.instance.incrementCommentCount(postId);

      TLoaders.successSnackBar(title: 'Success', message: 'Comment posted');
    } catch (e) {
      // Remove optimistic comment on error
      comments.removeWhere((c) => c.commentId == tempComment.commentId);
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

  /// Update comment with optimistic update
  Future<void> updateComment() async {
    final contentError = CommunityValidator.validateCommentContent(commentText.text);
    if (contentError != null) {
      TLoaders.warningSnackBar(title: 'Invalid Comment', message: contentError);
      return;
    }

    final content = commentText.text.trim();
    if (editingCommentId.value == null || content.isEmpty || content == originalText.value) return;

    final commentId = editingCommentId.value!;
    final index = comments.indexWhere((c) => c.commentId == commentId);
    if (index == -1) return;

    // Optimistic update
    final oldComment = comments[index];
    comments[index] = oldComment.copyWith(
      content: content,
      updatedAt: DateTime.now(),
    );

    clearEditingState();

    try {
      await commentRepo.updateComment(commentId: commentId, content: content);
      TLoaders.successSnackBar(title: 'Success', message: 'Comment updated');
    } catch (e) {
      // Rollback on error
      comments[index] = oldComment;
      _showError('Failed to update comment');
    }
  }

  /// Delete comment with optimistic update
  void deleteCommentDialog(CommentModel comment) {
    TDialog.deleteDialog(
      title: 'Delete Comment',
      message: 'Are you sure you want to delete this comment?',
      onConfirm: () => _deleteComment(comment),
    );
  }

  Future<void> _deleteComment(CommentModel comment) async {
    // Optimistic removal
    final index = comments.indexWhere((c) => c.commentId == comment.commentId);
    if (index != -1) {
      comments.removeAt(index);
    }

    try {
      await commentRepo.deleteComment(comment.commentId);

      // 本地同步帖子上的 commentCount
      PostController.instance.decrementCommentCount(postId);

      TLoaders.successSnackBar(title: 'Success', message: 'Comment deleted');
    } catch (e) {
      // Rollback on error
      comments.insert(index, comment);
      _showError('Failed to delete comment');
    }
  }

  /// Toggle comment like with optimistic update
  Future<void> toggleCommentLike(CommentModel comment) async {
    final userId = userController.user.value.userId;
    final index = comments.indexWhere((c) => c.commentId == comment.commentId);
    if (index == -1) return;

    // Optimistic update
    final oldComment = comments[index];
    final newLikes = List<String>.from(oldComment.likes);

    if (newLikes.contains(userId)) {
      newLikes.remove(userId);
    } else {
      newLikes.add(userId);
    }

    comments[index] = oldComment.copyWith(likes: newLikes);

    try {
      await commentRepo.toggleCommentLike(
        commentId: comment.commentId,
        currentLikes: comment.likes,
      );
    } catch (e) {
      // Rollback on error
      comments[index] = oldComment;
      _showError('Failed to update like');
    }
  }

  /// =================== REPLIES SECTION =================== ///

  /// Fetch replies for a comment (real-time stream)
  void fetchReplies(String commentId) {
    if (repliesMap.containsKey(commentId)) {
      expandedReplies[commentId] = !(expandedReplies[commentId] ?? false);
      return;
    }

    loadingReplies[commentId] = true;
    repliesError[commentId] = '';

    try {
      repliesMap[commentId] = <ReplyModel>[].obs;
      repliesMap[commentId]!.bindStream(
          replyRepo.fetchReplies(parentCommentId: commentId)
      );
      expandedReplies[commentId] = true;
    } catch (e) {
      repliesError[commentId] = 'Failed to load replies';
    } finally {
      loadingReplies[commentId] = false;
    }
  }

  /// Create new reply with optimistic update
  Future<void> createReply(String parentCommentId) async {
    final contentError = CommunityValidator.validateReplyContent(commentText.text);
    if (contentError != null) {
      TLoaders.warningSnackBar(title: 'Invalid Reply', message: contentError);
      return;
    }

    final content = commentText.text.trim();
    if (!await _checkConnection()) return;

    // Optimistic update
    final tempReply = ReplyModel(
      replyId: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      authorId: userController.user.value.userId,
      content: content,
      likes: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
      isOptimistic: true,
    );

    if (repliesMap.containsKey(parentCommentId)) {
      repliesMap[parentCommentId]!.add(tempReply);
    }

    // Update reply count optimistically
    final commentIndex = comments.indexWhere((c) => c.commentId == parentCommentId);
    if (commentIndex != -1) {
      comments[commentIndex] = comments[commentIndex].copyWith(
        replyCount: comments[commentIndex].replyCount + 1,
      );
    }

    commentText.clear();

    try {
      await replyRepo.createReply(
        content: content,
        parentCommentId: parentCommentId,
      );
      TLoaders.successSnackBar(title: 'Success', message: 'Reply posted');
    } catch (e) {
      // Rollback on error
      if (repliesMap.containsKey(parentCommentId)) {
        repliesMap[parentCommentId]!.removeWhere((r) => r.replyId == tempReply.replyId);
      }
      if (commentIndex != -1) {
        comments[commentIndex] = comments[commentIndex].copyWith(
          replyCount: comments[commentIndex].replyCount - 1,
        );
      }
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

  /// Update reply with optimistic update
  Future<void> updateReply() async {
    final contentError = CommunityValidator.validateReplyContent(commentText.text);
    if (contentError != null) {
      TLoaders.warningSnackBar(title: 'Invalid Reply', message: contentError);
      return;
    }

    final content = commentText.text.trim();
    if (editingReplyId.value == null || editingParentCommentId.value == null ||
        content.isEmpty || content == originalText.value) return;

    final replyId = editingReplyId.value!;
    final parentCommentId = editingParentCommentId.value!;

    if (!repliesMap.containsKey(parentCommentId)) return;

    final replies = repliesMap[parentCommentId]!;
    final index = replies.indexWhere((r) => r.replyId == replyId);
    if (index == -1) return;

    // Optimistic update
    final oldReply = replies[index];
    replies[index] = oldReply.copyWith(
      content: content,
      updatedAt: DateTime.now(),
    );

    clearEditingState();

    try {
      await replyRepo.updateReply(
        replyId: replyId,
        parentCommentId: parentCommentId,
        content: content,
      );
      TLoaders.successSnackBar(title: 'Success', message: 'Reply updated');
    } catch (e) {
      // Rollback on error
      replies[index] = oldReply;
      _showError('Failed to update reply');
    }
  }

  /// Delete reply with optimistic update
  void deleteReplyDialog(ReplyModel reply, String parentCommentId) {
    TDialog.deleteDialog(
      title: 'Delete Reply',
      message: 'Are you sure you want to delete this reply?',
      onConfirm: () => _deleteReply(reply, parentCommentId),
    );
  }

  Future<void> _deleteReply(ReplyModel reply, String parentCommentId) async {
    if (!repliesMap.containsKey(parentCommentId)) return;

    final replies = repliesMap[parentCommentId]!;
    final index = replies.indexWhere((r) => r.replyId == reply.replyId);
    if (index != -1) {
      replies.removeAt(index);
    }

    // Update reply count
    final commentIndex = comments.indexWhere((c) => c.commentId == parentCommentId);
    if (commentIndex != -1) {
      comments[commentIndex] = comments[commentIndex].copyWith(
        replyCount: comments[commentIndex].replyCount - 1,
      );
    }

    try {
      await replyRepo.deleteReply(
        replyId: reply.replyId,
        parentCommentId: parentCommentId,
      );
      TLoaders.successSnackBar(title: 'Success', message: 'Reply deleted');
    } catch (e) {
      // Rollback on error
      replies.insert(index, reply);
      if (commentIndex != -1) {
        comments[commentIndex] = comments[commentIndex].copyWith(
          replyCount: comments[commentIndex].replyCount + 1,
        );
      }
      _showError('Failed to delete reply');
    }
  }

  /// Toggle reply like with optimistic update
  Future<void> toggleReplyLike(ReplyModel reply, String parentCommentId) async {
    final userId = userController.user.value.userId;
    if (!repliesMap.containsKey(parentCommentId)) return;

    final replies = repliesMap[parentCommentId]!;
    final index = replies.indexWhere((r) => r.replyId == reply.replyId);
    if (index == -1) return;

    // Optimistic update
    final oldReply = replies[index];
    final newLikes = List<String>.from(oldReply.likes);

    if (newLikes.contains(userId)) {
      newLikes.remove(userId);
    } else {
      newLikes.add(userId);
    }

    replies[index] = oldReply.copyWith(likes: newLikes);

    try {
      await replyRepo.toggleReplyLike(
        replyId: reply.replyId,
        parentCommentId: parentCommentId,
        currentLikes: reply.likes,
      );
    } catch (e) {
      // Rollback on error
      replies[index] = oldReply;
      _showError('Failed to update like');
    }
  }

  /// =================== UI ACTIONS =================== ///

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

  Future<void> cancelEdit() async {
    if (_hasUnsavedChanges()) {
      final shouldDiscard = await _showDiscardDialog();
      if (!shouldDiscard) return;
    }
    clearEditingState();
  }

  void sortComments(String sortType) {
    if (currentSort.value == sortType) return;

    currentSort.value = sortType;
    fetchComments(refresh: true);
  }

  /// =================== HELPER METHODS =================== ///

  bool isOwner(String authorId) => userController.user.value.userId == authorId;

  bool get isEditing => editingCommentId.value != null || editingReplyId.value != null;

  String get submitButtonText {
    if (editingCommentId.value != null || editingReplyId.value != null) {
      return 'Update';
    }
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

  void clearEditingState() {
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

  List<ReplyModel> getReplies(String commentId) {
    return repliesMap[commentId]?.toList() ?? [];
  }

  bool areRepliesExpanded(String commentId) {
    return expandedReplies[commentId] ?? false;
  }

  bool areRepliesLoading(String commentId) {
    return loadingReplies[commentId] ?? false;
  }
}