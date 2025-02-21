// import http from "http"

// http.createServer(function (req, res) {
//     res.write("API IS RUNNING");
//     res.end();
//     }).listen(8081);

// http.createServer(function (req, res) {
//     res.writeHead(200, {
//         "Content-Type": "text/html",
//     }),
//     res.write("API IS RUNNING");
//     res.end();
//     }).listen(8000);

// import express, { Request, Response } from "express";
// import { router } from "./routing/routes";

import express from 'express';
import cors from 'cors';
import bodyParser from 'body-parser';
import helmet from 'helmet';
import morgan from 'morgan';
// import userRoutes from './routing/user.routes';
// import authRoutes from './routing/auth.routes';

const app = express();

// 1. 安全性中间件
app.use(helmet()); // 保护 HTTP 头信息
app.use(cors()); // 允许跨域请求
app.use(morgan('dev')); // 记录 HTTP 请求日志

// 2. 解析请求体
app.use(bodyParser.json()); // 解析 JSON
app.use(bodyParser.urlencoded({ extended: true })); // 解析 URL 编码的数据

// 3. 加载路由
// app.use('/api/users', userRoutes);
// app.use('/api/auth', authRoutes);

// 4. 主页路由
app.get('/', (req, res) => {
  res.send('Diabetes Risk Prediction and Health Management System API');
});

export default app;

// // register view engine
// app.set('view engine', 'ejs');
//
// // listen for request
// app.listen(3000);