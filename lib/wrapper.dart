// import 'package:diabetes_risk_prediction_and_health_management_system/src/features/homepage.dart';
// import 'package:diabetes_risk_prediction_and_health_management_system/login.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
//
// class Wrapper extends StatefulWidget {
//   const Wrapper({super.key});
//
//   @override
//   State<Wrapper> createState() => _WrapperState();
// }
//
// class _WrapperState extends State<Wrapper> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: StreamBuilder(
//           stream: FirebaseAuth.instance.authStateChanges(),
//           builder: (context, snapshot) {
//             // 检查流中是否有数据。若为 true，说明用户已登录
//             if (snapshot.hasData) {
//               // snapshot.data 是当前登录用户的 User 对象
//               print(snapshot.data);
//               // 检查用户的电子邮件是否已被验证
//               if (snapshot.data!.emailVerified) {
//                 return Homepage();
//               } else {
//                 // return Verify();
//               }
//             }
//             else {
//               return Login();
//             }
//           }
//       ),
//     );
//   }
// }
