import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/constants/firebase_field_names.dart';
import 'base_account_model.dart';

class AdminModel extends BaseAccountModel {
  int loginAttempt;
  int lastAttemptTime;

  AdminModel({
    required super.userId,
    required super.username,
    required super.userType,
    required super.email,
    super.phoneNumber,
    super.profileImg,
    required super.joinDate,
    required super.isVerify,
    super.accountAvailable,
    super.isDeleted,
    super.lastActive,
    this.loginAttempt = 5,
    this.lastAttemptTime = 0,
  });

  static AdminModel empty() {
    return AdminModel(
      userId: '',
      username: '',
      userType: 'admin',
      email: '',
      phoneNumber: '',
      profileImg: '',
      joinDate: DateTime.now(),
      isVerify: false,
      accountAvailable: true,
      isDeleted: false,
      lastActive: 0,
      loginAttempt: 5,
      lastAttemptTime: 0,
    );
  }

  AdminModel copyWith({
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
    int? loginAttempt,
    int? lastAttemptTime,
  }) {
    return AdminModel(
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
      loginAttempt: loginAttempt ?? this.loginAttempt,
      lastAttemptTime: lastAttemptTime ?? this.lastAttemptTime,
    );
  }

  factory AdminModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    if (data == null) return AdminModel.empty();

    return AdminModel(
      userId: data[FirebaseFieldNames.userId] ?? '',
      username: data[FirebaseFieldNames.username] ?? '',
      userType: data[FirebaseFieldNames.userType] ?? 'admin',
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
      loginAttempt: data[FirebaseFieldNames.loginAttempt] ?? 5,
      lastAttemptTime: data[FirebaseFieldNames.lastAttemptTime] ?? 0,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final map = super.toJson();
    map.addAll({
      FirebaseFieldNames.loginAttempt: loginAttempt,
      FirebaseFieldNames.lastAttemptTime: lastAttemptTime,
    });
    return map;
  }
}
