// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
//
// import '../../../navigation_menu.dart';
// import '../../services/tutorial_flow_manager.dart';
//
// /// Dashboard 教学配置
// class DashboardTutorialConfig {
//   // 教学步骤所需的 GlobalKey
//   static final dashboardKey = GlobalKey();
//   static final addButtonKey = GlobalKey();
//   static final glucoseCardKey = GlobalKey();
//   static final mealPlanKey = GlobalKey();
//   static final communityKey = GlobalKey();
//
//   /// 获取完整的教学步骤列表
//   static List<TutorialStep> getTutorialSteps() {
//     return [
//       // 1. 欢迎和 Dashboard 介绍
//       TutorialStep(
//         id: 'welcome',
//         title: '👋 Welcome to Diatrack!',
//         description:
//         'Let\'s take a quick tour to help you get started with tracking your health.',
//         position: TutorialPosition.center,
//       ),
//
//       TutorialStep(
//         id: 'dashboard_intro',
//         title: '🏠 Your Health Dashboard',
//         description:
//         'This is your main control center. Here you can view your daily health status, diabetes risk, blood glucose, blood pressure, weight, body fat, and daily activity records.',
//         targetKey: dashboardKey,
//         position: TutorialPosition.center,
//         autoNextDelay: const Duration(seconds: 5),
//       ),
//
//       // 2. 如何添加健康记录
//       TutorialStep(
//         id: 'add_button_intro',
//         title: '➕ Add Health Records',
//         description:
//         'Tap this button to add health records including blood glucose, exercise, blood pressure, and weight.',
//         targetKey: addButtonKey,
//         position: TutorialPosition.top,
//         requiresAction: true,
//       ),
//
//       TutorialStep(
//         id: 'add_menu_shortcuts',
//         title: '⚡ Quick Entry Shortcuts',
//         description:
//         'These are quick shortcuts to add different types of health records. Click on any icon to quickly log your data.',
//         position: TutorialPosition.center,
//         requiresAction: true,
//       ),
//
//       TutorialStep(
//         id: 'add_glucose_action',
//         title: '🩸 Add Glucose Record',
//         description:
//         'Now, let\'s add a glucose record. The form will automatically expand the glucose section for you.',
//         position: TutorialPosition.center,
//         requiresAction: true,
//       ),
//
//       // 3. 查看数据和图表
//       TutorialStep(
//         id: 'view_glucose_card',
//         title: '📊 View Your Data',
//         description:
//         'Great! Now you can see your glucose data displayed here with charts. Tap this card to see detailed analytics.',
//         targetKey: glucoseCardKey,
//         position: TutorialPosition.bottom,
//         requiresAction: true,
//       ),
//
//       TutorialStep(
//         id: 'analytics_screen_intro',
//         title: '📈 Analytics Screen',
//         description:
//         'Here you can see detailed analytics of your blood glucose data, including trends, statistics, and distribution.',
//         position: TutorialPosition.center,
//       ),
//
//       TutorialStep(
//         id: 'statistics_interaction',
//         title: '🎯 Interactive Statistics',
//         description:
//         'Tap on "Highest" to see your highest glucose records, "Lowest" for lowest records, and "Average" to see all records.',
//         position: TutorialPosition.center,
//       ),
//
//       TutorialStep(
//         id: 'distribution_interaction',
//         title: '🥧 Distribution Chart',
//         description:
//         'You can also tap on the distribution chart. Tap "Normal" to see normal records, "High" for high records, "Low" for low records, or "Total" to see all records.',
//         position: TutorialPosition.center,
//       ),
//
//       TutorialStep(
//         id: 'delete_record',
//         title: '🗑️ Delete Records',
//         description:
//         'You can delete a record by tapping on it in the list and then tapping the delete button. Let\'s try deleting the record you just created.',
//         position: TutorialPosition.center,
//         requiresAction: true,
//       ),
//
//       // 4. 糖尿病风险预测
//       TutorialStep(
//         id: 'predict_risk_intro',
//         title: '🔮 Predict Diabetes Risk',
//         description:
//         'Now let\'s learn about the diabetes risk prediction feature. Tap the add button again to access it.',
//         position: TutorialPosition.center,
//         requiresAction: true,
//       ),
//
//       TutorialStep(
//         id: 'predict_risk_start',
//         title: '🎯 Risk Assessment',
//         description:
//         'This feature helps you assess your diabetes risk. Tap "Let\'s Start" to begin the assessment.',
//         position: TutorialPosition.center,
//         requiresAction: true,
//       ),
//
//       TutorialStep(
//         id: 'assessment_overview',
//         title: '📋 Assessment Overview',
//         description:
//         'To predict your risk, you need to complete 8 steps. You can tap on any step to update it without having to re-enter all steps every time.',
//         position: TutorialPosition.center,
//       ),
//
//       // 5. 餐饮计划
//       TutorialStep(
//         id: 'meal_plan_intro',
//         title: '🍽️ Meal Plan',
//         description:
//         'Tap here to access meal plan recommendations. Note: This feature requires a subscription plan.',
//         targetKey: mealPlanKey,
//         position: TutorialPosition.top,
//         requiresAction: true,
//       ),
//
//       // 6. 社区功能
//       TutorialStep(
//         id: 'community_intro',
//         title: '👥 Community',
//         description:
//         'Here you can share your goals, thoughts, and experiences with peers. Connect with others on their health journey!',
//         targetKey: communityKey,
//         position: TutorialPosition.top,
//         requiresAction: true,
//       ),
//
//       // 7. 结束
//       TutorialStep(
//         id: 'tutorial_complete',
//         title: '🎉 Tutorial Complete!',
//         description:
//         'You\'re all set! You can now start tracking your health data. If you need help, you can always access the tutorial again from Settings.',
//         position: TutorialPosition.center,
//       ),
//     ];
//   }
//
//   /// 开始 Dashboard 教学
//   static void startDashboardTutorial() {
//     final tutorialService = TutorialService.instance;
//
//     // 检查是否已完成教学
//     if (tutorialService.hasCompletedTutorial()) {
//       print('Tutorial already completed');
//       return;
//     }
//
//     // 延迟启动，确保页面已完全加载
//     Future.delayed(const Duration(milliseconds: 500), () {
//       tutorialService.startTutorial(getTutorialSteps());
//     });
//   }
//
//   /// 处理教学步骤的特定动作
//   static void handleTutorialAction(String stepId) {
//     final tutorialService = TutorialService.instance;
//
//     switch (stepId) {
//       case 'add_button_intro':
//       // 用户需要点击添加按钮
//       // 在 NavigationMenu 的 FAB onPressed 中检测并继续
//         break;
//
//       case 'add_menu_shortcuts':
//       // 显示添加菜单后的说明
//         tutorialService.nextStep();
//         break;
//
//       case 'add_glucose_action':
//       // 引导用户点击 Glucose 快捷方式
//       // 检测到点击后跳转到 HealthDataEntryScreen
//         break;
//
//       case 'view_glucose_card':
//       // 用户需要点击 glucose card
//       // 在 Dashboard 的 glucose card onTap 中检测并继续
//         break;
//
//       case 'delete_record':
//       // 引导用户删除记录
//       // 检测到删除后继续
//         break;
//
//       case 'predict_risk_intro':
//       // 用户需要再次点击添加按钮
//         break;
//
//       case 'predict_risk_start':
//       // 用户需要点击 "Let's Start"
//         break;
//
//       case 'meal_plan_intro':
//       // 用户需要点击 Meal Plan
//         break;
//
//       case 'community_intro':
//       // 用户需要点击 Community
//         break;
//
//       default:
//         break;
//     }
//   }
// }