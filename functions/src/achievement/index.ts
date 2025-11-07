/**
 * 成就模块入口文件 - 完整版
 * 导出所有成就相关的功能
 */

// 配置服务
export {
  getAchievementConfigs,
  clearAchievementConfigCache,
} from "./config/achievement_config";

export type { AchievementConfig } from "./config/achievement_config";

// 核心服务
export { HealthLogAchievementService } from "./services/health_log_achievement_service";
export { CommunityAchievementService } from "./services/community_achievement_service";

// 工具函数
export { DateUtils } from "./utils/date_utils";

// 健康数据触发器
export {
  onHealthLogCreated,
  onHealthLogUpdated,
  onHealthLogDeleted,
} from "./triggers/health_data_triggers";

// 社区数据触发器
export {
  onPostCreated,
  onCommentCreated,
  onReplyCreated,
} from "./triggers/community_triggers";

// 定时任务
export {
  monthlyAchievementReset,
  hourlySyncCheck,
  dailyPermanentAchievementUpdate,
} from "./triggers/scheduled_tasks";
