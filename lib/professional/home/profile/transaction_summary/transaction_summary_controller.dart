import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../api/user_api_service.dart';
import '../../../../common/base_controller.dart';
import '../../../../services/analytics_service.dart';

class TransactionHistoryItem {
  final String id;
  final String title;
  final DateTime date;
  final double amount;
  final String currencySymbol;
  final String status;
  final String transactionReference;

  const TransactionHistoryItem({
    required this.id,
    required this.title,
    required this.date,
    required this.amount,
    required this.currencySymbol,
    required this.status,
    required this.transactionReference,
  });

  factory TransactionHistoryItem.fromJson(Map<String, dynamic> json) {
    final id = (json['_id'] ?? json['id'] ?? json['transaction_id'] ?? '').toString();
    final title = (json['plan_name'] ??
        json['title'] ??
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

    DateTime date = DateTime.now();
    final rawDate = json['created_at'] ??
        json['date'] ??
        json['transaction_date'] ??
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
    final rawAmount = json['amount'] ??
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

    final status = (json['status'] ??
        json['payment_status'] ??
        json['paymentStatus'] ??
        json['state'] ??
        '')
        .toString();

    final transactionReference = (json['transaction_reference'] ??
        json['transactionReference'] ??
        json['reference'] ??
        '')
        .toString();

    return TransactionHistoryItem(
      id: id,
      title: title,
      date: date,
      amount: amount,
      currencySymbol: currencySymbol,
      status: status,
      transactionReference: transactionReference,
    );
  }

  String get formattedDate => DateFormat('dd/MM/yyyy HH:mm').format(date);

  String get formattedAmount => '$currencySymbol${amount.toStringAsFixed(2)}';
}

class TransactionSummaryController extends BaseController {
  final UserApiService _userApiService;

  TransactionSummaryController(this._userApiService);

  var isLoadingTransactions = false.obs;
  var isLoadingMore = false.obs;
  var currentPage = 1;
  var hasMoreData = true.obs;
  var transactions = <TransactionHistoryItem>[].obs;

  late ScrollController scrollController;

  @override
  void onInit() {
    super.onInit();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalTransactionSummaryScreen',
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
    if (!isLoadMore && isLoadingTransactions.value) return;

    if (isLoadMore) {
      isLoadingMore(true);
    } else {
      isLoadingTransactions(true);
      currentPage = 1;
      transactions.clear();
      hasMoreData(true);
    }

    await callDataService(
      _userApiService.getTransactionHistory(
        page: currentPage,
        limit: 10,
      ),
      onStart: () {},
      onSuccess: (response) {
        if (response.success && response.data != null) {
          List<dynamic> items = [];
          Map<String, dynamic>? pagination;

          if (response.data is List) {
            items = response.data;
          } else if (response.data is Map) {
            final candidate = response.data['transactions'] ??
                response.data['transaction_history'] ??
                response.data['transactionHistory'] ??
                response.data['items'] ??
                response.data['list'];
            if (candidate is List) items = candidate;
            pagination = response.data['pagination'] as Map<String, dynamic>?;
          }
          
          final parsed = items.map((e) => TransactionHistoryItem.fromJson(e as Map<String, dynamic>)).toList();

          if (isLoadMore) {
            transactions.addAll(parsed);
          } else {
            transactions.assignAll(parsed);
          }

          if (pagination != null) {
            final totalPages = pagination['total_pages'] as int? ?? 1;
            final currPage = pagination['current_page'] as int? ?? currentPage;
            
            if (currPage < totalPages) {
              currentPage = currPage + 1;
              hasMoreData(true);
            } else {
              hasMoreData(false);
            }
          } else {
            // Fallback if no pagination object
            if (parsed.length < 10) {
              hasMoreData(false);
            } else {
              currentPage++;
              hasMoreData(true);
            }
          }
        }
      },
      onComplete: () {
        if (isLoadMore) isLoadingMore(false);
        else isLoadingTransactions(false);
      },
    );
  }
}
