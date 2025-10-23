import 'package:flutter/material.dart';

class TCustomCurvedEdges extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height);  // 改为 0.75，蓝色区域更多

    // 第一个曲线（左下角）- 向上凸起
    final firstCurve = Offset(0, size.height - 10);  // 向上凸起 20px
    final lastCurve = Offset(30, size.height - 10);
    path.quadraticBezierTo(firstCurve.dx, firstCurve.dy, lastCurve.dx, lastCurve.dy);

    // 中间的水平线（顶部凸起部分）
    final secondFirstCurve = Offset(0, size.height - 10);
    final secondLastCurve = Offset(size.width - 30, size.height - 10);
    path.quadraticBezierTo(secondFirstCurve.dx, secondFirstCurve.dy, secondLastCurve.dx, secondLastCurve.dy);

    // 第二个曲线（右下角）- 向上凸起
    final thirdFirstCurve = Offset(size.width, size.height - 10);
    final thirdLastCurve = Offset(size.width, size.height);
    path.quadraticBezierTo(thirdFirstCurve.dx, thirdFirstCurve.dy, thirdLastCurve.dx, thirdLastCurve.dy);

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}