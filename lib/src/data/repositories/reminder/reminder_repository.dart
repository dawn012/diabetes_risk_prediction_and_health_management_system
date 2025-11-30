import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../features/reminder/models/reminder_model.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class ReminderRepository extends GetxController {
  static ReminderRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get reminders collection reference
  CollectionReference<Map<String, dynamic>> get remindersRef =>
      _db.collection(FirebaseCollectionNames.reminders);

  Map<String, dynamic> _reminderToJson(ReminderModel reminder) {
    final json = <String, dynamic>{
      FirebaseFieldNames.reminderId: reminder.reminderId,
      FirebaseFieldNames.userId: currentUserId,
      FirebaseFieldNames.reminderTitle: reminder.reminderTitle,
      FirebaseFieldNames.baseTime: Timestamp.fromDate(reminder.baseTime),
      FirebaseFieldNames.repeatType: reminder.repeatType.value,
      FirebaseFieldNames.customDays: reminder.customDays,
      FirebaseFieldNames.intervalTime: reminder.intervalTime,
      FirebaseFieldNames.nextTriggerTime: Timestamp.fromDate(reminder.nextTriggerTime),
      FirebaseFieldNames.snoozeDuration: reminder.snoozeDuration,
      FirebaseFieldNames.isActive: reminder.isActive,
    };

    // 2. 处理 endDate
    if (reminder.repeatType == RepeatType.once) {
      // Once 类型使用 2099 作为占位符，表示"无限期"
      json[FirebaseFieldNames.endDate] = Timestamp.fromDate(DateTime(2099, 12, 31));
    } else if (reminder.endDate != null) {
      // 重复类型才使用实际的 endDate
      final endDateWithTime = DateTime(
        reminder.endDate!.year,
        reminder.endDate!.month,
        reminder.endDate!.day,
        23,
        59,
        59,
      );
      json[FirebaseFieldNames.endDate] = Timestamp.fromDate(endDateWithTime);
    } else {
      // 如果没有设置 endDate，也使用 2099
      json[FirebaseFieldNames.endDate] = Timestamp.fromDate(DateTime(2099, 12, 31));
    }

    return json;
  }

  /// Stream: Get all reminders in real-time
  Stream<List<ReminderModel>> getAllRemindersStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return remindersRef
        .where(FirebaseFieldNames.userId, isEqualTo: currentUserId)
        .orderBy(FirebaseFieldNames.baseTime)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => ReminderModel.fromSnapshot(doc))
          .toList();
    });
  }

  /// Fetch all reminders for current user
  Future<List<ReminderModel>> fetchAllReminders() async {
    try {
      if (!isAuthenticated) {
        throw 'User not authenticated';
      }

      final snapshot = await remindersRef
          .where(FirebaseFieldNames.userId, isEqualTo: currentUserId)
          .orderBy(FirebaseFieldNames.baseTime)
          .get();

      return snapshot.docs
          .map((doc) => ReminderModel.fromSnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Fetch single reminder by ID
  Future<ReminderModel?> fetchReminderById(String reminderId) async {
    try {
      if (!isAuthenticated) {
        throw 'User not authenticated';
      }

      final document = await remindersRef.doc(reminderId).get();

      if (document.exists) {
        final data = document.data()!;
        // Verify reminder belongs to current user
        if (data[FirebaseFieldNames.userId] == currentUserId) {
          return ReminderModel.fromSnapshot(document);
        }
        throw 'Access denied: Reminder does not belong to current user';
      }
      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Create a new reminder
  Future<ReminderModel> createReminder({
    required String reminderTitle,
    required DateTime baseTime,
    required RepeatType repeatType,
    required List<String> customDays,
    int? intervalTime,
    DateTime? endDate,
    required int snoozeDuration,
    bool isActive = true,
  }) async {
    try {
      if (!isAuthenticated) {
        throw 'User not authenticated';
      }

      final reminderId = const Uuid().v1();

      // Calculate next trigger time
      final nextTriggerTime = _calculateNextTriggerTime(
        baseTime: baseTime,
        repeatType: repeatType,
        customDays: customDays,
        intervalTime: intervalTime,
      );

      final reminder = ReminderModel(
        reminderId: reminderId,
        reminderTitle: reminderTitle,
        baseTime: baseTime,
        repeatType: repeatType,
        customDays: customDays,
        intervalTime: intervalTime,
        endDate: endDate, // Can be null
        nextTriggerTime: nextTriggerTime,
        snoozeDuration: snoozeDuration,
        reminderSchedules: [],
        isActive: isActive,
      );

      await remindersRef.doc(reminderId).set(_reminderToJson(reminder));

      return reminder;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Add new reminder (using ReminderModel)
  Future<ReminderModel> addReminder(ReminderModel reminder) async {
    try {
      if (!isAuthenticated) {
        throw 'User not authenticated';
      }

      // Generate new ID if not provided
      final reminderId = reminder.reminderId.isEmpty
          ? const Uuid().v1()
          : reminder.reminderId;

      final reminderWithId = reminder.copyWith(reminderId: reminderId);

      await remindersRef.doc(reminderId).set(_reminderToJson(reminderWithId));

      return reminderWithId;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Update existing reminder
  Future<void> updateReminder(ReminderModel reminder) async {
    try {
      if (!isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify the reminder belongs to current user
      final existingReminder = await fetchReminderById(reminder.reminderId);
      if (existingReminder == null) {
        throw 'Reminder not found or access denied';
      }

      await remindersRef.doc(reminder.reminderId).update(_reminderToJson(reminder));
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Delete reminder
  Future<void> deleteReminder(String reminderId) async {
    try {
      if (!isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify the reminder belongs to current user
      final existingReminder = await fetchReminderById(reminderId);
      if (existingReminder == null) {
        throw 'Reminder not found or access denied';
      }

      await remindersRef.doc(reminderId).delete();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Stream for real-time updates
  Stream<List<ReminderModel>> getRemindersStream() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return remindersRef
        .where(FirebaseFieldNames.userId, isEqualTo: currentUserId)
        .orderBy(FirebaseFieldNames.nextTriggerTime)
        .snapshots()
        .map((querySnapshot) {
      return querySnapshot.docs
          .map((doc) => ReminderModel.fromSnapshot(doc))
          .toList();
    });
  }

  /// Update reminder status (active/inactive)
  Future<void> updateReminderStatus(String reminderId, bool isActive) async {
    try {
      if (!isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify the reminder belongs to current user
      final existingReminder = await fetchReminderById(reminderId);
      if (existingReminder == null) {
        throw 'Reminder not found or access denied';
      }

      // 如果是 re-enable，重新计算 nextTriggerTime
      Map<String, dynamic> updateData = {
        FirebaseFieldNames.isActive: isActive,
      };

      if (isActive) {
        // Re-enabling: 重新计算下次触发时间
        final nextTriggerTime = _calculateNextTriggerTime(
          baseTime: existingReminder.baseTime,
          repeatType: existingReminder.repeatType,
          customDays: existingReminder.customDays,
          intervalTime: existingReminder.intervalTime,
        );

        updateData[FirebaseFieldNames.nextTriggerTime] = Timestamp.fromDate(nextTriggerTime);
      }

      await remindersRef.doc(reminderId).update(updateData);
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Update next trigger time
  Future<void> updateNextTriggerTime(String reminderId, DateTime nextTriggerTime) async {
    try {
      if (!isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify the reminder belongs to current user
      final existingReminder = await fetchReminderById(reminderId);
      if (existingReminder == null) {
        throw 'Reminder not found or access denied';
      }

      await remindersRef.doc(reminderId).update({
        FirebaseFieldNames.nextTriggerTime: Timestamp.fromDate(nextTriggerTime),
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Get active reminders only
  Future<List<ReminderModel>> getActiveReminders() async {
    try {
      if (!isAuthenticated) {
        throw 'User not authenticated';
      }

      final snapshot = await remindersRef
          .where(FirebaseFieldNames.userId, isEqualTo: currentUserId)
          .where(FirebaseFieldNames.isActive, isEqualTo: true)
          .orderBy(FirebaseFieldNames.nextTriggerTime)
          .get();

      return snapshot.docs
          .map((doc) => ReminderModel.fromSnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Get upcoming reminders (next 24 hours)
  Future<List<ReminderModel>> getUpcomingReminders() async {
    try {
      if (!isAuthenticated) {
        throw 'User not authenticated';
      }

      final now = DateTime.now();
      final tomorrow = now.add(const Duration(days: 1));

      final snapshot = await remindersRef
          .where(FirebaseFieldNames.userId, isEqualTo: currentUserId)
          .where(FirebaseFieldNames.isActive, isEqualTo: true)
          .where(FirebaseFieldNames.nextTriggerTime, isGreaterThanOrEqualTo: Timestamp.fromDate(now))
          .where(FirebaseFieldNames.nextTriggerTime, isLessThan: Timestamp.fromDate(tomorrow))
          .orderBy(FirebaseFieldNames.nextTriggerTime)
          .get();

      return snapshot.docs
          .map((doc) => ReminderModel.fromSnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Calculate next trigger time based on repeat configuration
  DateTime _calculateNextTriggerTime({
    required DateTime baseTime,
    required RepeatType repeatType,
    required List<String> customDays,
    int? intervalTime,
  }) {
    final now = DateTime.now();

    switch (repeatType) {
      case RepeatType.once:
      // 如果 baseTime 已过，设置为明天的同一时间
        final todayTrigger = DateTime(
          now.year,
          now.month,
          now.day,
          baseTime.hour,
          baseTime.minute,
          0,
          0,
        );

        if (todayTrigger.isAfter(now)) {
          // 今天的时间还没到，就用今天
          return todayTrigger;
        } else {
          // 今天的时间已过，设置为明天
          return todayTrigger.add(const Duration(days: 1));
        }

      case RepeatType.customDays:
        return _calculateNextCustomDayTime(baseTime, customDays);

      case RepeatType.fixedInterval:
        return _calculateNextIntervalTime(baseTime, intervalTime ?? 1);
    }
  }

  /// Calculate next trigger time for custom days
  DateTime _calculateNextCustomDayTime(DateTime baseTime, List<String> customDays) {
    if (customDays.isEmpty) {
      return DateTime.now().add(const Duration(minutes: 1));
    }

    final now = DateTime.now();
    final baseTimeOfDay = TimeOfDay.fromDateTime(baseTime);

    // Start from today
    DateTime candidate = DateTime(now.year, now.month, now.day);
    candidate = candidate.add(Duration(
      hours: baseTimeOfDay.hour,
      minutes: baseTimeOfDay.minute,
    ));

    // Check next 7 days
    for (int i = 0; i < 7; i++) {
      final checkDate = candidate.add(Duration(days: i));
      final dayName = _getDayNameFromDateTime(checkDate);

      if (customDays.contains(dayName) && checkDate.isAfter(now)) {
        return checkDate;
      }
    }

    // Fallback: add 1 day to base time
    return baseTime.add(const Duration(days: 1));
  }

  /// Calculate next trigger time for fixed interval
  DateTime _calculateNextIntervalTime(DateTime baseTime, int intervalMinutes) {
    final now = DateTime.now();

    if (baseTime.isAfter(now)) {
      return baseTime;
    }

    // Calculate how many intervals have passed
    final difference = now.difference(baseTime).inMinutes;
    final intervalsPassedCount = (difference / intervalMinutes).ceil();

    return baseTime.add(Duration(minutes: intervalMinutes * intervalsPassedCount));
  }

  /// Convert DateTime to day name string
  String _getDayNameFromDateTime(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday: return 'Mon';
      case DateTime.tuesday: return 'Tue';
      case DateTime.wednesday: return 'Wed';
      case DateTime.thursday: return 'Thu';
      case DateTime.friday: return 'Fri';
      case DateTime.saturday: return 'Sat';
      case DateTime.sunday: return 'Sun';
      default: return 'Mon';
    }
  }
}