import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import '../../utils/AppText.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import '../home_main/HomeMainController.dart';
import 'NotificationController.dart';
import 'NotificationModel.dart';

class NotificationScreen extends StatelessWidget {
  final NotificationController controller = Get.put(NotificationController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(AppAssets.back),
          onPressed: () {
            // Refresh notification count when going back to home screen
            if (Get.isRegistered<HomeMainController>(tag: 'home')) {
              Get.find<HomeMainController>(tag: 'home').fetchNotificationCount();
            }
            Get.back();
          },
        ),
        title: Text(
          AppText.notifications,
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
            color: AppColors.black,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(
              color: AppColors.primaryColor,
            ),
          );
        }

        if (controller.notifications.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              controller.loadNotifications();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: _buildEmptyState(),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            controller.refreshData();
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (scrollInfo is ScrollEndNotification) {
                if (scrollInfo.metrics.pixels == scrollInfo.metrics.maxScrollExtent) {
                  // User has reached the bottom of the list
                  controller.loadMoreNotifications();
                }
              }
              return false;
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              itemCount: controller.notifications.length + (controller.hasMoreData.value ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the bottom
                if (index == controller.notifications.length) {
                  return _buildLoadMoreIndicator();
                }
                
                final notification = controller.notifications[index];
                return _buildNotificationItem(notification);
              },
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNotificationItem(NotificationModel notification) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      margin: EdgeInsets.symmetric(vertical: 10,horizontal: 10),
      decoration: BoxDecoration(
        color: notification.isRead
            ? AppColors.white
            : AppColors.colorF6FFFF,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
          borderRadius: BorderRadius.circular(10)
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Unread indicator
         /*       if (!notification.isRead)
            Container(
              width: 8,
              height: 8,
              margin: EdgeInsets.only(top: 6, right: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
            )
          else
            SizedBox(width: 20),*/

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: AppTextStyles.mediumTextStyle(
                          fontSize: 16,
                          color: AppColors.blueColor,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      notification.date,
                      style: AppTextStyles.regularTextStyle(
                        fontSize: 12,
                        color: AppColors.color7a7a7a,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  notification.description,
                  style: AppTextStyles.regularTextStyle(
                    fontSize: 14,
                    color: AppColors.blueColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    return Container(
      padding: EdgeInsets.all(16),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          SizedBox(height: 16),
          Text(
            'No Notifications',
            style: AppTextStyles.boldTextStyle(
              fontSize: 20,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'You\'re all caught up!',
            style: AppTextStyles.regularTextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}