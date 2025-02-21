import mongoose from 'mongoose';
import dotenv from 'dotenv';

dotenv.config(); // 读取 .env 文件中的配置

const dbURI: string = process.env.MONGO_URI as string; // 从环境变量获取连接字符串

const connectDB = async (retries = 5) => {
  while (retries) {
    try {
      const conn = await mongoose.connect(dbURI, {
        dbName: 'diatrack', // 指定数据库名称
      });
      console.log(`MongoDB Connected: ${conn.connection.host}`);
      return;
    } catch (error) {
      console.error(`Database connection failed. Retries left: ${retries}`, error);
      retries--;
      await new Promise((res) => setTimeout(res, 5000)); // 5秒后重试
    }
  }
  process.exit(1); // 连接失败，终止进程
};

export default connectDB;
