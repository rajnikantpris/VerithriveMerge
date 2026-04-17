import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../utils/api_services.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import 'NotificationModel.dart';
import 'package:verithrive_dev/services/analytics_service.dart';

class NotificationController extends BaseController {
  final ProjectRepository _repository = Get.find(tag: (ProjectRepository).toString());
  
  var notifications = <NotificationModel>[].obs;
  var isLoading = false.obs;
  var currentPage = 1.obs;
  var totalPages = 1.obs;
  var hasMoreData = true.obs;
  
  static const int limit = 20;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  // Refresh data method called by MainScreen
  void refreshData() {
    resetPagination();
    loadNotifications();
  }

  // Reset pagination to first page
  void resetPagination() {
    currentPage.value = 1;
    totalPages.value = 1;
    hasMoreData.value = true;
    notifications.clear();
  }

  // Load first page of notifications
  void loadNotifications() {
    callNotificationsListAPI(isRefresh: true);
  }

  // Load more notifications (next page)
  void loadMoreNotifications() {
    if (!isLoading.value && hasMoreData.value) {
      currentPage.value++;
      callNotificationsListAPI(isRefresh: false);
    }
  }

  void callNotificationsListAPI({bool isRefresh = true}) {
    if (!isRefresh) {
      // For load more, don't show full loading indicator
      isLoading.value = false;
    } else {
      // For refresh, show loading
      isLoading.value = true;
    }
    
    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{};
      data['page'] = currentPage.value;
      data['limit'] = limit;
      //data['status'] = 'pending';
      
      print('========================================');
      print('Notifications List API Request (POST):');
      print('Page: ${data['page']}');
      print('Limit: ${data['limit']}');
      print('Is Refresh: $isRefresh');
      print('========================================');
      
      return data;
    }
    
    // Using POST request
    var service = _repository.sendPostApiRequest(toJson, notifications_list, true);
    callDataService(
      service,
      onSuccess: (response) => _handleNotificationsListSuccess(response, isRefresh),
      onError: _handleNotificationsListError,
      isShowLoading: isRefresh, // Only show loading for refresh, not for load more
    );
  }

  Future<void> _handleNotificationsListSuccess(dynamic baseResponse, bool isRefresh) async {
    try {
      Map<String, dynamic> responseData;
      if (baseResponse != null && baseResponse.data != null) {
        responseData = baseResponse.data is Map<String, dynamic>
            ? baseResponse.data
            : baseResponse.data as Map<String, dynamic>;
      } else if (baseResponse is Map<String, dynamic>) {
        responseData = baseResponse;
      } else {
        throw Exception('Invalid response format');
      }

      bool success = responseData['success'] ?? false;
      String message = responseData['message'] ?? '';
      
      if (success == true && responseData['data'] != null) {
        Map<String, dynamic> dataMap = responseData['data'] as Map<String, dynamic>;

        // Analytics: Log notifications loaded
        
        
        List<dynamic>? notificationsList = dataMap['notifications'] as List<dynamic>?;
        
        // Parse pagination information
        if (dataMap['pagination'] != null) {
          Map<String, dynamic> pagination = dataMap['pagination'] as Map<String, dynamic>;
          currentPage.value = pagination['current_page'] ?? 1;
          totalPages.value = pagination['total_pages'] ?? 1;
          hasMoreData.value = currentPage.value < totalPages.value;
        } else {
          // If no pagination info, assume single page
          hasMoreData.value = false;
        }
        
        if (notificationsList != null && notificationsList.isNotEmpty) {
          List<NotificationModel> newNotifications = notificationsList.map((json) => _parseNotification(json)).toList();
          
          if (isRefresh) {
            // Replace all notifications for refresh
            notifications.value = newNotifications;
          } else {
            // Append new notifications for load more
            notifications.addAll(newNotifications);
          }
        } else {
          if (isRefresh) {
            notifications.value = [];
          }
          hasMoreData.value = false;
        }
        
        print('========================================');
        print('Notifications List API Success:');
        print('Is Refresh: $isRefresh');
        print('New Items: ${notificationsList?.length ?? 0}');
        print('Total Notifications: ${notifications.length}');
        print('Current Page: ${currentPage.value}');
        print('Total Pages: ${totalPages.value}');
        print('Has More Data: ${hasMoreData.value}');
        if (dataMap['pagination'] != null) {
          print('Pagination: ${dataMap['pagination']}');
        }
        print('========================================');
      } else {
        print('Notifications List API Error: $message');
        if (isRefresh) {
          notifications.value = [];
        }
        hasMoreData.value = false;
      }
      isLoading.value = false;
    } catch (e) {
      print('Error parsing notifications list response: $e');
      if (isRefresh) {
        notifications.value = [];
      }
      hasMoreData.value = false;
      isLoading.value = false;
    }
  }

  void _handleNotificationsListError(Exception exception) {
    print('Notifications List API Error: $exception');
    notifications.value = [];
    hasMoreData.value = false;
    isLoading.value = false;
  }

  NotificationModel _parseNotification(Map<String, dynamic> json) {
    // Parse created_at date and format it
    String formattedDate = '';
    try {
      String? createdAt = json['created_at']?.toString();
      if (createdAt != null && createdAt.isNotEmpty) {
        // Parse ISO 8601 date format: "2026-01-02T09:55:48.224Z"
        DateTime dateTime = DateTime.parse(createdAt);
        // Format as DD/MM/YYYY
        formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
      }
    } catch (e) {
      print('Error parsing notification date: $e');
      formattedDate = '';
    }
    
    // Determine if notification is read based on delivery_status
    // Consider notifications as read if they are sent successfully
    bool isRead = json['delivery_status']?.toString() == 'sent' || 
                  json['is_sent'] == true;
    
    return NotificationModel(
      id: json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['message']?.toString() ?? '',
      date: formattedDate,
      isRead: isRead,
      isSent: json['is_sent'] as bool? ?? false,
      deliveryStatus: json['delivery_status']?.toString() ?? 'pending',
    );
  }

  void markAsRead(String id) {
    int index = notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      final notification = notifications[index];
      notifications[index] = NotificationModel(
        id: notification.id,
        title: notification.title,
        description: notification.description,
        date: notification.date,
        isRead: true,
        isSent: notification.isSent,
        deliveryStatus: notification.deliveryStatus,
      );
      notifications.refresh();
    }
  }

  void deleteNotification(String id) {
    notifications.removeWhere((n) => n.id == id);
    Get.snackbar(
      'Deleted',
      'Notification removed',
      snackPosition: SnackPosition.BOTTOM,
      duration: Duration(seconds: 2),
      backgroundColor: Colors.grey.shade300,
    );
  }

  void clearAll() {
    Get.dialog(
      AlertDialog(
        title: Text(
          'Clear All',
          style: AppTextStyles.boldTextStyle(fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to clear all notifications?',
          style: AppTextStyles.regularTextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text(
              'Cancel',
              style: AppTextStyles.mediumTextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              notifications.clear();
              Get.back();
              Get.snackbar(
                'Cleared',
                'All notifications removed',
                snackPosition: SnackPosition.BOTTOM,
                duration: Duration(seconds: 2),
              );
            },
            child: Text(
              'Clear All',
              style: AppTextStyles.mediumTextStyle(
                fontSize: 14,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}