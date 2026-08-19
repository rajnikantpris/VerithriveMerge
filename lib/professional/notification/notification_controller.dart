import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../api/api_response.dart';
import '../../api/user_api_service.dart';
import '../../common/base_controller.dart';
import '../../services/notification_service.dart';
import '../../services/analytics_service.dart';

class NotificationItem {
  const NotificationItem({
    required this.title,
    required this.description,
    required this.dateLabel,
  });

  final String title;
  final String description;
  final String dateLabel;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    String dateLabel = '';
    if (json['created_at'] != null || json['sent_at'] != null) {
      try {
        final dateStr = json['created_at'] ?? json['sent_at'];
        if (dateStr is String) {
          final date = DateTime.parse(dateStr);
          dateLabel = DateFormat('dd/MM/yyyy').format(date);
        }
      } catch (e) {
        dateLabel = '';
      }
    }

    return NotificationItem(
      title: json['title']?.toString() ?? '',
      description: json['message']?.toString() ?? json['description']?.toString() ?? '',
      dateLabel: dateLabel,
    );
  }
}

class NotificationController extends BaseController {
  NotificationController(this._userApiService);

  final UserApiService _userApiService;
  final notifications = <NotificationItem>[].obs;

  // Pagination state
  final currentPage = 1.obs;
  final totalPages = 1.obs;
  final hasNextPage = false.obs;
  final isLoadingMore = false.obs;
  
  final ScrollController scrollController = ScrollController();

  NotificationService? get _notificationService =>
      Get.isRegistered<NotificationService>()
          ? Get.find<NotificationService>()
          : null;

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalNotificationView',
      screenClass: 'NotificationView',
      pageCategory: 'notification',
      elementLocation: 'view',
    );
    _notificationService?.fetchNotificationCount();
    
    // Add scroll listener for pagination
    scrollController.addListener(_scrollListener);
    
    fetchNotifications();
  }

  @override
  void onClose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    // Load more when user scrolls to bottom (with 200px threshold)
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 200) {
      loadMoreNotifications();
    }
  }

  /// Fetch notifications from API
  Future<void> fetchNotifications({bool showLoader = true, bool isRefresh = true}) async {
    if (isRefresh) {
      currentPage.value = 1;
    }

    await callDataService(
      _userApiService.getNotificationsList(
        body: {
          'page': currentPage.value,
          'per_page': 20,
        },
      ),
      showLoader: showLoader,
      onSuccess: (ApiResponse<dynamic> response) {
        if (response.success && response.data != null) {
          _parseApiResponse(response.data, isRefresh: isRefresh);
        } else if (isRefresh) {
          notifications.clear();
        }
      },
      onError: (error, stack) {
        if (isRefresh) {
          notifications.clear();
        }
      },
    );
  }

  /// Load more notifications (next page)
  Future<void> loadMoreNotifications() async {
    if (isLoadingMore.value || !hasNextPage.value) return;

    isLoadingMore.value = true;
    currentPage.value++;

    final response = await _userApiService.getNotificationsList(
      body: {
        'page': currentPage.value,
        'per_page': 20,
      },
    );

    if (response.success && response.data != null) {
      _parseApiResponse(response.data, isRefresh: false);
    } else {
      currentPage.value--;
    }
    
    isLoadingMore.value = false;
  }

  /// Parse API response and update notifications list
  void _parseApiResponse(dynamic data, {required bool isRefresh}) {
    try {
      List<dynamic>? notificationsList;
      Map<String, dynamic>? paginationData;

      if (data is Map<String, dynamic>) {
        // Handle case where data is the full response or the nested 'data' object
        final innerData = data.containsKey('data') && data['data'] is Map<String, dynamic> 
            ? data['data'] as Map<String, dynamic> 
            : data;

        if (innerData['notifications'] is List) {
          notificationsList = innerData['notifications'] as List;
        }
        if (innerData['pagination'] is Map<String, dynamic>) {
          paginationData = innerData['pagination'] as Map<String, dynamic>;
        }
      }

      // Update pagination state
      if (paginationData != null) {
        currentPage.value = paginationData['current_page'] ?? currentPage.value;
        totalPages.value = paginationData['total_pages'] ?? 1;
        hasNextPage.value = paginationData['has_next_page'] ?? false;
      } else {
        hasNextPage.value = false;
      }

      if (notificationsList != null && notificationsList.isNotEmpty) {
        final newItems = notificationsList
            .map((item) => item is Map<String, dynamic> ? NotificationItem.fromJson(item) : null)
            .whereType<NotificationItem>()
            .toList();

        if (isRefresh) {
          notifications.assignAll(newItems);
        } else {
          notifications.addAll(newItems);
        }
      } else if (isRefresh) {
        notifications.clear();
      }
    } catch (e) {
      if (isRefresh) notifications.clear();
    }
  }
}
