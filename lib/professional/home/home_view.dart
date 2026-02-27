import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:verithrive_dev/theme/font_sizes.dart';
import 'package:verithrive_dev/theme/hight_width_sizes.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/fonts.dart';
import '../../theme/image_paths.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';
import 'dashboard_view.dart';
import 'calendar_view.dart';
import 'home_controller.dart';
import 'calendar_controller.dart';
import 'message_view.dart';
import 'messages_controller.dart';
import 'profile_controller.dart';
import 'profile_view.dart';

class HomeView extends BaseView<HomeController> {
  const HomeView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 1),
      child: Obx(() {
        final index = controller.currentIndex.value;
        return Container(
          decoration: const BoxDecoration(
            color: AppColor.white,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A000000), // #0000001A
                blurRadius: 15,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: Colors.white,
            elevation: 0,
            titleSpacing: 16,
            title: _buildAppBarContent(index),
          ),
        );
      }),
    );
  }

  Widget _buildAppBarContent(int index) {
    switch (index) {
      case 0:
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppImages.home_logo_image(
              width: HightWidthSizes.setValue_100,
              height: HightWidthSizes.setValue_50,
              fit: BoxFit.contain,
            ),
            _NotificationIconWithBadge(controller: controller),
          ],
        );
      case 1:
        final calendarController = Get.find<CalendarController>();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Calendar',
                style: TextStyle(
                  fontFamily: AppFonts.rubikMedium,
                  fontWeight: FontWeight.w500,
                  fontSize: FontSizes.setFontValue_18,
                  color: AppColor.color_414141,
                )),
            _NotificationIconWithBadge(controller: calendarController),
          ],
        );
      case 2:
        return Center(
            child: Text('Messages',
                style: TextStyle(
                  fontFamily: AppFonts.rubikMedium,
                  fontWeight: FontWeight.w500,
                  fontSize: FontSizes.setFontValue_18,
                  color: AppColor.color_414141,
                )));
      case 3:
      default:
        return Text('Profile',
            style: TextStyle(
              fontFamily: AppFonts.rubikMedium,
              fontWeight: FontWeight.w500,
              fontSize: FontSizes.setFontValue_18,
              color: AppColor.color_414141,
            ));
    }
  }

  @override
  Widget? bottomNavigationBar(BuildContext context) {
    return Obx(() {
      final index = controller.currentIndex.value;
      return Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 24,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          currentIndex: index,
          onTap: controller.onTabSelected,
          selectedItemColor: AppColor.color_2FC4B2,
          unselectedItemColor: AppColor.color_BFBFBF,
          selectedLabelStyle: TextStyle(
            fontFamily: AppFonts.rubikRegular,
            fontWeight: FontWeight.w400,
            fontSize: FontSizes.setFontValue_12,
            letterSpacing: 0.12,
            height: 2,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: AppFonts.rubikRegular,
            fontWeight: FontWeight.w400,
            fontSize: FontSizes.setFontValue_12,
            letterSpacing: 0.12,
            height: 2,
          ),
          items: [
            BottomNavigationBarItem(
              icon: AppImages.bottom_home_svg(
                width: HightWidthSizes.setValue_20,
                height: HightWidthSizes.setValue_20,
              ),
              activeIcon: AppImages.bottom_home_selected_svg(
                width: HightWidthSizes.setValue_20,
                height: HightWidthSizes.setValue_20,
              ),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: AppImages.bottom_calender_svg(
                width: HightWidthSizes.setValue_20,
                height: HightWidthSizes.setValue_20,
              ),
              activeIcon: AppImages.bottom_calender_selected_svg(
                width: HightWidthSizes.setValue_20,
                height: HightWidthSizes.setValue_20,
              ),
              label: 'Calendar',
            ),
            BottomNavigationBarItem(
              icon: AppImages.bottom_chat_svg(
                width: HightWidthSizes.setValue_20,
                height: HightWidthSizes.setValue_20,
              ),
              activeIcon: AppImages.bottom_chat_selected_svg(
                width: HightWidthSizes.setValue_20,
                height: HightWidthSizes.setValue_20,
              ),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: AppImages.bottom_user_svg(
                width: HightWidthSizes.setValue_20,
                height: HightWidthSizes.setValue_20,
              ),
              activeIcon: AppImages.bottom_user_selected_svg(
                width: HightWidthSizes.setValue_20,
                height: HightWidthSizes.setValue_20,
              ),
              label: 'Profile',
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget buildView(BuildContext context) {
    final calendarController = Get.find<CalendarController>();
    final messagesController = Get.find<MessagesController>();
    final profileController = Get.find<ProfileController>();
    return Container(
      color: AppColor.white,
      child: SafeArea(
        child: Obx(() {
          final index = controller.currentIndex.value;
          return IndexedStack(
            index: index,
            children: [
              DashboardTab(controller: controller),
              CalendarTab(controller: calendarController),
              MessagesTab(controller: messagesController),
              ProfileTab(controller: profileController),
            ],
          );
        }),
      ),
    );
  }
}

class _NotificationIconWithBadge extends StatelessWidget {
  const _NotificationIconWithBadge({required this.controller});

  final dynamic controller; // Can be HomeController or CalendarController

  @override
  Widget build(BuildContext context) {
    // Get NotificationService instance - must be inside build to access Get.find
    if (!Get.isRegistered<NotificationService>()) {
      return AppImages.notification_svg(
        width: HightWidthSizes.setValue_40,
        height: HightWidthSizes.setValue_40,
        fit: BoxFit.fill,
      );
    }

    final notificationService = Get.find<NotificationService>();

    return GestureDetector(
      onTap: () async {
        // Refresh notification count before navigating
        await notificationService.fetchNotificationCount();
        // Navigate to notifications page
        final result = await Get.toNamed(Routes.notifications);
        // Refresh count when returning from notifications page
        if (result == true || result == null) {
          await notificationService.fetchNotificationCount();
        }
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AppImages.notification_svg(
            width: HightWidthSizes.setValue_40,
            height: HightWidthSizes.setValue_40,
            fit: BoxFit.fill,
          ),
          Obx(() {
            final count = notificationService.notificationCount.value;
            if (count > 0) {
              return Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: EdgeInsets.all(HightWidthSizes.setValue_2),
                  decoration: const BoxDecoration(
                    color: AppColor.white,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: HightWidthSizes.setValue_18,
                      minHeight: HightWidthSizes.setValue_18,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: count > 99
                          ? HightWidthSizes.setValue_4
                          : HightWidthSizes.setValue_6,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColor.color_2FC4B2,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikMedium,
                        fontWeight: FontWeight.w500,
                        fontSize: FontSizes.setFontValue_10,
                        color: AppColor.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
        ],
      ),
    );
  }
}
