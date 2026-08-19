import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:get/get.dart';

import '../../theme/colors.dart';
import '../../theme/font_sizes.dart';
import '../../theme/fonts.dart';
import '../../widgets/custom_app_bar.dart';
import '../../services/analytics_service.dart';

class ProfessionalWebViewScreen extends StatefulWidget {
  final String url;

  const ProfessionalWebViewScreen({super.key, required this.url});

  @override
  State<ProfessionalWebViewScreen> createState() =>
      _ProfessionalWebViewScreenState();
}

class _ProfessionalWebViewScreenState extends State<ProfessionalWebViewScreen> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    AnalyticsService.instance.logScreenView(
      screenName: 'ProfessionalWebViewScreen',
      screenClass: 'ProfessionalWebViewScreen',
      pageCategory: 'legal',
      elementLocation: 'view',
    );
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        appBarTitleText: 'Privacy policy',
        titleColor: AppColor.color000000,
        titleFontSize: FontSizes.setFontValue_18,
        titlefontFamily: AppFonts.rubikMedium,
        isBackButtonEnabled: true,
        isCenterTitle: false,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
