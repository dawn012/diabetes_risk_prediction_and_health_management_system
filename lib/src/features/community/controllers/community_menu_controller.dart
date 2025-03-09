import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CommunityController extends GetxController with GetSingleTickerProviderStateMixin {
  late final TabController tabController;
  final currentIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 3, vsync: this);
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }
}
