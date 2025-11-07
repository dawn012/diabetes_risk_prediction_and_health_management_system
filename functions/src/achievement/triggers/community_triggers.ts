/**
 * Community 触发器 (重构版)
 * 监听帖子、评论、回复的创建，触发成就更新
 */

import { onDocumentCreated } from "firebase-functions/v2/firestore";
import * as functions from "firebase-functions";
import { CommunityAchievementService } from "../services/community_achievement_service";

/**
 * 监听帖子创建
 */
export const onPostCreated = onDocumentCreated(
  "posts/{postId}",
  async (event) => {
    const postData = event.data?.data();
    if (!postData) return;

    const userId = postData.posterId;
    const postType = postData.postType;

    functions.logger.log(
      `📝 Post created by user: ${userId}, type: ${postType}`
    );

    try {
      // 🆕 统一处理帖子创建的成就更新（包括 periodic 和 permanent）
      await CommunityAchievementService.handlePostCreated(userId, postType);

      functions.logger.log(
        `✅ All achievements updated for post creation by ${userId}`
      );
    } catch (error) {
      functions.logger.error(
        "❌ Error updating achievements for post creation:",
        error
      );
    }
  }
);

/**
 * 监听评论创建
 */
export const onCommentCreated = onDocumentCreated(
  "comments/{commentId}",
  async (event) => {
    const commentData = event.data?.data();
    if (!commentData) return;

    const userId = commentData.authorId;

    functions.logger.log(`💬 Comment created by user: ${userId}`);

    try {
      // 🆕 统一处理评论创建的成就更新（包括 periodic 和 permanent）
      await CommunityAchievementService.handleCommentCreated(userId);

      functions.logger.log(
        `✅ All achievements updated for comment creation by ${userId}`
      );
    } catch (error) {
      functions.logger.error(
        "❌ Error updating achievements for comment creation:",
        error
      );
    }
  }
);

/**
 * 监听回复创建
 */
export const onReplyCreated = onDocumentCreated(
  "comments/{commentId}/replies/{replyId}",
  async (event) => {
    const replyData = event.data?.data();
    if (!replyData) return;

    const userId = replyData.authorId;

    functions.logger.log(`↩️ Reply created by user: ${userId}`);

    try {
      // 🆕 回复也算评论，使用相同的处理逻辑
      await CommunityAchievementService.handleCommentCreated(userId);

      functions.logger.log(
        `✅ All achievements updated for reply creation by ${userId}`
      );
    } catch (error) {
      functions.logger.error(
        "❌ Error updating achievements for reply creation:",
        error
      );
    }
  }
);