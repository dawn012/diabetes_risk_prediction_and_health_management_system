import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../meal_recommendation/models/meal_preference_model.dart';
import '../../personalization/models/user_profile_model.dart';
import 'base_account_model.dart';

class UserModel extends BaseAccountModel {
  int totalScore;
  int lastScoreUpdateTime;
  int rewardPoints;
  String? currentAvatarFrame;
  final UserProfileModel profile;
  final MealPreferenceModel mealPreferences;

  UserModel({
    required super.userId,
    required super.username,
    required super.userType,
    required super.email,
    super.phoneNumber,
    super.profileImg,
    required super.joinDate,
    required super.isVerify,
    required super.accountAvailable,
    super.isDeleted,
    super.lastActive,
    this.totalScore = 0,
    this.lastScoreUpdateTime = 0,
    this.rewardPoints = 0,
    this.currentAvatarFrame,
    UserProfileModel? profile,
    MealPreferenceModel? mealPreferences, // 添加饮食偏好参数
  }) : profile = profile ?? UserProfileModel.empty(),
        mealPreferences = mealPreferences ?? MealPreferenceModel.empty();

  /// empty factory
  static UserModel empty() {
    return UserModel(
      userId: '',
      username: '',
      userType: 'user',
      email: '',
      phoneNumber: '',
      profileImg: '',
      joinDate: DateTime.now(),
      isVerify: false,
      accountAvailable: true,
      isDeleted: false,
      lastActive: 0,
      totalScore: 0,
      lastScoreUpdateTime: 0,
      rewardPoints: 0,
      currentAvatarFrame: null,
      profile: UserProfileModel.empty(),
      mealPreferences: MealPreferenceModel.empty(),
    );
  }

  /// copyWith
  UserModel copyWith({
    String? userId,
    String? username,
    String? userType,
    String? email,
    String? phoneNumber,
    String? profileImg,
    DateTime? joinDate,
    bool? isVerify,
    bool? accountAvailable,
    bool? isDeleted,
    int? lastActive,
    int? totalScore,
    int? lastScoreUpdateTime,
    int? rewardPoints,
    String? currentAvatarFrame,
    UserProfileModel? profile,
    MealPreferenceModel? mealPreferences,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      userType: userType ?? this.userType,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImg: profileImg ?? this.profileImg,
      joinDate: joinDate ?? this.joinDate,
      isVerify: isVerify ?? this.isVerify,
      accountAvailable: accountAvailable ?? this.accountAvailable,
      isDeleted: isDeleted ?? this.isDeleted,
      lastActive: lastActive ?? this.lastActive,
      totalScore: totalScore ?? this.totalScore,
      lastScoreUpdateTime: lastScoreUpdateTime ?? this.lastScoreUpdateTime,
      rewardPoints: rewardPoints ?? this.rewardPoints,
      currentAvatarFrame: currentAvatarFrame ?? this.currentAvatarFrame,
      profile: profile ?? this.profile,
      mealPreferences: mealPreferences ?? this.mealPreferences,
    );
  }

  /// fromSnapshot
  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return UserModel.empty();

    // 解析 UserProfileModel
    UserProfileModel profile;
    if (data[FirebaseFieldNames.profile] != null &&
        data[FirebaseFieldNames.profile] is Map<String, dynamic>) {
      profile = UserProfileModel.fromMap(data[FirebaseFieldNames.profile]);
    } else {
      profile = UserProfileModel.empty();
    }

    // 解析 MealPreferenceModel
    MealPreferenceModel mealPreferences;
    if (data[FirebaseFieldNames.mealPreferences] != null &&
        data[FirebaseFieldNames.mealPreferences] is Map<String, dynamic>) {
      mealPreferences = MealPreferenceModel.fromMap(data[FirebaseFieldNames.mealPreferences]);
    } else {
      mealPreferences = MealPreferenceModel.empty();
    }

    return UserModel(
      userId: data[FirebaseFieldNames.userId] ?? '',
      username: data[FirebaseFieldNames.username] ?? '',
      userType: data[FirebaseFieldNames.userType] ?? 'user',
      email: data[FirebaseFieldNames.email] ?? '',
      phoneNumber: data[FirebaseFieldNames.phoneNumber] ?? '',
      profileImg: data[FirebaseFieldNames.profileImg] ?? '',
      joinDate: data[FirebaseFieldNames.joinDate] != null
          ? DateTime.fromMillisecondsSinceEpoch(data[FirebaseFieldNames.joinDate])
          : DateTime.now(),
      isVerify: data[FirebaseFieldNames.isVerify] ?? false,
      accountAvailable: data[FirebaseFieldNames.accountAvailable] ?? true,
      isDeleted: data[FirebaseFieldNames.isDeleted] ?? false,
      lastActive: data[FirebaseFieldNames.lastActive] ?? 0,
      totalScore: data[FirebaseFieldNames.totalScore] ?? 0,
      lastScoreUpdateTime: data[FirebaseFieldNames.lastScoreUpdateTime] ?? 0,
      rewardPoints: data[FirebaseFieldNames.rewardPoints] ?? 0,
      currentAvatarFrame: data[FirebaseFieldNames.currentAvatarFrame],
      profile: profile,
      mealPreferences: mealPreferences,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({
      FirebaseFieldNames.totalScore: totalScore,
      FirebaseFieldNames.lastScoreUpdateTime: lastScoreUpdateTime,
      FirebaseFieldNames.rewardPoints: rewardPoints,
      FirebaseFieldNames.currentAvatarFrame: currentAvatarFrame,
      FirebaseFieldNames.profile: profile.toJson(),
      FirebaseFieldNames.mealPreferences: mealPreferences.toJson(),
    });
    return map;
  }
}