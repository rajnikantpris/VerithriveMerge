import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';

import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/analytics_service.dart';

class PaymentWebViewScreen extends StatefulWidget {
  final String url;

  const PaymentWebViewScreen({super.key, required this.url});

  @override
  State<PaymentWebViewScreen> createState() => _PaymentWebViewScreenState();
}

class _PaymentWebViewScreenState extends State<PaymentWebViewScreen> {
  late final WebViewController _controller;
  bool _hasClosed = false;

  String? _transactionIdFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      for (final key in const ['transaction_id', 'transactionId', 'session_id']) {
        final value = uri.queryParameters[key];
        if (value != null && value.isNotEmpty) return value;
      }
    } catch (_) {}
    return null;
  }

  void _handleUrl(String source, String url) {
    print('Payment [$source] url: $url');
    print('Payment [$source] query: ${Uri.tryParse(url)?.queryParameters}');

    if (_hasClosed) return;

    if (url.contains('payment/success')) {
      final transactionId = _transactionIdFromUrl(url);
      print('Payment [$source] transaction_id: $transactionId');
      if (transactionId == null || transactionId.isEmpty) {
        return;
      }
      _hasClosed = true;
      Get.back(result: {
        'status': 'success',
        'transactionId': transactionId,
      });
      return;
    }

    if (url.contains('payment/failed') || url.contains('payment/cancel')) {
      _hasClosed = true;
      Get.back(result: {'status': 'failed'});
    }
  }

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalPaymentWebViewScreen',
      screenClass: 'PaymentWebViewScreen',
      pageCategory: 'payment',
      elementLocation: 'view',
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            _handleUrl('page_started', url);
          },
          onPageFinished: (String url) {
            _handleUrl('page_finished', url);
          },
          onUrlChange: (UrlChange change) {
            if (change.url != null) {
              _handleUrl('url_change', change.url!);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            _handleUrl('navigation', request.url);
            if (request.url.contains('payment/cancel') ||
                request.url.contains('payment/failed')) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarTitleText: 'Payment',
        titleColor: AppColor.color000000,
        titleFontSize: FontSizes.setFontValue_18,
        titlefontFamily: AppFonts.rubikMedium,
        isBackButtonEnabled: true,
        isCenterTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColor.color000000),
          onPressed: () => Get.back(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
