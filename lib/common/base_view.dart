import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../theme/colors.dart';
import '../theme/hight_width_sizes.dart';
import 'base_controller.dart';

abstract class BaseView<T extends BaseController> extends GetView<T> {
  const BaseView({super.key});

  PreferredSizeWidget? appBar(BuildContext context) => null;
  Widget? bottomNavigationBar(BuildContext context) => null;

  Widget buildView(BuildContext context);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final state = controller.pageState.value;
      final isLoading =
          state == PageState.loading || state == PageState.loadingShimmer;

      if (state == PageState.error &&
          controller.errorMessage.value.isNotEmpty) {
        _showErrorSnackBar(context, controller.errorMessage.value);
        return Scaffold(
          backgroundColor: AppColor.white,
          appBar: appBar(context),
          bottomNavigationBar: bottomNavigationBar(context),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                controller.errorMessage.value,
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }

      return Stack(
        children: [
          Scaffold(
            backgroundColor: AppColor.white,
            appBar: appBar(context),
            bottomNavigationBar: bottomNavigationBar(context),
            body: buildView(context),
          ),
          if (isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    height: HightWidthSizes.setValue_80,
                    width: HightWidthSizes.setValue_80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(
                        HightWidthSizes.setValue_20,
                      ),
                    ),
                    child: Center(
                      child: SizedBox(
                        height: HightWidthSizes.setValue_50,
                        width: HightWidthSizes.setValue_50,
                        child: const CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    });
  }
}
