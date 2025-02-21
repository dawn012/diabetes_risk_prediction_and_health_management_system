import http from 'http';
import dotenv from 'dotenv';
import app from './app';
import connectDB from './config/db';

dotenv.config(); // 加载环境变量
const PORT = process.env.PORT || 5000;

// 连接数据库
connectDB();

const server = http.createServer(app);

server.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
});
