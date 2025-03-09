import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../utils/constants/colors.dart';
import '../controllers/community_menu_controller.dart';
import 'posts/posts_screen.dart';
import 'videos/videos_screen.dart';

class CommunityMenu extends StatelessWidget {
  const CommunityMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(CommunityController());

    return Scaffold(
      backgroundColor: TColors.communityBgColor,
      appBar: AppBar(
        title: const Text(
            'Community',
            style: TextStyle(
              color: TColors.primary,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
        ),
        backgroundColor: TColors.white,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(45),
          child: Obx(() => TabBar(
            tabs: CommunityMenu.getHomeScreenTabs(controller.currentIndex.value),
            controller: controller.tabController,
            onTap: (index) {
              controller.currentIndex.value = index;
              controller.tabController.animateTo(index);
            },
          )),
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: screens,
      ),
    );
  }

  static List<Tab> getHomeScreenTabs(int index) {
    return [
      Tab(
        icon: Icon(
          index == 0 ? Icons.home : Icons.home_outlined,
          color: Colors.blue,
        ),
      ),
      Tab(
        icon: Icon(
          index == 1 ? Icons.group : Icons.group_outlined,
          color: Colors.blue,
        ),
      ),
      Tab(
        icon: Icon(
          index == 2 ? Icons.smart_display : Icons.smart_display_outlined,
          color: Colors.blue,
        ),
      ),
      // Tab(
      //   icon: Icon(
      //     index == 3 ? Icons.account_circle : Icons.account_circle_outlined,
      //     color: Colors.blue,
      //   ),
      // ),
      // Tab(
      //   icon: Icon(
      //     index == 4 ? Icons.density_medium : Icons.density_medium_outlined,
      //     color: Colors.blue,
      //   ),
      // ),
    ];
  }

  static const List<Widget> screens = [
    PostsScreen(),
    Center(child: Text('Friends Screen')),
    VideosScreen(),
  ];
}

