import 'package:jiffy/jiffy.dart';

// extension ExtensionName on ClassName {
//   ReturnType methodName(Parameters) {
//     // 方法逻辑
//   }
// }

// ExtensionName 是扩展的名称（随便取，但要有意义）。
// on ClassName 表示这个扩展作用在哪个类上（比如 DateTime）。
// 方法的 this 代表被扩展的类的实例。

/// 给 DateTime 增加了一个 yMMMEd() 方法，用于格式化日期
extension FormatDate on DateTime {
  String yMMMEd() => Jiffy.parseFromDateTime(this).yMMMEd;  // Mon, Sep 10, 2004
}

/// 给 DateTime 增加了 fromNow() 方法，返回相对时间（比如“3 天前”）
extension FromNow on DateTime {
  String fromNow() => Jiffy.parseFromDateTime(this).fromNow();
}