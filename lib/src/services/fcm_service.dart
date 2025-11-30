import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';

import '../features/reminder/controllers/reminder_controller.dart';
import '../features/reminder/views/reminder_screen.dart';

@pragma('vm:entry-point')
class FCMService {
  static final FCMService _instance = FCMService._internal();
  @pragma('vm:entry-point')
  factory FCMService() => _instance;
  @pragma('vm:entry-point')
  FCMService._internal();

  // ✅ FIX: Make Firebase instances lazy and nullable
  FirebaseMessaging? _messaging;
  FirebaseFirestore? _firestore;
  FirebaseFunctions? _functions;
  FirebaseAuth? _auth;
  late FlutterLocalNotificationsPlugin _localNotifications;

  static const String _lastUserIdKey = 'last_user_id';
  static const String _channelId = 'reminder_notifications';
  static const String _channelName = 'Reminder Notifications';

  bool _isInitialized = false;

  // ✅ FIX: Lazy getters for Firebase instances
  FirebaseMessaging get messaging => _messaging ??= FirebaseMessaging.instance;
  FirebaseFirestore get firestore => _firestore ??= FirebaseFirestore.instance;
  FirebaseFunctions get functions => _functions ??= FirebaseFunctions.instance;
  FirebaseAuth get auth => _auth ??= FirebaseAuth.instance;

