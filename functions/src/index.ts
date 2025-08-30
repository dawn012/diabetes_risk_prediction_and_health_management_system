import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
// const { updateReplyCountOnCreate, updateReplyCountOnDelete, deleteCommentAndReplies } = require("./comments");

// 初始化 Firebase Admin（防止多次初始化）
if (admin.apps.length === 0) {
  admin.initializeApp();
}

/*
 // 错误写法
 const { initializeApp } = require('firebase-admin');

 // 直接调用被解构的方法
 initializeApp(); // ❌ TypeError: Cannot read properties of undefined (reading 'INTERNAL')

 发生错误的原因
 firebase-admin 默认导出的是一个类的实例，而不是一个普通的对象或模块。
 当你解构或单独提取 initializeApp 方法时，它会失去 this 的上下文，导致 this.INTERNAL 变成 undefined。
 由于 initializeApp 依赖 this，所以它会报错。
*/

// 导入其他文件的 Cloud Functions
import * as authentication from "./authentication";
import * as comments from "./comments";

export const {
  setDefaultUserRole,
  addUserWithRole
} = authentication;

export const {
  updateReplyCountOnCreate,
  updateReplyCountOnDelete,
  deleteCommentAndReplies
} = comments;

export const setAdminClaim = functions.https.onRequest(async (req, res) => {
  try {
    // 你可以通过 query 或 body 获取 uid
    const uid = req.query.uid as string || req.body.uid;
    if (!uid) {
      res.status(400).send("Missing UID");
      return;
    }

    // 设置 custom claims
    await admin.auth().setCustomUserClaims(uid, { role: "admin" });
    console.log(`Custom claim 'admin' set for user ${uid}`);

    // 标记 emailVerified
    await admin.auth().updateUser(uid, { emailVerified: true });
    console.log(`Email verified set for user ${uid}`);

    res.status(200).send(`User ${uid} updated: admin + emailVerified`);
  } catch (error) {
    console.error(error);
    res.status(500).send(error);
  }
});

// 正确导出 Cloud Functions
// module.exports = { updateReplyCountOnCreate, updateReplyCountOnDelete, deleteCommentAndReplies };

