import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import 'notification_controller.dart';

class NotificationView extends BaseView<NotificationController> {
  const NotificationView({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 1),
      child: Container(
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
          backgroundColor: AppColor.white,
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: AppColor.white,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
          ),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColor.color000000),
            onPressed: Get.back,
          ),
          title: Text(
            'Notifications',
            style: TextStyle(
              fontFamily: AppFonts.rubikMedium,
              fontWeight: FontWeight.w500,
              fontSize: FontSizes.setFontValue_18,
              color: AppColor.color_2D3648,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildView(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: double.infinity,
          height: constraints.maxHeight,
          color: AppColor.color_F5F7F8,
          child: Obx(() {
            if (controller.notifications.isEmpty) {
              return RefreshIndicator(
                onRefresh: () =>
                    controller.fetchNotifications(showLoader: false),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(HightWidthSizes.setValue_16),
                        child: Text(
                          'No notifications yet',
                          style: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontWeight: FontWeight.w400,
                            fontSize: FontSizes.setFontValue_14,
                            color: AppColor.color_9D9D9D,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () => controller.fetchNotifications(showLoader: false),
              child: ListView.separated(
                padding: EdgeInsets.symmetric(
                  horizontal: HightWidthSizes.setValue_16,
                  vertical: HightWidthSizes.setValue_16,
                ),
                itemBuilder: (_, index) {
                  final item = controller.notifications[index];
                  return _NotificationCard(item: item);
                },
                separatorBuilder: (_, __) =>
                    SizedBox(height: HightWidthSizes.setValue_12),
                itemCount: controller.notifications.length,
              ),
            );
          }),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item});

  final NotificationItem item;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(HightWidthSizes.setValue_14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7FB),
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikBold,
                    fontWeight: FontWeight.w700,
                    fontSize: FontSizes.setFontValue_16,
                    color: AppColor.color_2D3648,
                  ),
                ),
              ),
              SizedBox(width: HightWidthSizes.setValue_10),
              Text(
                item.dateLabel,
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_12,
                  color: AppColor.color_9D9D9D,
                ),
              ),
            ],
          ),
          SizedBox(height: HightWidthSizes.setValue_10),
          Text(
            item.description,
            style: TextStyle(
              fontFamily: AppFonts.rubikRegular,
              fontWeight: FontWeight.w400,
              fontSize: FontSizes.setFontValue_14,
              color: AppColor.color_2D2D2D,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
