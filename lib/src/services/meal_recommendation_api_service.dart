import 'dart:convert';
import 'package:http/http.dart' as http;

class MealRecommendationApiService {
  // API base URL
  static const String baseUrl = 'http://192.168.45.188:5000';

  /// 生成每日餐食计划
  ///
  /// Parameters:
  /// - userPreferences: 用户偏好设置
  /// - userId: 用户ID
  /// - pastRecipeIds: 过去的食谱ID列表（用于避免重复）
  static Future<Map<String, dynamic>> generateDailyPlan({
    required Map<String, dynamic> userPreferences,
    String? userId,
    List<String>? pastRecipeIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/generate_daily_plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_preferences': userPreferences,
          'user_id': userId,
          'past_recipe_ids': pastRecipeIds ?? [],
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate daily plan: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating daily plan: $e');
    }
  }

  /// 生成每周餐食计划
  static Future<Map<String, dynamic>> generateWeeklyPlan({
    required Map<String, dynamic> userPreferences,
    String? userId,
    List<String>? pastRecipeIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/generate_weekly_plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_preferences': userPreferences,
          'user_id': userId,
          'past_recipe_ids': pastRecipeIds ?? [],
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate weekly plan: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating weekly plan: $e');
    }
  }

  /// 替换特定餐食
  ///
  /// Parameters:
  /// - mealType: 餐食类型 (breakfast, lunch, dinner, snack)
  /// - userPreferences: 用户偏好
  /// - currentPlanRecipeIds: 当前计划中的所有食谱ID
  /// - day: 周计划中的天数 (可选)
  /// - pastRecipeIds: 过去的食谱ID列表（用于避免重复）
  static Future<Map<String, dynamic>> replaceMeal({
    required String mealType,
    required Map<String, dynamic> userPreferences,
    required List<String> currentPlanRecipeIds,
    String? replacedRecipeId,
    String? day,
    String? userId,
    List<String>? pastRecipeIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/replace_meal'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'meal_type': mealType,
          'day': day,
          'user_preferences': userPreferences,
          'current_plan_recipe_ids': currentPlanRecipeIds,
          'replaced_recipe_id': replacedRecipeId,
          'past_recipe_ids': pastRecipeIds ?? [],
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to replace meal: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error replacing meal: $e');
    }
  }

  /// 重新生成计划（保留部分食谱）
  static Future<Map<String, dynamic>> regeneratePlan({
    required Map<String, dynamic> userPreferences,
    required List<String> currentPlanRecipeIds,
    required String planType,
    double keepRatio = 0.5,
    String? userId,
    List<String>? pastRecipeIds,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/regenerate_plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'user_preferences': userPreferences,
          'current_plan_recipe_ids': currentPlanRecipeIds,
          'plan_type': planType,
          'keep_ratio': keepRatio,
          'past_recipe_ids': pastRecipeIds ?? [],
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to regenerate plan: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error regenerating plan: $e');
    }
  }

  /// 生成考虑历史的新计划
  static Future<Map<String, dynamic>> generateNewPlanWithHistory({
    required Map<String, dynamic> userPreferences,
    required String userId,
    required List<String> pastRecipeIds,
    required String planType,
    double overlapRatio = 0.4, // 最多40%重复率
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/generate_new_plan_with_history'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'user_preferences': userPreferences,
          'past_recipe_ids': pastRecipeIds,
          'plan_type': planType,
          'overlap_ratio': overlapRatio,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to generate new plan with history: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating new plan with history: $e');
    }
  }

  /// 健康检查
  static Future<Map<String, dynamic>> healthCheck() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Health check failed: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during health check: $e');
    }
  }
}