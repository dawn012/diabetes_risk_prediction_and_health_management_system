const admin = require("firebase-admin");
const { updateReplyCountOnCreate, updateReplyCountOnDelete } = require("./comments");

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

// 正确导出 Cloud Functions
module.exports = { updateReplyCountOnCreate, updateReplyCountOnDelete };

