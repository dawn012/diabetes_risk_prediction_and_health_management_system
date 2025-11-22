import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../../features/reward/models/reward_model.dart';
import '../../../features/reward/models/user_reward_model.dart';
import '../../../utils/constants/enums.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class RewardRepository extends GetxController {
  static RewardRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// ========== Reward CRUD ==========

  /// Fetch all active rewards
  Future<List<RewardModel>> fetchActiveRewards() async {
    try {
      final querySnapshot = await _db
          .collection(FirebaseCollectionNames.rewards)
          .where(FirebaseFieldNames.isActive, isEqualTo: true)
          .orderBy(FirebaseFieldNames.costPoints, descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => RewardModel.fromSnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Fetch active rewards by type
  Future<List<RewardModel>> fetchActiveRewardsByType(RewardType type) async {
    try {
      final querySnapshot = await _db
          .collection(FirebaseCollectionNames.rewards)
          .where(FirebaseFieldNames.isActive, isEqualTo: true)
          .where(FirebaseFieldNames.rewardType, isEqualTo: type.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim().toLowerCase())
          .orderBy(FirebaseFieldNames.costPoints, descending: false)
          .get();

      return querySnapshot.docs
          .map((doc) => RewardModel.fromSnapshot(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Fetch single reward by ID
  Future<RewardModel> fetchRewardById(String rewardId) async {
    try {
      final doc = await _db
          .collection(FirebaseCollectionNames.rewards)
          .doc(rewardId)
          .get();

      if (!doc.exists) {
        throw 'Reward not found';
      }

      return RewardModel.fromSnapshot(doc);
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// ========== User Reward Operations ==========

  /// Redeem a reward (with validation)
  Future<void> redeemReward({
    required String userId,
    required String rewardId,
    String? notes,
  }) async {
    try {
      // Start a transaction to ensure atomicity
      await _db.runTransaction((transaction) async {
        // 1. Get reward details
        final rewardDoc = await transaction.get(
          _db.collection(FirebaseCollectionNames.rewards).doc(rewardId),
        );

        if (!rewardDoc.exists) {
          throw 'Reward not found';
        }

        final reward = RewardModel.fromSnapshot(rewardDoc);

        // 2. Validate reward is active
        if (!reward.isActive) {
          throw 'This reward is no longer available';
        }

        // 3. Check availability
        if (reward.availableQuantity != null && reward.availableQuantity! <= 0) {
          throw 'This reward is out of stock';
        }

        // 4. Get user's current reward points
        final userDoc = await transaction.get(
          _db.collection(FirebaseCollectionNames.users).doc(userId),
        );

        if (!userDoc.exists) {
          throw 'User not found';
        }

        final userData = userDoc.data()!;
        final currentPoints = userData[FirebaseFieldNames.rewardPoints] ?? 0;

        // 5. Validate user has enough points
        if (currentPoints < reward.costPoints) {
          throw 'Insufficient reward points. You need ${reward.costPoints} points but only have $currentPoints points.';
        }

        // 6. Deduct points from user
        transaction.update(
          _db.collection(FirebaseCollectionNames.users).doc(userId),
          {
            FirebaseFieldNames.rewardPoints: FieldValue.increment(-reward.costPoints),
          },
        );

        // 7. Decrease available quantity (if applicable)
        if (reward.availableQuantity != null) {
          transaction.update(
            _db.collection(FirebaseCollectionNames.rewards).doc(rewardId),
            {
              FirebaseFieldNames.availableQuantity: FieldValue.increment(-1),
            },
          );
        }

        // 8. Create user reward record
        final userRewardRef = _db.collection(FirebaseCollectionNames.userRewards).doc();
        transaction.set(userRewardRef, {
          FirebaseFieldNames.userId: userId,
          FirebaseFieldNames.rewardId: rewardId,
          FirebaseFieldNames.pointsSpent: reward.costPoints,
          FirebaseFieldNames.redeemedAt: DateTime.now().millisecondsSinceEpoch,
          FirebaseFieldNames.status: UserRewardStatus.redeemed.name,
          FirebaseFieldNames.notes: notes,
        });
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

  /// Fetch user's reward history
  Future<List<UserRewardModel>> fetchUserRewardHistory(String userId) async {
    try {
      final querySnapshot = await _db
          .collection(FirebaseCollectionNames.userRewards)
          .where(FirebaseFieldNames.userId, isEqualTo: userId)
          .orderBy(FirebaseFieldNames.redeemedAt, descending: true)
          .get();

      final userRewards = <UserRewardModel>[];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final rewardId = data[FirebaseFieldNames.rewardId] as String;

        // Fetch reward details
        final reward = await fetchRewardById(rewardId);

        userRewards.add(UserRewardModel.fromSnapshot(doc, rewardObj: reward));
      }

      return userRewards;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Fetch user's redeemed avatar frames
  Future<List<UserRewardModel>> fetchUserAvatarFrames(String userId) async {
    try {
      final querySnapshot = await _db
          .collection(FirebaseCollectionNames.userRewards)
          .where(FirebaseFieldNames.userId, isEqualTo: userId)
          .orderBy(FirebaseFieldNames.redeemedAt, descending: true)
          .get();

      final avatarFrames = <UserRewardModel>[];

      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        final rewardId = data[FirebaseFieldNames.rewardId] as String;

        // Fetch reward details
        final reward = await fetchRewardById(rewardId);

        // Only include avatar frames
        if (reward.rewardType == RewardType.avatarFrame) {
          avatarFrames.add(UserRewardModel.fromSnapshot(doc, rewardObj: reward));
        }
      }

      return avatarFrames;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Apply avatar frame to user
  Future<void> applyAvatarFrame(String userId, String rewardId) async {
    try {
      await _db.collection(FirebaseCollectionNames.users).doc(userId).update({
        FirebaseFieldNames.currentAvatarFrame: rewardId,
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Remove avatar frame from user
  Future<void> removeAvatarFrame(String userId) async {
    try {
      await _db.collection(FirebaseCollectionNames.users).doc(userId).update({
        FirebaseFieldNames.currentAvatarFrame: null,
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Get user's current reward points
  Future<int> getUserRewardPoints(String userId) async {
    try {
      final doc = await _db.collection(FirebaseCollectionNames.users).doc(userId).get();

      if (!doc.exists) {
        return 0;
      }

      return doc.data()?[FirebaseFieldNames.rewardPoints] ?? 0;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Get all rewards stream for admin (including inactive) - Admin only
  Stream<List<RewardModel>> getAllRewardsForAdminStream() {
    try {
      return _db
          .collection(FirebaseCollectionNames.rewards)
          .orderBy(FirebaseFieldNames.updatedAt, descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
          .map((doc) => RewardModel.fromSnapshot(doc))
          .toList());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Create reward (Admin only)
  Future<void> createRewardForAdmin(RewardModel reward) async {
    try {
      final rewardId = const Uuid().v4();
      final now = DateTime.now();

      final rewardWithId = reward.copyWith(
        rewardId: rewardId,
        createdAt: now,
        updatedAt: now,
      );

      await _db
          .collection(FirebaseCollectionNames.rewards)
          .doc(rewardId)
          .set(rewardWithId.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Update reward (Admin only)
  Future<void> updateRewardForAdmin(RewardModel reward) async {
    try {
      final updatedReward = reward.copyWith(
        updatedAt: DateTime.now(),
      );

      await _db
          .collection(FirebaseCollectionNames.rewards)
          .doc(reward.rewardId)
          .update(updatedReward.toJson());
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Enable/Disable reward (Admin only)
  Future<void> toggleRewardStatus(String rewardId, bool isActive) async {
    try {
      await _db.collection(FirebaseCollectionNames.rewards).doc(rewardId).update({
        FirebaseFieldNames.isActive: isActive,
        FirebaseFieldNames.updatedAt: DateTime.now().millisecondsSinceEpoch,
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Batch enable/disable rewards (Admin only)
  Future<void> batchToggleRewardStatus(List<String> rewardIds, bool isActive) async {
    try {
      final batch = _db.batch();
      final now = DateTime.now().millisecondsSinceEpoch;

      for (final id in rewardIds) {
        batch.update(
          _db.collection(FirebaseCollectionNames.rewards).doc(id),
          {
            FirebaseFieldNames.isActive: isActive,
            FirebaseFieldNames.updatedAt: now,
          },
        );
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Delete reward (Admin only)
  Future<void> deleteReward(String rewardId) async {
    try {
      await _db.collection(FirebaseCollectionNames.rewards).doc(rewardId).delete();
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }
}