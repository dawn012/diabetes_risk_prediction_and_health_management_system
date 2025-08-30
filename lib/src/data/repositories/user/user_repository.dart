import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:diabetes_risk_prediction_and_health_management_system/src/utils/constants/firebase_field_names.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../features/authentication/models/user_model.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../authentication/authentication_repository.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final _db = FirebaseFirestore.instance;

  /// Function to save user data to Firestore
  Future<void> saveUserRecord(UserModel user) async {
    try {
      await _db.collection(FirebaseCollectionNames.users).doc(user.userId).set(user.toJson());
      // await _db.collection('Users').doc(user.id).set({
      //   'email': user.email,
      //   ''
      //   'providers': ['password'],
      //   'createdAt': FieldValue.serverTimestamp(),
      //   'lastLoginAt': FieldValue.serverTimestamp(),
      // });
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

  /// Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final documentSnapshot = await _db.collection(FirebaseCollectionNames.users).get();
      final list = documentSnapshot.docs.map((document) => UserModel.fromSnapshot(document)).toList();
      return list;
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

  /// Get users by status (active/banned)
  Future<List<UserModel>> getUsersByStatus(bool isActive) async {
    try {
      final documentSnapshot = await _db.collection(FirebaseCollectionNames.users).where(FirebaseFieldNames.accountAvailable, isEqualTo: isActive).get();
      final list = documentSnapshot.docs.map((document) => UserModel.fromSnapshot(document)).toList();
      return list;
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

  /// Function to fetch user details based on user ID
  Future<UserModel> fetchUserDetails() async {
    try {
      final documentSnapshot = await _db.collection(FirebaseCollectionNames.users).doc(AuthenticationRepository.instance.authUser?.uid).get();
      if (documentSnapshot.exists) {
        return UserModel.fromSnapshot(documentSnapshot);
      } else {
        return UserModel.empty();
      }
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

  Future<UserModel> fetchUserDetailsById(String userId) async {
    try {
      final documentSnapshot = await _db
          .collection(FirebaseCollectionNames.users)
          .doc(userId)
          .get();

      if (documentSnapshot.exists) {
        return UserModel.fromSnapshot(documentSnapshot);
      } else {
        return UserModel.empty();
      }
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

  /// Update any field in specific Users Collection
  Future<void> updateUserDetails(UserModel updatedUser) async {
    try {
      await _db.collection(FirebaseCollectionNames.users).doc(updatedUser.userId).update(updatedUser.toJson());
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

  /// Update any field in specific Users Collection
  Future<void> updateSingleField(Map<String, dynamic> json) async {
    try {
      await _db.collection(FirebaseCollectionNames.users).doc(AuthenticationRepository.instance.authUser?.uid).update(json);
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

  /// Ban a user
  Future<void> banUser(String userId) async {
    try {
      await _db.collection(FirebaseCollectionNames.users).doc(userId).update({
        FirebaseFieldNames.accountAvailable: false,
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

  /// Restore a banned user
  Future<void> restoreUser(String userId) async {
    try {
      await _db.collection(FirebaseCollectionNames.users).doc(userId).update({
        FirebaseFieldNames.accountAvailable: true,
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

  /// Function to remove user data from Firestore
  Future<void> removeUserRecord(String userId) async {
    try {
      await _db.collection(FirebaseCollectionNames.users).doc(userId).delete();
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

  /// Search users
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      // Firebase doesn't support full-text search, so we'll get all users and filter client-side
      final documentSnapshot = await _db.collection(FirebaseCollectionNames.users).get();
      final allUsers = documentSnapshot.docs.map((document) => UserModel.fromSnapshot(document)).toList();

      final filteredUsers = allUsers.where((user) {
        final searchTerm = query.toLowerCase();
        return user.username.toLowerCase().contains(searchTerm) ||
               user.email.toLowerCase().contains(searchTerm) ||
               user.userId.toLowerCase().contains(searchTerm) ||
               user.phoneNumber.toLowerCase().contains(searchTerm);
      }).toList();

      return filteredUsers;
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

  /// Get user statistics
  Future<Map<String, int>> getUserStatistics() async {
    try {
      final allUsersSnapshot = await _db.collection("Users").get();
      final activeUsersSnapshot = await _db
          .collection("Users")
          .where(FirebaseFieldNames.accountAvailable, isEqualTo: true)
          .get();
      final verifiedUsersSnapshot = await _db
          .collection("Users")
          .where(FirebaseFieldNames.isVerify, isEqualTo: true)
          .get();

      // Get today's new users
      final todayStart = DateTime.now().millisecondsSinceEpoch - (24 * 60 * 60 * 1000);
      final newTodaySnapshot = await _db
          .collection("Users")
          .where(FirebaseFieldNames.joinDate, isGreaterThan: todayStart)
          .get();

      return {
        'total': allUsersSnapshot.docs.length,
        'active': activeUsersSnapshot.docs.length,
        'banned': allUsersSnapshot.docs.length - activeUsersSnapshot.docs.length,
        'verified': verifiedUsersSnapshot.docs.length,
        'newToday': newTodaySnapshot.docs.length,
      };
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
