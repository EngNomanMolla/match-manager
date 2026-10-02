import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/navigation_controller.dart';
import '../../theme/app_theme.dart';
import '../home/home_view.dart';
import '../groups/groups_view.dart';
import '../media/media_view.dart';
import '../more/more_view.dart';

class MainNavView extends StatelessWidget {
  const MainNavView({super.key});

  @override
  Widget build(BuildContext context) {
    final navController = Get.find<NavigationController>();

    final List<Widget> pages = const [
      HomeView(),
      GroupsView(),
      MediaView(),
      MoreView(),
    ];

    return Scaffold(
      body: Obx(() => IndexedStack(
            index: navController.currentIndex.value,
            children: pages,
          )),
      bottomNavigationBar: Obx(() => Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
            ),
            child: BottomNavigationBar(
              currentIndex: navController.currentIndex.value,
              onTap: (index) => navController.changeIndex(index),
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: const Color(0xFF94A3B8),
              selectedFontSize: 12,
              unselectedFontSize: 12,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
              elevation: 0,
              items: [
                BottomNavigationBarItem(
                  icon: const Icon(Icons.home_outlined),
                  activeIcon: const Icon(Icons.home_rounded),
                  label: 'nav_home'.tr,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.groups_outlined),
                  activeIcon: const Icon(Icons.groups_rounded),
                  label: 'nav_groups'.tr,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.receipt_long_outlined),
                  activeIcon: const Icon(Icons.receipt_long_rounded),
                  label: 'nav_media'.tr,
                ),
                BottomNavigationBarItem(
                  icon: const Icon(Icons.more_horiz_rounded),
                  activeIcon: const Icon(Icons.more_horiz_rounded),
                  label: 'nav_more'.tr,
                ),
              ],
            ),
          )),
    );
  }
}
