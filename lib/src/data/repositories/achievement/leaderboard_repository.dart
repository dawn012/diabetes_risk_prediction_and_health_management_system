import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../utils/constants/firebase_collection_names.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/constants/text_strings.dart';
import '../../../utils/exceptions/firebase_exceptions.dart';
import '../../../utils/exceptions/format_exceptions.dart';
import '../../../utils/exceptions/platform_exceptions.dart';

class LeaderboardRepository extends GetxController {
  static LeaderboardRepository get instance => Get.find();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String get currentUserId => _auth.currentUser?.uid ?? '';

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// Get leaderboard collection reference
  CollectionReference<Map<String, dynamic>> get leaderboardRef =>
      _db.collection(FirebaseCollectionNames.leaderboard);

  /// Get users collection reference
  CollectionReference<Map<String, dynamic>> get usersRef =>
      _db.collection(FirebaseCollectionNames.users);

  /// Fetch current month leaderboard with improved ranking logic
  /// -排序规则：分数高 > 达成时间早 > 用户名字母顺序
  /// - 相同分数和时间的用户共享排名
  /// - 限制最多100人
  Future<List<Map<String, dynamic>>> fetchCurrentMonthLeaderboard({int limit = 100}) async {
    try {
      // 只获取有分数的用户（totalScore > 0）
      final querySnapshot = await usersRef
          .where(FirebaseFieldNames.accountAvailable, isEqualTo: true)
          .where(FirebaseFieldNames.totalScore, isGreaterThan: 0)
          .orderBy(FirebaseFieldNames.totalScore, descending: true)
          .orderBy(FirebaseFieldNames.lastScoreUpdateTime, descending: false)
          .orderBy(FirebaseFieldNames.username, descending: false)
          .limit(limit)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      // 转换数据并计算排名（处理相同分数和时间的情况）
      final users = querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': doc.id,
          'username': data[FirebaseFieldNames.username] ?? '',
          'totalScore': data[FirebaseFieldNames.totalScore] ?? 0,
          'lastScoreUpdateTime': data[FirebaseFieldNames.lastScoreUpdateTime] ?? 0,
          'profileImg': data[FirebaseFieldNames.profileImg] ?? '',
        };
      }).toList();

      // 计算排名（相同分数和时间共享排名）
      int currentRank = 1;
      int? lastScore;
      int? lastUpdateTime;

      for (int i = 0; i < users.length; i++) {
        final user = users[i];
        final score = user['totalScore'] as int;
        final updateTime = user['lastScoreUpdateTime'] as int;

        // 如果分数和时间都相同，则共享排名
        if (lastScore != null && lastUpdateTime != null &&
            score == lastScore && updateTime == lastUpdateTime) {
          user['rank'] = currentRank;
        } else {
          // 否则，排名为当前索引+1
          currentRank = i + 1;
          user['rank'] = currentRank;
        }

        lastScore = score;
        lastUpdateTime = updateTime;
      }

      return users;
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

  /// Fetch last month leaderboard (from Leaderboard collection)
  Future<List<Map<String, dynamic>>> fetchLastMonthLeaderboard() async {
    try {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1);
      final year = lastMonth.year;
      final month = lastMonth.month;

      final querySnapshot = await leaderboardRef
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .orderBy('rank', descending: false)
          .limit(100)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return [];
      }

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'userId': data['userId'] ?? '',
          'username': data['username'] ?? '',
          'totalScore': data['score'] ?? 0,
          'rank': data['rank'] ?? 0,
          'profileImg': data['profileImg'] ?? '',
        };
      }).toList();
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

  /// Get current user's rank in current month
  Future<int> getCurrentUserRank(String userId) async {
    try {
      final userDoc = await usersRef.doc(userId).get();
      if (!userDoc.exists) return -1;

      final userData = userDoc.data();
      final userScore = userData?[FirebaseFieldNames.totalScore] ?? 0;

      // 如果用户分数为0，返回-1（无排名）
      if (userScore == 0) return -1;

      final userUpdateTime = userData?[FirebaseFieldNames.lastScoreUpdateTime] ?? 0;

      // 获取所有比该用户分数高，或分数相同但时间更早的用户
      final higherScoreUsers = await usersRef
          .where(FirebaseFieldNames.accountAvailable, isEqualTo: true)
          .where(FirebaseFieldNames.totalScore, isGreaterThan: userScore)
          .get();

      final sameScoreUsers = await usersRef
          .where(FirebaseFieldNames.accountAvailable, isEqualTo: true)
          .where(FirebaseFieldNames.totalScore, isEqualTo: userScore)
          .where(FirebaseFieldNames.lastScoreUpdateTime, isLessThan: userUpdateTime)
          .get();

      return higherScoreUsers.docs.length + sameScoreUsers.docs.length + 1;
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

  /// Get user's rank from last month leaderboard
  Future<int?> getLastMonthUserRank(String userId) async {
    try {
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1);
      final year = lastMonth.year;
      final month = lastMonth.month;

      final querySnapshot = await leaderboardRef
          .where('year', isEqualTo: year)
          .where('month', isEqualTo: month)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final data = querySnapshot.docs.first.data();
      return data['rank'] as int?;
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

  /// Save monthly leaderboard snapshot (call this at the end of each month)
  Future<void> saveMonthlyLeaderboardSnapshot() async {
    try {
      final now = DateTime.now();
      final year = now.year;
      final month = now.month;

      // 获取当月排行榜（带排名信息）
      final topUsers = await fetchCurrentMonthLeaderboard(limit: 100);

      if (topUsers.isEmpty) return;

      // Batch write to leaderboard collection
      final batch = _db.batch();

      for (var user in topUsers) {
        final docRef = leaderboardRef.doc();

        batch.set(docRef, {
          'userId': user['userId'],
          'username': user['username'],
          'score': user['totalScore'],
          'rank': user['rank'],
          'year': year,
          'month': month,
          'profileImg': user['profileImg'],
          'timestamp': FieldValue.serverTimestamp(),
        });
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

  /// Get user's current score
  Future<int> getUserScore(String userId) async {
    try {
      final userDoc = await usersRef.doc(userId).get();
      if (!userDoc.exists) return 0;

      final userData = userDoc.data();
      return userData?[FirebaseFieldNames.totalScore] ?? 0;
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