  /// Initialize FCM for reminders
  @pragma('vm:entry-point')
  Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ FCM Service already initialized');
      return;
    }

    try {
      // ✅ Ensure Firebase is initialized
      await _ensureFirebaseInitialized();

      await _initializeLocalNotifications();

      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        announcement: false,
      );

      await _getAndSaveFCMToken();
      _setupMessageHandlers();
      _setupAuthStateListener();

      _isInitialized = true;
      print('✅ Reminder FCM initialized successfully');
    } catch (e) {
      print('❌ Error initializing Reminder FCM: $e');
    }
  }

  /// Ensure Firebase is initialized before use
  @pragma('vm:entry-point')
  static Future<void> _ensureFirebaseInitialized() async {
    try {
      await Firebase.initializeApp();
      print('✅ Firebase initialized');
    } catch (e) {
      if (e.toString().contains('duplicate-app')) {
        print('⚠️ Firebase already initialized');
      } else {
        print('❌ Error initializing Firebase: $e');
        rethrow;
      }
    }
  }

  /// Initialize local notifications with action buttons
  @pragma('vm:entry-point')
  Future<void> _initializeLocalNotifications() async {
    _localNotifications = FlutterLocalNotificationsPlugin();

    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosSettings =
    DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
    InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: _handleNotificationResponse,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  /// Static handler that ensures Firebase initialization
  @pragma('vm:entry-point')
  static Future<void> _handleNotificationResponse(NotificationResponse response) async {
    print('🔔 Notification Response Received');
    print('Action ID: ${response.actionId}');
    print('Payload: ${response.payload}');

    // Ensure Firebase is initialized before processing
    await _ensureFirebaseInitialized();

    // Process the action
    await FCMService._instance._processNotificationAction(response);
  }

  /// Process notification actions
  @pragma('vm:entry-point')
  Future<void> _processNotificationAction(NotificationResponse response) async {
    final actionId = response.actionId;

    print('📲 Processing notification action');
    print('Action ID: $actionId');
    print('Payload: ${response.payload}');

    // Parse payload
    Map<String, dynamic>? payloadMap;
    if (response.payload != null) {
      try {
        payloadMap = jsonDecode(response.payload!) as Map<String, dynamic>;
        print('✅ Parsed payload: $payloadMap');
      } catch (e) {
        print('❌ Failed to parse notification payload: $e');
        return;
      }
    }

    final reminderId = payloadMap?['reminderId'];
    final scheduleId = payloadMap?['scheduleId'];
    final snoozeDuration = int.tryParse(payloadMap?['snoozeDuration'] ?? '5') ?? 5;

    if (reminderId == null || scheduleId == null) {
      print('❌ Missing reminderId or scheduleId');
      return;
    }

    // Handle different actions
    if (actionId == null || actionId.isEmpty) {
      // User tapped on the notification body
      print('👆 User tapped notification body');
      _handleNotificationTap(payloadMap);
    } else if (actionId == 'snooze_action') {
      // User tapped Snooze button
      print('⏰ User tapped Snooze button');
      await _handleSnooze(reminderId, scheduleId, snoozeDuration);
    } else if (actionId == 'dismiss_action') {
      // User tapped Dismiss button
      print('✅ User tapped Dismiss button');
      await _handleDismiss(reminderId, scheduleId);
    } else {
      print('⚠️ Unknown action ID: $actionId');
    }
  }

  /// Handle notification tap (navigate to details page)
  @pragma('vm:entry-point')
  void _handleNotificationTap(Map<String, dynamic>? data) {
    if (data == null) {
      print('⚠️ Notification data is null');
      return;
    }

    final type = data['type'];
    final reminderId = data['reminderId'];

    print('👆 Notification tapped');
    print('Type: $type');
    print('Reminder ID: $reminderId');

    if (type == 'reminder_notification' && reminderId != null) {
      // 🔧 同样使用延迟执行
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          if (Get.context != null) {
            Get.to(() => const ReminderScreen());
          } else {
            Future.delayed(const Duration(seconds: 1), () {
              if (Get.context != null) {
                Get.to(() => const ReminderScreen());
              }
            });
          }
        } catch (e) {
          print('❌ Error navigating to reminder screen: $e');
        }
      });
    }
  }

  /// Create notification channel with action buttons
  @pragma('vm:entry-point')
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Notifications for health reminders',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Get and save FCM token
  @pragma('vm:entry-point')
  Future<void> _getAndSaveFCMToken() async {
    try {
      String? token = await messaging.getToken();

      if (token != null) {
        await _saveTokenToFirestore(token);
        print('Reminder FCM Token: $token');
      }

      messaging.onTokenRefresh.listen((newToken) {
        _saveTokenToFirestore(newToken);
        print('Reminder FCM Token refreshed: $newToken');
      });
    } catch (e) {
      print('Error getting Reminder FCM token: $e');
    }
  }

  /// Save token to Firestore
  @pragma('vm:entry-point')
  Future<void> _saveTokenToFirestore(String token) async {
    try {
      String? userId = _getCurrentUserId();

      if (userId != null) {
        await firestore.collection('users').doc(userId).set({
          'fcmTokens': FieldValue.arrayUnion([token]),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        print('Reminder FCM token saved for user $userId');
      }
    } catch (e) {
      print('Error saving Reminder FCM token: $e');
    }
  }

  /// Get current user ID
  @pragma('vm:entry-point')
  String? _getCurrentUserId() {
    try {
      return auth.currentUser?.uid;
    } catch (e) {
      print('Error getting current user ID: $e');
      return null;
    }
  }

  /// Setup message handlers
  @pragma('vm:entry-point')
  void _setupMessageHandlers() {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground reminder, data: ${message.data}');
      showLocalNotification(message);
    });

    // Background message opened
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('App opened from background reminder, data: ${message.data}');
      _handleNotificationClick(message.data);
    });

    // Terminated state message
    messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        print('App opened from terminated state, data: ${message.data}');
        _handleNotificationClick(message.data);
      }
    });
  }

  /// Setup auth state listener
  @pragma('vm:entry-point')
  void _setupAuthStateListener() {
    auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        print('User logged in, refreshing Reminder FCM token');
        await _saveUserId(user.uid);
        _getAndSaveFCMToken();
      } else {
        print('User logged out');
        _clearTokensOnLogout();
      }
    });
  }

  /// Display a local notification with action buttons
  @pragma('vm:entry-point')
  Future<void> showLocalNotification(RemoteMessage message) async {
    final data = message.data;
    final reminderId = data['reminderId'];
    final scheduleId = data['scheduleId'];
    final snoozeDuration = int.tryParse(data['snoozeDuration'] ?? '5') ?? 5;

    // 从 data 取标题和内容（Cloud Function 已经塞进 data 里了）
    final title = data['reminderTitle'] ?? 'Reminder';
    final body = data['reminderDescription'] ?? 'Time to track your health!';

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Notifications for health reminders',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      actions: <AndroidNotificationAction>[
        AndroidNotificationAction(
          'snooze_action',
          'Snooze ${snoozeDuration}m',
          showsUserInterface: false,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'dismiss_action',
          'Dismiss',
          showsUserInterface: false,
          cancelNotification: true,
        ),
      ],
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      categoryIdentifier: 'reminder_category',
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode({
      'type': 'reminder_notification',
      'reminderId': reminderId,
      'scheduleId': scheduleId,
      'snoozeDuration': snoozeDuration.toString(),
      'timestamp': DateTime.now().toIso8601String(),
    });

    print('📤 Showing notification with payload: $payload');

    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _localNotifications.show(
      notificationId,
      title, // 不再用 message.notification?.title
      body,  // 不再用 message.notification?.body
      details,
      payload: payload,
    );
    print('✅ Notification shown with ID: $notificationId');
  }

  /// Handle Snooze action (calls Cloud Function)
  @pragma('vm:entry-point')
  Future<void> _handleSnooze(String reminderId, String scheduleId, int snoozeDuration) async {
    print('🔄 Snoozing reminder...');
    print('Reminder ID: $reminderId');
    print('Schedule ID: $scheduleId');
    print('Snooze Duration: $snoozeDuration minutes');

    try {
      // Check if Get context is available before showing snackbar
      if (Get.context != null) {
        Get.snackbar(
          '⏰ Snoozing...',
          'Processing your request',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 1),
        );
      }

      // Call Cloud Function
      final result = await functions
          .httpsCallable('handleSnoozeReminder')
          .call({
        'reminderId': reminderId,
        'scheduleId': scheduleId,
        'snoozeDuration': snoozeDuration,
      });

      print('✅ Cloud Function Response: ${result.data}');

      if (result.data['success'] == true) {
        print('✅ Reminder snoozed successfully');

        if (Get.context != null) {
          Get.snackbar(
            '⏰ Reminder Snoozed',
            'Will remind you again in $snoozeDuration minutes',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        throw Exception(result.data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      print('❌ Error snoozing reminder: $e');
      if (Get.context != null) {
        Get.snackbar(
          '❌ Error',
          'Failed to snooze reminder: ${e.toString()}',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// Handle Dismiss action (calls Cloud Function)
  @pragma('vm:entry-point')
  Future<void> _handleDismiss(String reminderId, String scheduleId) async {
    print('✅ Dismissing reminder...');
    print('Reminder ID: $reminderId');
    print('Schedule ID: $scheduleId');

    try {
      // Check if Get context is available before showing snackbar
      if (Get.context != null) {
        Get.snackbar(
          '✅ Dismissing...',
          'Processing your request',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 1),
        );
      }

      // Call Cloud Function
      final result = await functions
          .httpsCallable('handleDismissReminder')
          .call({
        'reminderId': reminderId,
        'scheduleId': scheduleId,
      });

      print('✅ Cloud Function Response: ${result.data}');

      if (result.data['success'] == true) {
        print('✅ Reminder dismissed successfully');

        if (Get.context != null) {
          Get.snackbar(
            '✅ Reminder Dismissed',
            'Reminder marked as completed',
            snackPosition: SnackPosition.TOP,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        throw Exception(result.data['error'] ?? 'Unknown error');
      }
    } catch (e) {
      print('❌ Error dismissing reminder: $e');
      if (Get.context != null) {
        Get.snackbar(
          '❌ Error',
          'Failed to dismiss reminder: ${e.toString()}',
          snackPosition: SnackPosition.TOP,
          duration: const Duration(seconds: 3),
        );
      }
    }
  }

  /// Handle notification click (navigate to details page)
  @pragma('vm:entry-point')
  void _handleNotificationClick(Map<String, dynamic>? data) {
    if (data == null) {
      print('⚠️ Notification data is null');
      return;
    }

    final type = data['type'];
    final reminderId = data['reminderId'];

    print('👆 Notification clicked');
    print('Type: $type');
    print('Reminder ID: $reminderId');

    if (type == 'reminder_notification' && reminderId != null) {
      // 🔧 使用延迟执行，确保 app 完全启动
      Future.delayed(const Duration(milliseconds: 500), () {
        try {
          // 🔧 检查 Get 是否已初始化
          if (!Get.isRegistered<ReminderController>()) {
            Get.put(ReminderController());
          }

          final controller = Get.find<ReminderController>();
          final reminder = controller.getReminderById(reminderId);

          if (Get.context != null) {
            if (reminder != null) {
              Get.snackbar(
                '📋 ${reminder.reminderTitle}',
                'Time to track your health!',
                snackPosition: SnackPosition.TOP,
                duration: const Duration(seconds: 3),
                onTap: (_) {
                  Get.to(() => const ReminderScreen());
                },
              );
            } else {
              // 如果找不到 reminder，直接跳转到列表页
              Get.to(() => const ReminderScreen());
            }
          } else {
            print('⚠️ Context not available yet, retrying...');
            // 再延迟一次
            Future.delayed(const Duration(seconds: 1), () {
              if (Get.context != null) {
                Get.to(() => const ReminderScreen());
              }
            });
          }
        } catch (e) {
          print('❌ Error handling notification click: $e');
        }
      });
    }
  }

  /// Save user ID to local storage
  @pragma('vm:entry-point')
  Future<void> _saveUserId(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastUserIdKey, userId);
    } catch (e) {
      print('Error saving user ID: $e');
    }
  }

  /// Get last known user ID
  @pragma('vm:entry-point')
  Future<String?> _getLastKnownUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_lastUserIdKey);
    } catch (e) {
      print('Error getting last user ID: $e');
      return null;
    }
  }

  /// Clear saved user ID
  @pragma('vm:entry-point')
  Future<void> _clearSavedUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastUserIdKey);
    } catch (e) {
      print('Error clearing user ID: $e');
    }
  }

  /// Clear tokens on logout
  @pragma('vm:entry-point')
  Future<void> _clearTokensOnLogout() async {
    try {
      final lastKnownUserId = await _getLastKnownUserId();

      if (lastKnownUserId != null) {
        await firestore.collection('users').doc(lastKnownUserId).update({
          'fcmTokens': FieldValue.delete(),
          'lastLogout': FieldValue.serverTimestamp(),
        });

        await _clearSavedUserId();
        print('Reminder FCM tokens cleared for user $lastKnownUserId');
      }
    } catch (e) {
      print('Error clearing tokens on logout: $e');
    }
  }

  /// Get current FCM token
  @pragma('vm:entry-point')
  Future<String?> getCurrentToken() async {
    return await messaging.getToken();
  }

  /// Clear all tokens
  @pragma('vm:entry-point')
  Future<void> clearTokens() async {
    try {
      String? userId = _getCurrentUserId();
      if (userId != null) {
        await firestore.collection('users').doc(userId).update({
          'fcmTokens': FieldValue.delete(),
        });
        print('Reminder FCM tokens cleared for user $userId');
      }
    } catch (e) {
      print('Error clearing Reminder FCM tokens: $e');
    }
  }
}