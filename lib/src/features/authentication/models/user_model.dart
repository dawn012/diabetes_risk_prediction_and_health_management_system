import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/formatters/formatter.dart';
import '../../personalization/models/user_profile_model.dart';

class UserModel {
  final String userId;
  final String username;
  final String userType;
  final String email;
  String phoneNumber;
  String profileImg;
  final DateTime joinDate;
  int totalScore;
  final bool isVerify;
  int loginAttempt;
  int lastAttemptTime;
  final bool accountAvailable;
  UserProfileModel profile;

  /// Constructor
  UserModel({
    required this.userId,
    required this.username,
    required this.userType,
    required this.email,
    this.phoneNumber = '',
    this.profileImg = '',
    required this.joinDate,
    this.totalScore = 0,
    required this.isVerify,
    this.loginAttempt = 5,
    this.lastAttemptTime = 0,
    required this.accountAvailable,
    UserProfileModel? profile,
  }) : profile = profile ?? UserProfileModel.empty();
  
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
      profile: UserProfileModel.empty(),
    );
  }

  /// CopyWith method to create a new instance with updated fields
  UserModel copyWith({
    String? userId,
    String? username,
    String? userType,
    String? email,
    String? phoneNumber,
    String? profileImg,
    DateTime? joinDate,
    int? totalScore,
    bool? isVerify,
    int? loginAttempt,
    int? lastAttemptTime,
    bool? accountAvailable,
    UserProfileModel? profile,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userType: userType ?? this.userType,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImg: profileImg ?? this.profileImg,
      joinDate: joinDate ?? this.joinDate,
      totalScore: totalScore ?? this.totalScore,
      isVerify: isVerify ?? this.isVerify,
      loginAttempt: loginAttempt ?? this.loginAttempt,
      lastAttemptTime: lastAttemptTime ?? this.lastAttemptTime,
      accountAvailable: accountAvailable ?? this.accountAvailable,
      profile: profile ?? this.profile,
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
      FirebaseFieldNames.profile: profile.toJson(),
    };
  }

  /// Factory method to create a UserModel from a Firebase document snapshot
  /// 工厂构造方法允许返回已经存在的实例或根据逻辑创建新的实例
  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();
    if (data == null) return UserModel.empty();

    // 处理 profile 数据
    UserProfileModel profile;
    if (data[FirebaseFieldNames.profile] != null) {
      // 如果 profile 是 Map 类型（包含对象）
      final profileData = data[FirebaseFieldNames.profile] as Map<String, dynamic>;
      profile = UserProfileModel.fromMap(profileData);
    } else {
      profile = UserProfileModel.empty();
    }

    return UserModel(
      userId: data[FirebaseFieldNames.userId] ?? '',
      username: data[FirebaseFieldNames.username] ?? '',
      userType: data[FirebaseFieldNames.userType] ?? '',
      email: data[FirebaseFieldNames.email] ?? '',
      phoneNumber: data[FirebaseFieldNames.phoneNumber] ?? '',
      profileImg: data[FirebaseFieldNames.profileImg] ?? '',
      joinDate: data[FirebaseFieldNames.joinDate] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.joinDate])
          : DateTime.now(),
      totalScore: data[FirebaseFieldNames.totalScore] ?? 0,
      isVerify: data[FirebaseFieldNames.isVerify] ?? false,
      loginAttempt: data[FirebaseFieldNames.loginAttempt] ?? 0,
      lastAttemptTime: data[FirebaseFieldNames.lastAttemptTime] ?? 0,
      accountAvailable: data[FirebaseFieldNames.accountAvailable] ?? true,
      profile: profile,
    );
  }
}