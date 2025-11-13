import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/formatters/formatter.dart';

abstract class BaseAccountModel {
  final String userId;
  final String username;
  final String userType; // 'user' or 'admin'
  final String email;
  String phoneNumber;
  String profileImg;
  final DateTime joinDate;
  final bool isVerify;
  bool accountAvailable;

  BaseAccountModel({
    required this.userId,
    required this.username,
    required this.userType,
    required this.email,
    this.phoneNumber = '',
    this.profileImg = '',
    required this.joinDate,
    required this.isVerify,
    this.accountAvailable = true,
  });

  Map<String, dynamic> toJson() => {
    FirebaseFieldNames.userId: userId,
    FirebaseFieldNames.username: username,
    FirebaseFieldNames.userType: userType,
    FirebaseFieldNames.email: email,
    FirebaseFieldNames.phoneNumber: phoneNumber,
    FirebaseFieldNames.profileImg: profileImg,
    FirebaseFieldNames.joinDate: joinDate.millisecondsSinceEpoch,
    FirebaseFieldNames.isVerify: isVerify,
    FirebaseFieldNames.accountAvailable: accountAvailable,
  };

  /// Helper function to format phone number
  String get formattedPhoneNo => TFormatter.formatPhoneNumber(phoneNumber);
}
