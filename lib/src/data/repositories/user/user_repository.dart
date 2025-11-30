import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../features/authentication/models/admin_model.dart';
import '../../../features/authentication/models/user_model.dart';
import '../../../features/personalization/models/user_profile_model.dart';
import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';
import '../authentication/authentication_repository.dart';

class UserRepository extends GetxController {
  static UserRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Collection reference
  late final CollectionReference _usersCollection;

  @override
  void onInit() {
    super.onInit();
    _usersCollection = _db.collection(FirebaseCollectionNames.users);
  }

  /// Stream all users (type: 'user')
  Stream<List<UserModel>> streamAllUsers() {
    try {
      return _db
          .collection(FirebaseCollectionNames.users)
          .where(FirebaseFieldNames.userType, isEqualTo: 'user')
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => UserModel.fromSnapshot(doc))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Stream all managers (type: 'admin', 'user manager', 'community manager', 'achievement manager')
  Stream<List<AdminModel>> streamAllManagers() {
    try {
      return _db
          .collection(FirebaseCollectionNames.users)
          .where(FirebaseFieldNames.userType, whereIn: [
        'user manager',
        'community manager',
        'achievement manager',
      ])
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => AdminModel.fromSnapshot(doc))
            .toList();
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Get all managers (non-stream version)
  Future<List<AdminModel>> getAllManagers() async {
    try {
      final documentSnapshot = await _db
          .collection(FirebaseCollectionNames.users)
          .where(FirebaseFieldNames.userType, whereIn: [
        'user manager',
        'community manager',
        'achievement manager',
      ])
          .get();

      final list = documentSnapshot.docs
          .map((document) => AdminModel.fromSnapshot(document))
          .toList();
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

  /// Save admin/manager record
  Future<void> saveAdminRecord(AdminModel admin) async {
    try {
      await _usersCollection.doc(admin.userId).set(admin.toJson());
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

  /// Function to save user data to Firestore with profile as contained object
  Future<void> saveUserRecord(UserModel user) async {
    try {
      await _usersCollection.doc(user.userId).set(user.toJson(), SetOptions(merge: true));
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

  /// Check if username is already taken (excluding current user)
  Future<bool> checkUsernameDuplicate(String username, String currentUserId) async {
    try {
      final querySnapshot = await _db
          .collection(FirebaseCollectionNames.users)
          .where(FirebaseFieldNames.username, isEqualTo: username)
          .get();

      // Check if any document exists with this username that's not the current user
      for (var doc in querySnapshot.docs) {
        if (doc.id != currentUserId) {
          return true; // Username is taken
        }
      }
      return false; // Username is available
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

  /// Check if phone number is already taken (excluding current user)
  Future<bool> checkPhoneNumberDuplicate(String phoneNumber, String currentUserId) async {
    try {
      // 如果电话号码为空，不需要检查重复
      if (phoneNumber.isEmpty) return false;

      final querySnapshot = await _db
          .collection(FirebaseCollectionNames.users)
          .where(FirebaseFieldNames.phoneNumber, isEqualTo: phoneNumber)
          .get();

      // Check if any document exists with this phone number that's not the current user
      for (var doc in querySnapshot.docs) {
        if (doc.id != currentUserId) {
          return true; // Phone number is taken
        }
      }
      return false; // Phone number is available
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

  /// Get user by email (returns raw data for login validation)
  Future<Map<String, dynamic>?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _db
          .collection(FirebaseCollectionNames.users)
          .where(FirebaseFieldNames.email, isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['userId'] = doc.id; // Add document ID as userId
      return data;
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

  /// Get user by phone number (returns raw data)
  Future<Map<String, dynamic>?> getUserByPhoneNumber(String phoneNumber) async {
    try {
      final querySnapshot = await _db
          .collection(FirebaseCollectionNames.users)
          .where(FirebaseFieldNames.phoneNumber, isEqualTo: phoneNumber)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final data = doc.data();
      data['userId'] = doc.id; // Add document ID as userId
      return data;
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

  /// Reset login attempts to 5 (for successful login or after timeout)
  Future<void> resetLoginAttempts(String userId) async {
    try {
      await _db.collection(FirebaseCollectionNames.users).doc(userId).update({
        FirebaseFieldNames.loginAttempt: 5,
        FirebaseFieldNames.lastAttemptTime: DateTime.now().millisecondsSinceEpoch,
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

  /// Decrement login attempt by 1 (for failed login)
  Future<void> decrementLoginAttempt(String userId) async {
    try {
      // Get current login attempt
      final doc = await _db
          .collection(FirebaseCollectionNames.users)
          .doc(userId)
          .get();

      if (!doc.exists) return;

      final currentAttempt = doc.data()?[FirebaseFieldNames.loginAttempt] ?? 5;
      final newAttempt = currentAttempt > 0 ? currentAttempt - 1 : 0;

      await _db.collection(FirebaseCollectionNames.users).doc(userId).update({
        FirebaseFieldNames.loginAttempt: newAttempt,
        FirebaseFieldNames.lastAttemptTime: DateTime.now().millisecondsSinceEpoch,
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

  /// Fetch admin details based on current user ID
  Future<AdminModel> fetchAdminDetails() async {
    try {
      final currentUserId = AuthenticationRepository.instance.authUser?.uid;
      if (currentUserId == null) throw 'User not authenticated';

      final documentSnapshot = await _db
          .collection(FirebaseCollectionNames.users)
          .doc(currentUserId)
          .get();

      if (documentSnapshot.exists) {
        return AdminModel.fromSnapshot(documentSnapshot);
      } else {
        return AdminModel.empty();
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

  /// Update admin details
  Future<void> updateAdminDetails(AdminModel updatedAdmin) async {
    try {
      await _db
          .collection(FirebaseCollectionNames.users)
          .doc(updatedAdmin.userId)
          .update(updatedAdmin.toJson());
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

  /// Get only regular users (userType = 'user')
  Future<List<UserModel>> getRegularUsers() async {
    try {
      final documentSnapshot = await _db
          .collection(FirebaseCollectionNames.users)
          .where(FirebaseFieldNames.userType, isEqualTo: 'user')
          .get();

      final list = documentSnapshot.docs
          .map((document) => UserModel.fromSnapshot(document))
          .toList();
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

  /// Function to fetch user details based on user ID (with profile as contained object)
  Future<UserModel> fetchUserDetails() async {
    try {
      final currentUserId = AuthenticationRepository.instance.authUser?.uid;
      if (currentUserId == null) throw 'User not authenticated';

      final documentSnapshot = await _db
          .collection(FirebaseCollectionNames.users)
          .doc(currentUserId)
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

  /// Stream to listen to user details changes in real-time
  Stream<UserModel> streamUserDetails() {
    try {
      final currentUserId = AuthenticationRepository.instance.authUser?.uid;
      if (currentUserId == null) throw 'User not authenticated';

      return _db
          .collection(FirebaseCollectionNames.users)
          .doc(currentUserId)
          .snapshots()
          .map((snapshot) {
        if (snapshot.exists) {
          return UserModel.fromSnapshot(snapshot);
        } else {
          return UserModel.empty();
        }
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Stream to listen to specific user by ID
  Stream<UserModel> streamUserDetailsById(String userId) {
    try {
      return _db
          .collection(FirebaseCollectionNames.users)
          .doc(userId)
          .snapshots()
          .map((snapshot) {
        if (snapshot.exists) {
          return UserModel.fromSnapshot(snapshot);
        } else {
          return UserModel.empty();
        }
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } catch (e) {
      throw TTexts.commonErrorMessage;
    }
  }

  /// Upload user profile image to Firebase Storage
  Future<String> uploadImage(String path, XFile image, {String? oldImageUrl}) async {
    try {
      final uuid = Uuid();

      // 获取文件扩展名
      final fileExtension = image.name.split('.').last.toLowerCase();

      // 生成唯一的文件名：uuid + 原始文件扩展名
      final uniqueFileName = '${uuid.v4()}.$fileExtension';

      // 使用唯一的文件名
      final ref = FirebaseStorage.instance.ref(path).child(uniqueFileName);

      if (kIsWeb) {
        // Web 平台：使用字节数据上传
        final bytes = await image.readAsBytes();
        await ref.putData(bytes);
      } else {
        // 移动端：使用文件路径上传
        await ref.putFile(File(image.path));
      }

      final url = await ref.getDownloadURL();

      // 上传成功后删除旧图片
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await deleteImage(oldImageUrl);
      }

      return url;
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      print('Upload image error: $e');
      throw 'Something went wrong. Please try again.';
    }
  }

  /// Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return;

      // 从完整的 URL 中提取 storage reference
      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.delete();
    } on FirebaseException catch (e) {
      // 如果图片不存在，忽略这个错误
      if (e.code != 'object-not-found') {
        throw TFirebaseException(e.code).message;
      }
    } catch (e) {
      print('Error deleting image: $e');
      // 不抛出异常，因为删除旧图片不是关键操作
    }
  }

  /// Update user details with profile as contained object
  Future<void> updateUserDetails(UserModel updatedUser) async {
    try {
      await _db
          .collection(FirebaseCollectionNames.users)
          .doc(updatedUser.userId)
          .update(updatedUser.toJson());
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
  Future<void> updateSingleField(Map<String, dynamic> json, {String? userId}) async {
    try {
      final String targetUserId;

      if (userId != null) {
        // 使用传入的用户ID
        targetUserId = userId;
      } else {
        // 使用当前登录用户的ID
        final currentUserId = AuthenticationRepository.instance.authUser?.uid;
        if (currentUserId == null) throw 'User not authenticated';
        targetUserId = currentUserId;
      }

      await _db
          .collection(FirebaseCollectionNames.users)
          .doc(targetUserId)
          .update(json);
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

  /// Update user profile as contained object (directly in user document)
  Future<void> updateUserProfile(String userId, UserProfileModel profile) async {
    try {
      await _db
          .collection(FirebaseCollectionNames.users)
          .doc(userId)
          .update({
        FirebaseFieldNames.profile: profile.toJson(),
      });
    } on FirebaseException catch (e) {
      throw TFirebaseException(e.code).message;
    } on FormatException catch (_) {
      throw const TFormatException();
    } on PlatformException catch (e) {
      throw TPlatformException(e.code).message;
    } catch (e) {
      print("Error: $e");
      throw TTexts.commonErrorMessage;
    }
  }

  /// Update specific fields in user profile (contained object)
  Future<void> updateProfileFields(String userId, Map<String, dynamic> profileData) async {
    try {
      // Build the update map with profile field prefix
      final updateData = <String, dynamic>{};
      profileData.forEach((key, value) {
        updateData['${FirebaseFieldNames.profile}.$key'] = value;
      });

      await _db
          .collection(FirebaseCollectionNames.users)
          .doc(userId)
          .update(updateData);
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

  /// Fetch user profile from contained object
  Future<UserProfileModel> fetchUserProfile(String userId) async {
    try {
      final documentSnapshot = await _db
          .collection(FirebaseCollectionNames.users)
          .doc(userId)
          .get();

      if (documentSnapshot.exists) {
        final data = documentSnapshot.data();
        if (data != null && data[FirebaseFieldNames.profile] != null) {
          final profileData = data[FirebaseFieldNames.profile] as Map<String, dynamic>;
          return UserProfileModel.fromMap(profileData);
        }
      }
      return UserProfileModel.empty();
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

  /// Update user's last active timestamp
  Future<void> updateLastActive(String userId) async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _db
          .collection(FirebaseCollectionNames.users)
          .doc(userId)
          .update({
        FirebaseFieldNames.lastActive: now,
      });
    } on FirebaseException catch (e) {
      // 不抛出异常，因为更新最后活跃时间不是关键操作
      print('Error updating last active: ${e.message}');
    } catch (e) {
      print('Error updating last active: $e');
    }
  }

  /// Ban a user
  Future<void> banUser(String userId, {String? banReason}) async {
    try {
      await _db.collection(FirebaseCollectionNames.users).doc(userId).update({
        FirebaseFieldNames.accountAvailable: false,
      });

      // 发送封禁邮件
      unawaited(sendUserBannedEmail(
        userId: userId,
        banReason: banReason ?? 'Violation of community guidelines.',
      ));
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

      // 发送恢复邮件 (从封禁状态恢复)
      unawaited(sendUserRestoredEmail(
        userId: userId,
        wasInactive: false, // false 表示从 banned 恢复
      ));
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

  /// Soft delete user (mark as deleted by user)
  Future<void> deleteAccount(String userId) async {
    try {
      await _db.collection(FirebaseCollectionNames.users).doc(userId).update({
        // FirebaseFieldNames.accountAvailable: false,
        FirebaseFieldNames.isDeleted: true, // 标记为用户自己删除
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

  /// Restore soft-deleted user
  Future<void> restoreAccount(String userId) async {
    try {
      await _db.collection(FirebaseCollectionNames.users).doc(userId).update({
        // FirebaseFieldNames.accountAvailable: false,
        FirebaseFieldNames.isDeleted: false,
      });

      // 发送恢复邮件 (从 inactive 状态恢复)
      unawaited(sendUserRestoredEmail(
        userId: userId,
        wasInactive: true, // true 表示从 inactive 恢复
      ));
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
      final allUsersSnapshot = await _db.collection(FirebaseCollectionNames.users).get();
      final activeUsersSnapshot = await _db
          .collection(FirebaseCollectionNames.users)
          .where(FirebaseFieldNames.accountAvailable, isEqualTo: true)
          .get();
      final verifiedUsersSnapshot = await _db
          .collection(FirebaseCollectionNames.users)
          .where(FirebaseFieldNames.isVerify, isEqualTo: true)
          .get();

      // Get today's new users
      final todayStart = DateTime.now().millisecondsSinceEpoch - (24 * 60 * 60 * 1000);
      final newTodaySnapshot = await _db
          .collection(FirebaseCollectionNames.users)
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

  /// Send ban email to a user
  Future<bool> sendUserBannedEmail({
    required String userId,
    String? banReason,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendUserBannedEmail');
      final response = await callable.call({
        'userId': userId,
        'banReason': banReason,
      });

      return response.data['success'] == true;
    } catch (e) {
      print('Error calling sendUserBannedEmail: $e');
      return false;
    }
  }

  /// Send restore email to a user
  Future<bool> sendUserRestoredEmail({
    required String userId,
    required bool wasInactive,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendUserRestoredEmail');
      final response = await callable.call({
        'userId': userId,
        'wasInactive': wasInactive,
      });

      return response.data['success'] == true;
    } catch (e) {
      print('Error calling sendUserRestoredEmail: $e');
      return false;
    }
  }

  /// Send batch ban emails to multiple users
  Future<Map<String, dynamic>> sendBatchUserBannedEmails({
    required List<String> userIds,
    String? banReason,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendBatchUserBannedEmails');
      final response = await callable.call({
        'userIds': userIds,
        'banReason': banReason,
      });

      return {
        'success': response.data['success'] == true,
        'succeeded': response.data['succeeded'] ?? 0,
        'failed': response.data['failed'] ?? 0,
        'message': response.data['message'] ?? '',
      };
    } catch (e) {
      print('Error calling sendBatchUserBannedEmails: $e');
      return {
        'success': false,
        'succeeded': 0,
        'failed': userIds.length,
        'message': 'Failed to send emails: $e',
      };
    }
  }

  /// Send batch restore emails to multiple users
  Future<Map<String, dynamic>> sendBatchUserRestoredEmails({
    required List<String> userIds,
    required bool wasInactive,
  }) async {
    try {
      final callable = _functions.httpsCallable('sendBatchUserRestoredEmails');
      final response = await callable.call({
        'userIds': userIds,
        'wasInactive': wasInactive,
      });

      return {
        'success': response.data['success'] == true,
        'succeeded': response.data['succeeded'] ?? 0,
        'failed': response.data['failed'] ?? 0,
        'message': response.data['message'] ?? '',
      };
    } catch (e) {
      print('Error calling sendBatchUserRestoredEmails: $e');
      return {
        'success': false,
        'succeeded': 0,
        'failed': userIds.length,
        'message': 'Failed to send emails: $e',
      };
    }
  }
}