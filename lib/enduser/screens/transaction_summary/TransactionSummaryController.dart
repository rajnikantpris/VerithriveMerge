import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/base/base_controller.dart';
import '../../data/repository/project_repository.dart';
import '../../utils/api_services.dart';
import '../../utils/auth_service.dart';
import 'package:verithrive_dev/services/analytics_service.dart';

class TransactionHistoryItem {
  final String id;
  final String bookingId;
  final String title;
  final DateTime date;
  final double amount;
  final String currencySymbol;
  final String status;

  const TransactionHistoryItem({
    required this.id,
    required this.bookingId,
    required this.title,
    required this.date,
    required this.amount,
    required this.currencySymbol,
    required this.status,
  });

  factory TransactionHistoryItem.fromJson(Map<String, dynamic> json) {
    final id = (json['transaction_id'] ?? json['_id'] ?? json['id'] ?? '').toString();
    final bookingId = (json['booking_id'] ?? json['bookingId'] ?? '').toString();
    
    // Title from service format name or professional full name
    String title = 'Transaction';
    if (json['service_format'] != null && json['service_format']['name'] != null) {
      title = json['service_format']['name'].toString();
    } else if (json['professional_user'] != null && json['professional_user']['full_name'] != null) {
      title = json['professional_user']['full_name'].toString();
    } else {
      title = (json['title'] ??
          json['description'] ??
          json['service_name'] ??
          json['serviceFormatName'] ??
          json['service_format_name'] ??
          json['booking_id'] ??
          json['bookingId'] ??
          json['payment_for'] ??
          json['type'] ??
          'Transaction')
          .toString();
    }

    DateTime date = DateTime.now();
    final rawDate = json['transaction_date'] ??
        json['date'] ??
        json['created_at'] ??
        json['createdAt'] ??
        json['paid_at'] ??
        json['paidAt'];
    if (rawDate != null) {
      try {
        if (rawDate is String) {
          date = (DateTime.tryParse(rawDate) ?? date).toLocal();
        } else if (rawDate is int) {
          date = DateTime.fromMillisecondsSinceEpoch(rawDate).toLocal();
        } else if (rawDate is num) {
          date = DateTime.fromMillisecondsSinceEpoch(rawDate.toInt()).toLocal();
        }
      } catch (_) {}
    }

    double amount = 0.0;
    final rawAmount = json['booking_amount'] ??
        json['amount'] ??
        json['transaction_amount'] ??
        json['price'] ??
        json['total'] ??
        json['total_amount'] ??
        json['paid_amount'];
    if (rawAmount != null) {
      if (rawAmount is num) {
        amount = rawAmount.toDouble();
      } else if (rawAmount is String) {
        amount = double.tryParse(rawAmount) ?? 0.0;
      }
    }

    final currencySymbol = (json['currency_symbol'] ??
            json['currencySymbol'] ??
            (json['currency'] == 'GBP' ? '£' : null) ??
            '£')
        .toString();

    final status = (json['payment_status'] ??
            json['status'] ??
            json['paymentStatus'] ??
            json['state'] ??
            '')
        .toString();

    return TransactionHistoryItem(
      id: id,
      bookingId: bookingId,
      title: title,
      date: date,
      amount: amount,
      currencySymbol: currencySymbol,
      status: status,
    );
  }

  String get formattedDate => DateFormat('dd/MM/yyyy HH:mm').format(date);

  String get formattedAmount => '$currencySymbol${amount.toStringAsFixed(2)}';
}

class TransactionSummaryController extends BaseController {
  final ProjectRepository _repository =
      Get.find(tag: (ProjectRepository).toString());

  var isLoading = false.obs;
  var isLoadingMore = false.obs;
  var currentPage = 1;
  var hasMoreData = true.obs;
  var transactions = <TransactionHistoryItem>[].obs;

  late ScrollController scrollController;

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'TransactionSummaryScreen',
      screenClass: 'TransactionSummaryScreen',
      pageCategory: 'profile',
      elementLocation: 'view',
    );
    scrollController = ScrollController();
    scrollController.addListener(_scrollListener);
    fetchTransactions();
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }

  void _scrollListener() {
    if (scrollController.position.pixels == scrollController.position.maxScrollExtent) {
      fetchTransactions(isLoadMore: true);
    }
  }

  Future<void> fetchTransactions({bool isLoadMore = false}) async {
    if (isLoadMore && !hasMoreData.value) return;
    if (isLoadMore && isLoadingMore.value) return;
    if (!isLoadMore && isLoading.value) return;

    final canAccess = await AuthService.requireAuth();
    if (!canAccess) return;

    if (isLoadMore) {
      isLoadingMore(true);
    } else {
      isLoading(true);
      currentPage = 1;
      transactions.clear();
      hasMoreData(true);
    }
    showErrorMessage('');

    Map<String, dynamic> toJson() {
      final Map<String, dynamic> data = <String, dynamic>{
        "page": currentPage,
        "limit": 10,
        "start_date": "",
        "end_date": ""
      };
      return data;
    }

    var service = _repository.sendPostApiRequest(toJson, transactions_history, true);
    await callDataService(
      service,
      onSuccess: (response) => _handleTransactionHistorySuccess(response, isLoadMore),
      onError: _handleTransactionHistoryError,
      isShowLoading: !isLoadMore,
      onComplete: () {
        if (isLoadMore) isLoadingMore(false);
        else isLoading(false);
      },
    );
  }

  void _handleTransactionHistorySuccess(dynamic baseResponse, bool isLoadMore) {
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

      final success = responseData['success'] == true || responseData['status'] == true;
      if (!success) {
        final message = responseData['message']?.toString() ?? 'Failed to load transactions';
        if (!isLoadMore) transactions.value = [];
        showErrorMessage(message);
        if (!isLoadMore) isLoading.value = false;
        return;
      }

      dynamic data = responseData['data'];
      List<dynamic>? list;
      Map<String, dynamic>? pagination;

      if (data is List) {
        list = data;
      } else if (data is Map<String, dynamic>) {
        final candidate = data['transactions'] ??
            data['transaction_history'] ??
            data['transactionHistory'] ??
            data['items'] ??
            data['list'];
        if (candidate is List) list = candidate;
        pagination = data['pagination'] as Map<String, dynamic>?;
      }

      list ??= responseData['transactions'] is List ? (responseData['transactions'] as List) : null;

      final parsed = <TransactionHistoryItem>[];
      if (list != null) {
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            parsed.add(TransactionHistoryItem.fromJson(item));
          }
        }
      }

      if (isLoadMore) {
        transactions.addAll(parsed);
      } else {
        transactions.value = parsed;
      }

      if (pagination != null) {
        final totalPages = pagination['total_pages'] as int? ?? 1;
        if (currentPage < totalPages) {
          currentPage++;
          hasMoreData(true);
        } else {
          hasMoreData(false);
        }
      } else {
        // If no pagination info, assume no more data after first fetch
        hasMoreData(false);
      }

      if (!isLoadMore) isLoading.value = false;
    } catch (e) {
      if (!isLoadMore) transactions.value = [];
      showErrorMessage('Failed to parse transactions');
      if (!isLoadMore) isLoading.value = false;
    }
  }

  void _handleTransactionHistoryError(Exception exception) {
    transactions.value = [];
    showErrorMessage(exception.toString());
    isLoading.value = false;
  }
}
