import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../features/reminder/models/reminder_schedule_model.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import 'reminder_repository.dart';

class ReminderScheduleRepository extends GetxController {
  static ReminderScheduleRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// Get ReminderRepository instance
  ReminderRepository get _reminderRepo => ReminderRepository.instance;

  /// Check if user is authenticated
  bool get _isAuthenticated => _auth.currentUser != null;

  /// Get reminders collection reference (顶级 collection)
  CollectionReference<Map<String, dynamic>> get _remindersRef =>
      _db.collection(FirebaseCollectionNames.reminders);

  /// Get schedules subcollection reference
  CollectionReference<Map<String, dynamic>> _schedulesRef(String reminderId) =>
      _remindersRef.doc(reminderId).collection(FirebaseCollectionNames.reminderSchedules);

  /// Fetch all schedules for a reminder
  Future<List<ReminderScheduleModel>> fetchReminderSchedules(String reminderId) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership through ReminderRepository
      await _reminderRepo.fetchReminderById(reminderId);

      final snapshot = await _schedulesRef(reminderId)
          .orderBy(FirebaseFieldNames.triggerTime)
          .get();

      return snapshot.docs
          .map((doc) => ReminderScheduleModel.fromSnapshot(doc))
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

  /// Fetch single schedule by ID
  Future<ReminderScheduleModel?> fetchScheduleById(
      String reminderId,
      String scheduleId,
      ) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership
      await _reminderRepo.fetchReminderById(reminderId);

      final doc = await _schedulesRef(reminderId).doc(scheduleId).get();

