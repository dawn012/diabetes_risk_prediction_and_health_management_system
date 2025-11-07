import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../common/loaders/loaders.dart';
import '../../../features/achievement/models/achievement_model.dart';
import '../../../features/achievement/models/user_achievement_model.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class AchievementRepository extends GetxController {
  static AchievementRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _uuid = const Uuid();

  /// Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get achievements collection reference
  CollectionReference<Map<String, dynamic>> get achievementsRef =>
      _db.collection(FirebaseCollectionNames.achievements);

  /// Get user achievements collection reference
  CollectionReference<Map<String, dynamic>> get userAchievementsRef =>
      _db.collection(FirebaseCollectionNames.userAchievements);

  /// Get users collection reference
  CollectionReference<Map<String, dynamic>> get usersRef =>
      _db.collection(FirebaseCollectionNames.users);

  // ==================== Achievement Operations ====================

  /// Get all active achievements as a stream
  Stream<List<AchievementModel>> getAllAchievementsStream() {
    try {
      return achievementsRef
          .where(FirebaseFieldNames.isActive, isEqualTo: true)
          .orderBy(FirebaseFieldNames.createdAt, descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => AchievementModel.fromSnapshot(doc))
          .toList());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Get achievements by type as a stream
  Stream<List<AchievementModel>> getAchievementsByTypeStream(
      AchievementType type) {
    try {
      return achievementsRef
          .where(FirebaseFieldNames.isActive, isEqualTo: true)
          .where(FirebaseFieldNames.achievementType, isEqualTo: type.value)
          .orderBy(FirebaseFieldNames.createdAt, descending: false)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => AchievementModel.fromSnapshot(doc))
          .toList());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Get a single achievement by ID
  Future<AchievementModel?> getAchievementById(String achievementId) async {
    try {
      final doc = await achievementsRef.doc(achievementId).get();
      if (doc.exists) {
        return AchievementModel.fromSnapshot(doc);
      }
      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Create a new achievement (Admin only)
  Future<void> createAchievement(AchievementModel achievement) async {
    try {
      // 生成 UUID
      final achievementId = _uuid.v1();

      final achievementWithId = achievement.copyWith(achievementId: achievementId);

      await achievementsRef
          .doc(achievementId)
          .set(achievementWithId.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Update an achievement (Admin only)
  Future<void> updateAchievement(AchievementModel achievement) async {
    try {
      await achievementsRef
          .doc(achievement.achievementId)
          .update(achievement.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Delete an achievement (Admin only)
  Future<void> deleteAchievement(String achievementId) async {
    try {
      await achievementsRef.doc(achievementId).delete();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  // ==================== User Achievement Operations ====================

  /// Get user achievements as a stream
  Stream<List<UserAchievementModel>> getUserAchievementsStream(String userId) {
    try {
      return userAchievementsRef
          .where(FirebaseFieldNames.userId, isEqualTo: userId)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => UserAchievementModel.fromSnapshot(doc))
          .toList());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Get user achievements with complete achievement details
  Stream<List<UserAchievementModel>> getUserAchievementsWithDetailsStream(String userId) {
    try {
      return userAchievementsRef
          .where(FirebaseFieldNames.userId, isEqualTo: userId)
          .snapshots()
          .asyncMap((snapshot) async {
        final userAchievements = snapshot.docs
            .map((doc) => UserAchievementModel.fromSnapshot(doc))
            .toList();

        // 直接从文档数据中获取 achievementId，而不是从 model
        final achievementIds = snapshot.docs
            .map((doc) {
          final data = doc.data();
          return data[FirebaseFieldNames.achievementId] as String?;
        })
            .where((id) => id != null && id.isNotEmpty)
            .toSet()
            .toList()
            .cast<String>();

        // Fetch achievement details
        final achievements = await _getAchievementsByIds(achievementIds);

        // Combine data
        return userAchievements.asMap().entries.map((entry) {
          final index = entry.key;
          final userAchievement = entry.value;

          // 从原始文档数据中获取 achievementId
          final doc = snapshot.docs[index];
          final achievementId = doc.data()[FirebaseFieldNames.achievementId] as String?;

          final achievement = achievements[achievementId] ?? AchievementModel.empty();
          return userAchievement.copyWith(achievement: achievement);
        }).toList();
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      print('Error in getUserAchievementsWithDetailsStream: $e'); // Debug
      throw 'Something went wrong. Please try again';
    }
  }

  /// Get a single user achievement
  Future<UserAchievementModel?> getUserAchievement(
      String userId, String achievementId) async {
    try {
      final snapshot = await userAchievementsRef
          .where(FirebaseFieldNames.userId, isEqualTo: userId)
          .where(FirebaseFieldNames.achievementId, isEqualTo: achievementId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        return UserAchievementModel.fromSnapshot(snapshot.docs.first);
      }
      return null;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Create a new user achievement
  Future<void> createUserAchievement(
      String userId, UserAchievementModel userAchievement) async {
    try {
      final docRef = userAchievementsRef.doc();
      final data = userAchievement.toJson();
      data[FirebaseFieldNames.userId] = userId;
      data[FirebaseFieldNames.userAchievementId] = docRef.id;

      await docRef.set(data);
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Update user achievement progress
  Future<void> updateUserAchievement(
      String userId, UserAchievementModel userAchievement) async {
    try {
      final snapshot = await userAchievementsRef
          .where(FirebaseFieldNames.userId, isEqualTo: userId)
          .where(FirebaseFieldNames.achievementId,
          isEqualTo: userAchievement.achievement.achievementId)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        await snapshot.docs.first.reference.update(userAchievement.toJson());
      }
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Increment achievement count and update level if needed
  Future<void> incrementAchievementCount({
    required String userId,
    required String achievementId,
    required AchievementModel achievement,
    int incrementBy = 1,
  }) async {
    try {
      // Get existing user achievement or create new one
      var userAchievement = await getUserAchievement(userId, achievementId);

      if (userAchievement == null) {
        // Create new user achievement with proper initialization
        final newUserAchievement = UserAchievementModel(
          userAchievementId: '', // Will be set by Firestore
          userId: userId,
          achievement: achievement,
          currentLevel: UserAchievementLevel.none,
          currentCount: incrementBy, // Start with the increment value
          status: AchievementStatus.inProgress,
          startedAt: DateTime.now(),
          completedAt: null,
        );
        await createUserAchievement(userId, newUserAchievement);
      } else {
        // Update existing achievement
        int newCount = userAchievement.currentCount + incrementBy;
        UserAchievementLevel newLevel = userAchievement.currentLevel;
        AchievementStatus newStatus = userAchievement.status;
        DateTime? completedAt = userAchievement.completedAt;

        // Check if user should level up
        for (var level in achievement.levels) {
          if (newCount >= level.criteria) {
            newLevel = UserAchievementLevel.fromString(level.level.value);

            // Check if this is the highest level (Gold)
            if (level.level == AchievementLevel.gold) {
              newStatus = AchievementStatus.completed;
              completedAt = DateTime.now();

              // Award points (only for non-permanent achievements)
              if (achievement.achievementType == AchievementType.periodic) {
                await _updateUserTotalScore(userId, level.points);
              }
            }
          }
        }

        final updatedAchievement = userAchievement.copyWith(
          currentCount: newCount,
          currentLevel: newLevel,
          status: newStatus,
          completedAt: completedAt,
        );

        await updateUserAchievement(userId, updatedAchievement);
      }
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Reset periodic achievements (called monthly)
  Future<void> resetPeriodicAchievements(String userId) async {
    try {
      final snapshot = await userAchievementsRef
          .where(FirebaseFieldNames.userId, isEqualTo: userId)
          .get();

      final batch = _db.batch();

      for (var doc in snapshot.docs) {
        final userAchievement = UserAchievementModel.fromSnapshot(doc);

        // Get the achievement to check if it's periodic
        final achievement =
        await getAchievementById(userAchievement.achievement.achievementId);

        if (achievement != null &&
            achievement.achievementType == AchievementType.periodic) {
          // Reset the user achievement
          final resetAchievement = userAchievement.copyWith(
            currentLevel: UserAchievementLevel.bronze,
            currentCount: 0,
            status: AchievementStatus.inProgress,
            startedAt: DateTime.now(),
            completedAt: null,
          );

          batch.update(doc.reference, resetAchievement.toJson());
        }
      }

      await batch.commit();
      TLoaders.successSnackBar(
          title: 'Success', message: 'Periodic achievements reset');
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Update user's total score
  Future<void> _updateUserTotalScore(String userId, int points) async {
    try {
      await usersRef.doc(userId).update({
        FirebaseFieldNames.totalScore: FieldValue.increment(points),
      });
    } catch (e) {
      // Silent fail for score update to not interrupt achievement flow
      print('Error updating user score: $e');
    }
  }

  /// Get user's total score
  Future<int> getUserTotalScore(String userId) async {
    try {
      final doc = await usersRef.doc(userId).get();
      if (doc.exists) {
        return doc.data()?[FirebaseFieldNames.totalScore] ?? 0;
      }
      return 0;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on TPlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw 'Something went wrong. Please try again';
    }
  }

  /// Batch fetch achievements by IDs
  Future<Map<String, AchievementModel>> _getAchievementsByIds(List<String> ids) async {
    if (ids.isEmpty) return {};

    final queries = ids.map((id) => achievementsRef.doc(id).get());
    final snapshots = await Future.wait(queries);
    final achievements = <String, AchievementModel>{};

    for (final snapshot in snapshots) {
      if (snapshot.exists) {
        final achievement = AchievementModel.fromSnapshot(snapshot);
        achievements[achievement.achievementId] = achievement;
      }
    }

    return achievements;
  }
}