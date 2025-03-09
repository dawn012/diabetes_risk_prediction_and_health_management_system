const { onDocumentCreated, onDocumentDeleted } = require("firebase-functions/v2/firestore");
const { getFirestore, FieldValue } = require("firebase-admin/firestore");
const admin = require("firebase-admin");

// 初始化 Firebase Admin
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = getFirestore();

// ✅ 监听 Firestore "comments/{commentId}/replies/{replyId}" 的创建事件
export const updateReplyCountOnCreate = onDocumentCreated("comments/{commentId}/replies/{replyId}", async (event: any) => {
  const commentId = event.params.commentId;
  if (!commentId) return;

  const commentRef = db.collection("comments").doc(commentId);
  await commentRef.update({
    reply_count: FieldValue.increment(1),
  });
});

// ✅ 监听 Firestore "comments/{commentId}/replies/{replyId}" 的删除事件
export const updateReplyCountOnDelete = onDocumentDeleted("comments/{commentId}/replies/{replyId}", async (event: any) => {
  const commentId = event.params.commentId;
  if (!commentId) return;

  const commentRef = db.collection("comments").doc(commentId);
  await commentRef.update({
    reply_count: FieldValue.increment(-1),
  });
});

// module.exports = { updateReplyCountOnCreate, updateReplyCountOnDelete };
