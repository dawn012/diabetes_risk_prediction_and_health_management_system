import { onRequest } from "firebase-functions/v2/https";
import express from "express";
import cors from "cors";

const app = express();
app.use(cors({origin: true}));

app.get("/", (req, res) => {
  res.status(200).json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    service: "health-check"
  });
});

app.get("/health", (req, res) => {
  res.status(200).json({ status: "healthy" });
});

// ✅ 使用 v2 的 onRequest
export const health = onRequest({
  region: "us-central1",
  timeoutSeconds: 60,
  memory: "256MiB"
}, app);