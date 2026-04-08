import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import '../cart/DashedLinePainter.dart';
import 'TransactionSummaryController.dart';

class TransactionSummaryScreen extends GetView<TransactionSummaryController> {
  const TransactionSummaryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(AppAssets.back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'Transaction Summary',
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
            color: AppColors.black,
          ),
        ),
        centerTitle: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.errorMessage.isNotEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                controller.errorMessage,
                textAlign: TextAlign.center,
                style: AppTextStyles.regularTextStyle(
                  fontSize: 16,
                  color: AppColors.grey,
                ),
              ),
            ),
          );
        }

        if (controller.transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'No transactions found',
                  style: AppTextStyles.regularTextStyle(
                    fontSize: 16,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          controller: controller.scrollController,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          itemCount: controller.transactions.length + (controller.hasMoreData.value ? 1 : 0),
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            if (index == controller.transactions.length) {
              return Obx(() {
                if (controller.isLoadingMore.value) {
                  return const Center(child: CircularProgressIndicator());
                } else {
                  return const SizedBox.shrink();
                }
              });
            }
            final tx = controller.transactions[index];
            final isSuccess = tx.status.toLowerCase() == 'success';
            final isPending = tx.status.toLowerCase() == 'pending';
            
            Color statusColor = AppColors.grey;
            Color statusBgColor = AppColors.lightGrey.withOpacity(0.2);
            
            if (isSuccess) {
              statusColor = AppColors.greenText;
              statusBgColor = AppColors.availableColor;
            } else if (isPending) {
              statusColor = AppColors.orangeDotColor;
              statusBgColor = AppColors.colorFFB54D.withOpacity(0.2);
            } else if (tx.status.toLowerCase() == 'failed' || tx.status.toLowerCase() == 'error') {
              statusColor = AppColors.redDark;
              statusBgColor = AppColors.unavailableColor;
            }

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGrey),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          tx.title.isNotEmpty ? tx.title : 'Transaction #${index + 1}',
                          style: AppTextStyles.popinSemiboldTextStyle(
                            fontSize: 16,
                            color: AppColors.black,
                          ),
                        ),
                      ),
                      Text(
                        tx.formattedAmount,
                        style: AppTextStyles.popinSemiboldTextStyle(
                          fontSize: 18,
                          color: AppColors.color2D3648,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  CustomPaint(
                    size: const Size(double.infinity, 1),
                    painter: DashedLinePainter(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date & Time',
                            style: AppTextStyles.popinRegularTextStyle(
                              fontSize: 12,
                              color: AppColors.color9D9D9D,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tx.formattedDate,
                            style: AppTextStyles.regularTextStyle(
                              fontSize: 14,
                              color: AppColors.color2B2B2B,
                            ),
                          ),
                        ],
                      ),
                      if (tx.status.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBgColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            tx.status.capitalizeFirst ?? tx.status,
                            style: AppTextStyles.popinSemiboldTextStyle(
                              fontSize: 12,
                              color: statusColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}
