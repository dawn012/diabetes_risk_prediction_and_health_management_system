import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

import '../../../utils/constants/firebase_field_names.dart';
import '../../../utils/formatters/formatter.dart';

class UserModel {
  final String uid;
  final String username;
  final String email;
  String phoneNumber;
  String profilePicture;
  // final List<String> friends;
  // final List<String> sentRequests;
  // final List<String> receivedRequests;

  /// Constructor
  UserModel({
    required this.uid,
    required this.username,
    required this.email,
    required this.phoneNumber,
    required this.profilePicture,
  });
  
  /// Helper function to format phone number
  String get formattedPhoneNo => TFormatter.formatPhoneNumber(phoneNumber);

  /// Static function to create an empty user model
  static UserModel empty() {
    return UserModel(
      uid: '',
      username: '',
      email: '',
      phoneNumber: '',
      profilePicture: '',
    );
  }

  /// Convert model to JSON structure for storing data in Firebase
  Map<String, dynamic> toJson() {
    return {
      FirebaseFieldNames.uid: uid,
      FirebaseFieldNames.username: username,
      FirebaseFieldNames.email: email,
      FirebaseFieldNames.phoneNumber: phoneNumber,
      FirebaseFieldNames.profilePicture: profilePicture,
    };
  }

  /// Factory method to create a UserModel from a Firebase document snapshot
  /// 工厂构造方法允许返回已经存在的实例或根据逻辑创建新的实例
  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    if (document.data() != null) {
      final data = document.data()!;
      return UserModel(
          uid: data[FirebaseFieldNames.uid] ?? '',
          username: data[FirebaseFieldNames.username] ?? '',
          email: data[FirebaseFieldNames.email] ?? '',
          phoneNumber: data[FirebaseFieldNames.phoneNumber] ?? '',
          profilePicture: data[FirebaseFieldNames.profilePicture] ?? '',
      );
    } else {
      return UserModel.empty();
    }
  }
}