      if (doc.exists) {
        return ReminderScheduleModel.fromSnapshot(doc);
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

  /// Fetch pending schedules
  Future<List<ReminderScheduleModel>> fetchPendingSchedules(String reminderId) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership
      await _reminderRepo.fetchReminderById(reminderId);

      final snapshot = await _schedulesRef(reminderId)
          .where(FirebaseFieldNames.status, isEqualTo: ScheduleStatus.pending.name)
          .orderBy(FirebaseFieldNames.triggerTime)
          .get();

      return snapshot.docs
          .map((doc) => ReminderScheduleModel.fromSnapshot(doc))
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

  /// Fetch triggered schedules
  Future<List<ReminderScheduleModel>> fetchTriggeredSchedules(String reminderId) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership
      await _reminderRepo.fetchReminderById(reminderId);

      final snapshot = await _schedulesRef(reminderId)
          .where(FirebaseFieldNames.status, isEqualTo: ScheduleStatus.triggered.name)
          .orderBy(FirebaseFieldNames.triggerTime, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReminderScheduleModel.fromSnapshot(doc))
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

  /// Stream schedules for a reminder
  Stream<List<ReminderScheduleModel>> streamReminderSchedules(String reminderId) {
    if (!_isAuthenticated) {
      return Stream.value([]);
    }

    return _schedulesRef(reminderId)
        .orderBy(FirebaseFieldNames.triggerTime)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ReminderScheduleModel.fromSnapshot(doc))
        .toList());
  }

  /// Stream pending schedules
  Stream<List<ReminderScheduleModel>> streamPendingSchedules(String reminderId) {
    if (!_isAuthenticated) {
      return Stream.value([]);
    }

    return _schedulesRef(reminderId)
        .where(FirebaseFieldNames.status, isEqualTo: ScheduleStatus.pending.name)
        .orderBy(FirebaseFieldNames.triggerTime)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => ReminderScheduleModel.fromSnapshot(doc))
        .toList());
  }

  /// Create new schedule
  Future<String> createSchedule(String reminderId, ReminderScheduleModel schedule) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership
      await _reminderRepo.fetchReminderById(reminderId);

      // Generate ID if not provided
      final scheduleId = schedule.scheduleId.isEmpty
          ? const Uuid().v1()
          : schedule.scheduleId;

      final scheduleWithId = schedule.copyWith(scheduleId: scheduleId);

      await _schedulesRef(reminderId)
          .doc(scheduleId)
          .set(scheduleWithId.toJson());

      return scheduleId;
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

  /// Update schedule
  Future<void> updateSchedule(String reminderId, ReminderScheduleModel schedule) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership
      await _reminderRepo.fetchReminderById(reminderId);

      await _schedulesRef(reminderId)
          .doc(schedule.scheduleId)
          .update(schedule.toJson());
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

  /// Update schedule status
  Future<void> updateScheduleStatus(
      String reminderId,
      String scheduleId,
      ScheduleStatus status,
      ) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership
      await _reminderRepo.fetchReminderById(reminderId);

      await _schedulesRef(reminderId).doc(scheduleId).update({
        FirebaseFieldNames.status: status.name,
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

  /// Snooze a schedule
  Future<void> snoozeSchedule(
      String reminderId,
      String scheduleId,
      DateTime newTriggerTime,
      int newSnoozeCount,
      ) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership
      await _reminderRepo.fetchReminderById(reminderId);

      await _schedulesRef(reminderId).doc(scheduleId).update({
        FirebaseFieldNames.triggerTime: Timestamp.fromDate(newTriggerTime),
        FirebaseFieldNames.snoozeCount: newSnoozeCount,
        FirebaseFieldNames.status: ScheduleStatus.snoozed.name,
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

  /// Dismiss a schedule
  Future<void> dismissSchedule(String reminderId, String scheduleId) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership
      await _reminderRepo.fetchReminderById(reminderId);

      await _schedulesRef(reminderId).doc(scheduleId).update({
        FirebaseFieldNames.status: ScheduleStatus.dismissed.name,
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

  /// Delete schedule
  Future<void> deleteSchedule(String reminderId, String scheduleId) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership
      await _reminderRepo.fetchReminderById(reminderId);

      await _schedulesRef(reminderId).doc(scheduleId).delete();
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

  /// Delete all pending schedules for a reminder
  Future<void> deleteAllPendingSchedules(String reminderId) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership
      await _reminderRepo.fetchReminderById(reminderId);

      final batch = _db.batch();
      final schedules = await _schedulesRef(reminderId)
          .where(FirebaseFieldNames.status, isEqualTo: ScheduleStatus.pending.name)
          .get();

      for (final doc in schedules.docs) {
        batch.delete(doc.reference);
      }

      if (schedules.docs.isNotEmpty) {
        await batch.commit();
      }
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

  /// Delete all schedules for a reminder
  Future<void> deleteAllSchedules(String reminderId) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership
      await _reminderRepo.fetchReminderById(reminderId);

      final batch = _db.batch();
      final schedules = await _schedulesRef(reminderId).get();

      for (final doc in schedules.docs) {
        batch.delete(doc.reference);
      }

      if (schedules.docs.isNotEmpty) {
        await batch.commit();
      }
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

  /// Get schedule count for a reminder
  Future<int> getScheduleCount(String reminderId) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership
      await _reminderRepo.fetchReminderById(reminderId);

      final snapshot = await _schedulesRef(reminderId).get();
      return snapshot.docs.length;
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

  /// Get pending schedule count for a reminder
  Future<int> getPendingScheduleCount(String reminderId) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership
      await _reminderRepo.fetchReminderById(reminderId);

      final snapshot = await _schedulesRef(reminderId)
          .where(FirebaseFieldNames.status, isEqualTo: ScheduleStatus.pending.name)
          .get();

      return snapshot.docs.length;
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

  /// Check if a schedule exists at a specific trigger time
  Future<bool> scheduleExistsAtTime(
      String reminderId,
      DateTime triggerTime,
      ) async {
    try {
      if (!_isAuthenticated) {
        throw 'User not authenticated';
      }

      // Verify ownership
      await _reminderRepo.fetchReminderById(reminderId);

      final snapshot = await _schedulesRef(reminderId)
          .where(FirebaseFieldNames.status, isEqualTo: ScheduleStatus.pending.name)
          .where(FirebaseFieldNames.triggerTime, isEqualTo: Timestamp.fromDate(triggerTime))
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
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
}