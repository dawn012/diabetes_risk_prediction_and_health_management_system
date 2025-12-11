import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/formatters/formatter.dart';
import '../../../utils/validators/user_profile_validator.dart';

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
  bool isDeleted;
  int lastActive;

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
    this.isDeleted = false,
    this.lastActive = 0,
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
    FirebaseFieldNames.isDeleted: isDeleted,
    FirebaseFieldNames.lastActive: lastActive,
  };

  /// Helper function to format phone number
  String get formattedPhoneNo {
    if (phoneNumber.isEmpty) {
      return '';
    }
    return TFormatter.formatPhoneNumber(phoneNumber);
  }

  String get phoneNumberDisplay =>
      TUserProfileValidator.convertToDisplayFormat(phoneNumber);
}
