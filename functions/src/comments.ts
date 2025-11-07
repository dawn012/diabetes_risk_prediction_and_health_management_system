import { onDocumentCreated, onDocumentDeleted } from "firebase-functions/v2/firestore";
import { getFirestore, FieldValue, DocumentReference } from "firebase-admin/firestore";
import * as admin from "firebase-admin";

// 初始化 Firebase Admin（防止重复初始化）
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = getFirestore();

// ✅ 监听 Firestore "comments/{commentId}/replies/{replyId}" 的创建事件
export const updateReplyCountOnCreate = onDocumentCreated(
  "comments/{commentId}/replies/{replyId}",
  async (event) => {
    const commentId = event.params.commentId as string;
    if (!commentId) return;

    const commentRef: DocumentReference = db.collection("comments").doc(commentId);
    await commentRef.update({
      replyCount: FieldValue.increment(1),
    });
  }
);

// ✅ 监听 Firestore "comments/{commentId}/replies/{replyId}" 的删除事件
export const updateReplyCountOnDelete = onDocumentDeleted(
  "comments/{commentId}/replies/{replyId}",
  async (event) => {
    const commentId = event.params.commentId as string;
    if (!commentId) return;

    const commentRef: DocumentReference = db.collection("comments").doc(commentId);
    await commentRef.update({
      replyCount: FieldValue.increment(-1),
    });
  }
);

// ✅ 监听 Firestore "comments/{commentId}" 的删除事件，同时删除所有 replies
export const deleteCommentAndReplies = onDocumentDeleted(
  "comments/{commentId}",
  async (event) => {
    const commentId = event.params.commentId as string;
    if (!commentId) return;

    const repliesRef = db.collection("comments").doc(commentId).collection("replies");
    const repliesSnapshot = await repliesRef.get();

    const batch = db.batch();
    repliesSnapshot.forEach((doc) => {
      batch.delete(doc.ref);
    });

    return batch.commit();
  }
);
