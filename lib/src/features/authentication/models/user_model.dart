import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/formatters/formatter.dart';

class UserModel {
  final String userId;
  final String username;
  final String userType;
  final String email;
  String phoneNumber;
  String profileImg;
  final DateTime joinDate;
  final int totalScore;
  final bool isVerify;
  final int loginAttempt;
  final int lastAttemptTime;
  final bool accountAvailable;
  // final List<String> friends;
  // final List<String> sentRequests;
  // final List<String> receivedRequests;

  /// Constructor
  UserModel({
    required this.userId,
    required this.username,
    required this.userType,
    required this.email,
    required this.phoneNumber,
    required this.profileImg,
    required this.joinDate,
    required this.totalScore,
    required this.isVerify,
    required this.loginAttempt,
    required this.lastAttemptTime,
    required this.accountAvailable,
  });
  
  /// Helper function to format phone number
  String get formattedPhoneNo => TFormatter.formatPhoneNumber(phoneNumber);

  /// Static function to create an empty user model
  static UserModel empty() {
    return UserModel(
      userId: '',
      username: '',
      userType: '',
      email: '',
      phoneNumber: '',
      profileImg: '',
      joinDate: DateTime.now(),
      totalScore: 0,
      isVerify: false,
      loginAttempt: 0,
      lastAttemptTime: 0,
      accountAvailable: true,
    );
  }

  /// Convert model to JSON structure for storing data in Firebase
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.userId: userId,
      FirebaseFieldNames.username: username,
      FirebaseFieldNames.userType: userType,
      FirebaseFieldNames.email: email,
      FirebaseFieldNames.phoneNumber: phoneNumber,
      FirebaseFieldNames.profileImg: profileImg,
      FirebaseFieldNames.joinDate: joinDate.millisecondsSinceEpoch,
      FirebaseFieldNames.totalScore: totalScore,
      FirebaseFieldNames.isVerify: isVerify,
      FirebaseFieldNames.loginAttempt: loginAttempt,
      FirebaseFieldNames.lastAttemptTime: lastAttemptTime,
      FirebaseFieldNames.accountAvailable: accountAvailable,
    };
  }

  /// Factory method to create a UserModel from a Firebase document snapshot
  /// 工厂构造方法允许返回已经存在的实例或根据逻辑创建新的实例
  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) return UserModel.empty();

    return UserModel(
      userId: data[FirebaseFieldNames.userId] ?? '',
      username: data[FirebaseFieldNames.username] ?? '',
      userType: data[FirebaseFieldNames.userType] ?? '',
      email: data[FirebaseFieldNames.email] ?? '',
      phoneNumber: data[FirebaseFieldNames.phoneNumber] ?? 0,
      profileImg: data[FirebaseFieldNames.profileImg] ?? '',
      joinDate: data[FirebaseFieldNames.joinDate] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.joinDate])
          : DateTime.now(),
      totalScore: data[FirebaseFieldNames.totalScore] ?? 0,
      isVerify: data[FirebaseFieldNames.isVerify] ?? false,
      loginAttempt: data[FirebaseFieldNames.loginAttempt] ?? 0,
      lastAttemptTime: data[FirebaseFieldNames.lastAttemptTime] ?? 0,
      accountAvailable: data[FirebaseFieldNames.accountAvailable] ?? true,
    );
  }
}