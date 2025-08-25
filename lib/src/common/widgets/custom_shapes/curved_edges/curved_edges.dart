import 'package:flutter/material.dart';

class TCustomCurvedEdges extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {  // size 表示当前组件（Widget）的宽度和高度，是 Flutter 自动计算并传递 的，而不是手动传入的
    var path = Path();  // 创建一个 Path 对象，用于绘制路径（比如直线、曲线）。
    path.lineTo(0, size.height * 0.8);  // 从 (0,0) 开始（默认 Path 的起点），绘制一条直线到 (0, size.height)，即 左下角

    // size.height 代表组件的底部（即默认的下边界）
    final firstCurve = Offset(0, size.height * 0.8 - 20);  // size.height - 20 代表比底部 上移 20px（即往上凹陷 20px）。
    final lastCurve = Offset(30, size.height * 0.8 - 20);
    path.quadraticBezierTo(firstCurve.dx, firstCurve.dy, lastCurve.dx, lastCurve.dy);

    final secondFirstCurve = Offset(0, size.height * 0.8 - 20);
    final secondLastCurve = Offset(size.width - 30, size.height * 0.8 - 20);
    path.quadraticBezierTo(secondFirstCurve.dx, secondFirstCurve.dy, secondLastCurve.dx, secondLastCurve.dy);

    final thirdFirstCurve = Offset(size.width, size.height * 0.8 - 20);
    final thirdLastCurve = Offset(size.width, size.height * 0.8);
    path.quadraticBezierTo(thirdFirstCurve.dx, thirdFirstCurve.dy, thirdLastCurve.dx, thirdLastCurve.dy);

    path.lineTo(size.width, 0);  // 连接到右上角，绘制一条直线到 (size.width, 0)。
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}