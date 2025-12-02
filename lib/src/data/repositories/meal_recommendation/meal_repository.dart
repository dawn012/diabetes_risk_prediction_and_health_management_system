import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

import '../../../features/meal_recommendation/models/meal_model.dart';
import '../../../features/meal_recommendation/models/meal_plan_meal_model.dart';
import '../../../features/meal_recommendation/models/meal_plan_model.dart';
import '../../../features/meal_recommendation/models/meal_preference_model.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class MealRepository extends GetxController {
  static MealRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Hive boxes
  static const String _mealPreferenceBox = 'meal_preferences';
  static const String _tempMealPlanBox = 'temp_meal_plans';

  /// Get current user ID
  String? get userId => _auth.currentUser?.uid;

  /// Initialize Hive boxes
  Future<void> initializeHive() async {
    if (!Hive.isBoxOpen(_mealPreferenceBox)) {
      await Hive.openBox<MealPreferenceModel>(_mealPreferenceBox);
    }
    if (!Hive.isBoxOpen(_tempMealPlanBox)) {
      await Hive.openBox<MealPlanModel>(_tempMealPlanBox);
    }
  }

  // ==================== Meal Preference Methods ====================

  /// Save meal preference to Firestore
  Future<void> saveMealPreference(MealPreferenceModel preference) async {
    try {
      if (userId == null) throw 'User not authenticated';

      await _db
          .collection(FirebaseCollectionNames.users)
          .doc(userId)
          .update({
        FirebaseFieldNames.mealPreferences: preference.toJson(),
      });

      print('✅ Meal preference saved to Firestore');
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error saving meal preference: ${e.toString()}';
    }
  }

  /// Get meal preference from Firestore
  Future<MealPreferenceModel?> getMealPreference() async {
    try {
      if (userId == null) return null;

      final doc = await _db
          .collection(FirebaseCollectionNames.users)
          .doc(userId)
          .get();

      final data = doc.data();
      if (data == null || !data.containsKey(FirebaseFieldNames.mealPreferences)) {
        return null;
      }

      return MealPreferenceModel.fromMap(
        data[FirebaseFieldNames.mealPreferences] as Map<String, dynamic>,
      );
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error fetching meal preference: ${e.toString()}';
    }
  }

  /// Save meal preference to Hive (local cache)
  Future<void> saveMealPreferenceLocally(MealPreferenceModel preference) async {
    try {
      final box = await Hive.openBox<MealPreferenceModel>(_mealPreferenceBox);
      await box.put('user_preference', preference);
      print('✅ Meal preference saved locally');
    } catch (e) {
      print('❌ Error saving meal preference locally: $e');
    }
  }

  /// Get meal preference from Hive
  MealPreferenceModel? getMealPreferenceLocally() {
    try {
      final box = Hive.box<MealPreferenceModel>(_mealPreferenceBox);
      return box.get('user_preference');
    } catch (e) {
      print('❌ Error getting meal preference locally: $e');
      return null;
    }
  }

  // ==================== Meal Plan Methods ====================

  /// Get user's meal plans collection reference
  CollectionReference<Map<String, dynamic>> _getMealPlansCollection() {
    return _db
        .collection(FirebaseCollectionNames.mealPlans)
        .doc(userId)
        .collection('plans');
  }

  /// Get user's meal plan meals collection reference
  CollectionReference<Map<String, dynamic>> _getMealPlanMealsCollection(
      String mealPlanId,
      ) {
    return _db
        .collection(FirebaseCollectionNames.mealPlans)
        .doc(userId)
        .collection('plans')
        .doc(mealPlanId)
        .collection('scheduledMeals');
  }

  /// Save meal plan to Firestore
  Future<void> saveMealPlan(MealPlanModel mealPlan) async {
    try {
      if (userId == null) throw 'User not authenticated';

      final planRef = _getMealPlansCollection().doc(mealPlan.mealPlanId);

      // 1. 用 mealPlan.toJson() 生成 plan 的基础字段
      final planData = mealPlan.toJson();

      // 2. 手动把 scheduledMeals 转成数组，里面只放 id 等轻量字段
      planData[FirebaseFieldNames.scheduledMeals] =
          mealPlan.scheduledMeals.map((m) {
            return {
              FirebaseFieldNames.mealPlanMealId: m.mealPlanMealId,
              FirebaseFieldNames.mealId: m.meal.mealId,           // 从对象里拿 id
              FirebaseFieldNames.scheduledDate:
              m.scheduledDate.millisecondsSinceEpoch,
              FirebaseFieldNames.mealTimeSlot: m.mealTimeSlot.value,
              FirebaseFieldNames.status: m.status.value,
            };
          }).toList();

      await planRef.set(planData);
      print('✅ Meal plan saved to Firestore');

      await clearTempMealPlan();
    } catch (e) {
      throw 'Error saving meal plan: ${e.toString()}';
    }
  }

  /// Get active meal plan
  Future<MealPlanModel?> getActiveMealPlan() async {
    try {
      if (userId == null) return null;

      final querySnapshot = await _getMealPlansCollection()
          .where(FirebaseFieldNames.status, isEqualTo: MealPlanStatus.confirmed.value)
          .orderBy(FirebaseFieldNames.startDateTime, descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      return await _buildMealPlanFromDoc(querySnapshot.docs.first);
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error fetching active meal plan: ${e.toString()}';
    }
  }

  /// Stream active meal plan
  Stream<MealPlanModel?> streamActiveMealPlan() {
    try {
      if (userId == null) return Stream.value(null);

      return _getMealPlansCollection()
          .where(FirebaseFieldNames.status, isEqualTo: MealPlanStatus.confirmed.value)
          .orderBy(FirebaseFieldNames.startDateTime, descending: true)
          .limit(1)
          .snapshots()
          .asyncMap((snapshot) async {
        if (snapshot.docs.isEmpty) return null;
        return await _buildMealPlanFromDoc(snapshot.docs.first);
      });
    } catch (e) {
      print('Error streaming active meal plan: $e');
      return Stream.value(null);
    }
  }

  /// Get past meal plans
  Future<List<MealPlanModel>> getPastMealPlans() async {
    try {
      if (userId == null) return [];

      final querySnapshot = await _getMealPlansCollection()
          .where(FirebaseFieldNames.status, whereIn: [
        MealPlanStatus.completed.value,
        MealPlanStatus.cancelled.value,
        MealPlanStatus.expired.value,
      ])
          .orderBy(FirebaseFieldNames.startDateTime, descending: true)
          .get();

      List<MealPlanModel> plans = [];
      for (var doc in querySnapshot.docs) {
        final plan = await _buildMealPlanFromDoc(doc);
        if (plan != null) plans.add(plan);
      }

      return plans;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error fetching past meal plans: ${e.toString()}';
    }
  }

  /// Get meal plan by ID
  Future<MealPlanModel?> getMealPlanById(String mealPlanId) async {
    try {
      if (userId == null) return null;

      final doc = await _getMealPlansCollection().doc(mealPlanId).get();
      if (!doc.exists) return null;

      return await _buildMealPlanFromDoc(doc);
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error fetching meal plan: ${e.toString()}';
    }
  }

  /// Build MealPlanModel from Firestore document
  Future<MealPlanModel?> _buildMealPlanFromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc,
      ) async {
    try {
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null) return null;

      // 1. 先构建不带 meals 的 plan
      var mealPlan = MealPlanModel.fromSnapshot(doc);

      // 2. 从文档里取出 scheduledMeals 数组
      final rawMeals =
          (data[FirebaseFieldNames.scheduledMeals] as List<dynamic>?) ?? [];

      final List<MealPlanMealModel> scheduledMeals = [];

      for (final raw in rawMeals) {
        final m = raw as Map<String, dynamic>;

        final String mealPlanMealId =
            m[FirebaseFieldNames.mealPlanMealId] as String? ?? '';
        final String mealId =
            m[FirebaseFieldNames.mealId] as String? ?? '';

        final int scheduledMs =
            m[FirebaseFieldNames.scheduledDate] as int? ??
                DateTime.now().millisecondsSinceEpoch;
        final scheduledDate =
        DateTime.fromMillisecondsSinceEpoch(scheduledMs);

        final mealTimeSlotStr =
            m[FirebaseFieldNames.mealTimeSlot] as String? ?? 'breakfast';
        final statusStr =
            m[FirebaseFieldNames.status] as String? ?? 'pending';

        // 2.1 用 mealId 去 meals collection 拿 MealModel
        MealModel? mealData;
        if (mealId.isNotEmpty) {
          try {
            mealData = await getMealById(mealId);
          } catch (e) {
            print('⚠️ Error fetching meal $mealId: $e');
          }
        }

        // 2.2 构造你的 MealPlanMealModel（仍然用面向对象的 meal 字段）
        scheduledMeals.add(
          MealPlanMealModel(
            mealPlanMealId: mealPlanMealId,
            meal: mealData ?? MealModel.empty(),
            scheduledDate: scheduledDate,
            mealTimeSlot: MealTimeSlot.fromString(mealTimeSlotStr),
            status: MealConsumptionStatus.fromString(statusStr),
          ),
        );
      }

      // 3. 把构建好的 meals 塞回 plan
      mealPlan = mealPlan.copyWith(scheduledMeals: scheduledMeals);

      return mealPlan;
    } catch (e) {
      print('Error building meal plan from doc: $e');
      return null;
    }
  }

  /// Update meal consumption status
  Future<void> updateMealConsumptionStatus(
      String mealPlanId,
      String mealPlanMealId,
      MealConsumptionStatus status,
      ) async {
    try {
      if (userId == null) throw 'User not authenticated';

      final planRef = _getMealPlansCollection().doc(mealPlanId);
      final doc = await planRef.get();
      if (!doc.exists) throw 'Meal plan not found';

      final data = doc.data()!;
      final rawMeals =
          (data[FirebaseFieldNames.scheduledMeals] as List<dynamic>?) ?? [];

      // 更新数组中对应那一项的 status
      final updatedMeals = rawMeals.map((raw) {
        final m = Map<String, dynamic>.from(raw as Map);
        if (m[FirebaseFieldNames.mealPlanMealId] == mealPlanMealId) {
          m[FirebaseFieldNames.status] = status.value;
        }
        return m;
      }).toList();

      await planRef.update({
        FirebaseFieldNames.scheduledMeals: updatedMeals,
      });

      await _updateMealPlanAdherence(mealPlanId);

      print('✅ Meal consumption status updated');
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error updating meal status: ${e.toString()}';
    }
  }

  /// Calculate and update meal plan adherence
  Future<void> _updateMealPlanAdherence(String mealPlanId) async {
    try {
      final planRef = _getMealPlansCollection().doc(mealPlanId);
      final doc = await planRef.get();
      if (!doc.exists) return;

      final data = doc.data()!;
      final rawMeals =
          (data[FirebaseFieldNames.scheduledMeals] as List<dynamic>?) ?? [];

      final totalMeals = rawMeals.length;
      final consumedMeals = rawMeals.where((raw) {
        final m = raw as Map<String, dynamic>;
        return m[FirebaseFieldNames.status] ==
            MealConsumptionStatus.consumed.value;
      }).length;

      final adherence =
      totalMeals > 0 ? ((consumedMeals / totalMeals) * 100).round() : 0;

      await planRef.update({
        FirebaseFieldNames.adherence: adherence,
      });

      print('✅ Adherence updated: $adherence%');
    } catch (e) {
      print('❌ Error updating adherence: $e');
    }
  }

  /// Cancel meal plan
  Future<void> cancelMealPlan(String mealPlanId) async {
    try {
      if (userId == null) throw 'User not authenticated';

      await _getMealPlansCollection().doc(mealPlanId).update({
        FirebaseFieldNames.status: MealPlanStatus.cancelled.value,
      });

      print('✅ Meal plan cancelled');
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error cancelling meal plan: ${e.toString()}';
    }
  }

  // ==================== Temporary Meal Plan (Hive) Methods ====================

  /// Save temporary meal plan to Hive (before confirmation)
  Future<void> saveTempMealPlan(MealPlanModel mealPlan) async {
    try {
      final box = await Hive.openBox<MealPlanModel>(_tempMealPlanBox);
      await box.put('temp_plan', mealPlan);
      print('✅ Temporary meal plan saved locally');
    } catch (e) {
      print('❌ Error saving temp meal plan: $e');
    }
  }

  /// Get temporary meal plan from Hive
  Future<MealPlanModel?> getTempMealPlan() async {
    try {
      final box = await Hive.openBox<MealPlanModel>(_tempMealPlanBox);
      final mealPlan = box.get('temp_plan');

      if (mealPlan == null) return null;

      // Fetch actual meal data for each scheduled meal
      List<MealPlanMealModel> updatedMeals = [];
      for (var meal in mealPlan.scheduledMeals) {
        final mealData = await getMealById(meal.meal.mealId);
        if (mealData != null) {
          updatedMeals.add(meal.copyWith(meal: mealData));
        }
      }

      return mealPlan.copyWith(scheduledMeals: updatedMeals);
    } catch (e) {
      print('❌ Error getting temp meal plan: $e');
      return null;
    }
  }

  /// Clear temporary meal plan from Hive
  Future<void> clearTempMealPlan() async {
    try {
      final box = await Hive.openBox<MealPlanModel>(_tempMealPlanBox);
      await box.delete('temp_plan');
      print('✅ Temporary meal plan cleared');
    } catch (e) {
      print('❌ Error clearing temp meal plan: $e');
    }
  }

  /// Check if temporary meal plan exists
  Future<bool> hasTempMealPlan() async {
    try {
      final box = await Hive.openBox<MealPlanModel>(_tempMealPlanBox);
      return box.containsKey('temp_plan');
    } catch (e) {
      return false;
    }
  }

  // ==================== Meal Methods ====================

  /// Get meal by ID
  Future<MealModel?> getMealById(String mealId) async {
    try {
      final doc = await _db
          .collection(FirebaseCollectionNames.meals)
          .doc(mealId)
          .get();

      if (!doc.exists) return null;

      return MealModel.fromSnapshot(doc);
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error fetching meal: ${e.toString()}';
    }
  }

  /// Get multiple meals by IDs
  Future<List<MealModel>> getMealsByIds(List<String> mealIds) async {
    try {
      if (mealIds.isEmpty) return [];

      // Firestore 'in' query limit is 10, so batch if needed
      List<MealModel> meals = [];

      for (int i = 0; i < mealIds.length; i += 10) {
        final batch = mealIds.skip(i).take(10).toList();
        final querySnapshot = await _db
            .collection(FirebaseCollectionNames.meals)
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        meals.addAll(
          querySnapshot.docs.map((doc) => MealModel.fromSnapshot(doc)).toList(),
        );
      }

      return meals;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Error fetching meals: ${e.toString()}';
    }
  }

  // ==================== Cleanup Methods ====================

  /// Clear all local data
  Future<void> clearAllLocalData() async {
    try {
      final prefBox = await Hive.openBox<MealPreferenceModel>(_mealPreferenceBox);
      final planBox = await Hive.openBox<MealPlanModel>(_tempMealPlanBox);

      await prefBox.clear();
      await planBox.clear();

      print('✅ All local meal data cleared');
    } catch (e) {
      print('❌ Error clearing local data: $e');
    }
  }
}