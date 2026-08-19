import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';

import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/analytics_service.dart';

class StripAccountWebViewScreen extends StatefulWidget {
  final String url;

  const StripAccountWebViewScreen({super.key, required this.url});

  @override
  State<StripAccountWebViewScreen> createState() =>
      _StripAccountWebViewScreenState();
}

class _StripAccountWebViewScreenState extends State<StripAccountWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'StripeAccountCreateWebView',
      screenClass: 'StripAccountWebViewScreen',
      pageCategory: 'payment',
      elementLocation: 'view',
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            debugPrint('Page finished loading: $url');
            // Detect success or failed URLs and close WebView
            if (url.contains('stripe/complete')) {
              Get.back(result: 'success');
            } else if (url.contains('stripe/reconnect')) {
              Get.back(result: 'failed');
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (request.url.contains('stripe/complete')) {
              Get.back(result: 'success');
              return NavigationDecision.prevent;
            }
            if (request.url.contains('stripe/reconnect')) {
              Get.back(result: 'failed');
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
        appBarTitleText: 'Create Stripe Account',
        titleColor: AppColor.color000000,
        titleFontSize: FontSizes.setFontValue_18,
        titlefontFamily: AppFonts.rubikMedium,
        isBackButtonEnabled: true,
        isCenterTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColor.color000000),
          onPressed: () =>  Get.back(),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
