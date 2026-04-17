import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/common/base_view.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/hight_width_sizes.dart';
import 'transaction_summary_controller.dart';

class TransactionSummaryScreen extends BaseView<TransactionSummaryController> {
  const TransactionSummaryScreen({super.key});

  @override
  PreferredSizeWidget? appBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight + 1),
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.white,
          boxShadow: [
            BoxShadow(
              color: Color(0x1A000000), // #0000001A
              blurRadius: HightWidthSizes.setValue_10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: AppBar(
          backgroundColor: AppColor.white,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: AppColor.color_2D3648,
            ),
            onPressed: () => Get.back(),
          ),
          centerTitle: true,
          title: Text(
            'Transaction Summary',
            style: TextStyle(
              fontFamily: AppFonts.rubikMedium,
              fontWeight: FontWeight.w500,
              fontSize: FontSizes.setFontValue_18,
              color: AppColor.color_2D3648,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildView(BuildContext context) {
    return Container(
      color: AppColor.white,
      child: SafeArea(
        child: Obx(() {
          if (controller.isLoadingTransactions.value) {
            return const Center(child: CircularProgressIndicator());
          }

          if (controller.transactions.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => controller.fetchTransactions(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: Text(
                            'No transactions found',
                            style: TextStyle(
                              fontFamily: AppFonts.rubikRegular,
                              fontSize: FontSizes.setFontValue_16,
                              color: AppColor.color_9D9D9D,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => controller.fetchTransactions(),
            child: ListView.separated(
              controller: controller.scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(HightWidthSizes.setValue_16),
              itemCount: controller.transactions.length +
                  (controller.hasMoreData.value ? 1 : 0),
              separatorBuilder: (_, __) =>
                  SizedBox(height: HightWidthSizes.setValue_12),
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
                final transaction = controller.transactions[index];

                final isSuccess = transaction.status.toLowerCase() == 'success' ||
                    transaction.status.toLowerCase() == 'paid';
                final isPending = transaction.status.toLowerCase() == 'pending';

                Color statusColor = AppColor.color_9D9D9D;
                Color statusBgColor = AppColor.color_ECECEC.withOpacity(0.2);

                if (isSuccess) {
                  statusColor = AppColor.color_2FC4B2;
                  statusBgColor = AppColor.color_2FC4B2.withOpacity(0.1);
                } else if (isPending) {
                  statusColor =
                      const Color(0xFFF59300); // Orange color for pending
                  statusBgColor = const Color(0xFFF59300).withOpacity(0.1);
                } else if (transaction.status.toLowerCase() == 'failed' ||
                    transaction.status.toLowerCase() == 'error') {
                  statusColor = AppColor.color_E64646;
                  statusBgColor = AppColor.color_E64646.withOpacity(0.1);
                }

                return Container(
                  padding: EdgeInsets.all(HightWidthSizes.setValue_16),
                  decoration: BoxDecoration(
                    color: AppColor.white,
                    borderRadius:
                        BorderRadius.circular(HightWidthSizes.setValue_12),
                    border: Border.all(color: AppColor.color_ECECEC),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.color000000.withOpacity(0.05),
                        blurRadius: HightWidthSizes.setValue_10,
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  transaction.title,
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubikMedium,
                                    fontWeight: FontWeight.w600,
                                    fontSize: FontSizes.setFontValue_16,
                                    color: AppColor.color_2D3648,
                                  ),
                                ),
                                if (transaction
                                    .transactionReference.isNotEmpty) ...[
                                  SizedBox(height: HightWidthSizes.setValue_4),
                                  Text(
                                    'Ref: ${transaction.transactionReference}',
                                    style: TextStyle(
                                      fontFamily: AppFonts.rubikRegular,
                                      fontWeight: FontWeight.w400,
                                      fontSize: FontSizes.setFontValue_12,
                                      color: AppColor.color_9D9D9D,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            transaction.formattedAmount,
                            style: TextStyle(
                              fontFamily: AppFonts.rubikMedium,
                              fontWeight: FontWeight.w600,
                              fontSize: FontSizes.setFontValue_16,
                              color: AppColor.color_2D3648,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: HightWidthSizes.setValue_12),
                      CustomPaint(
                        size: const Size(double.infinity, 1),
                        painter: DashedLinePainter(),
                      ),
                      SizedBox(height: HightWidthSizes.setValue_12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date & Time',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubikRegular,
                                  fontWeight: FontWeight.w400,
                                  fontSize: FontSizes.setFontValue_12,
                                  color: AppColor.color_9D9D9D,
                                ),
                              ),
                              SizedBox(height: HightWidthSizes.setValue_4),
                              Text(
                                transaction.formattedDate,
                                style: TextStyle(
                                  fontFamily: AppFonts.rubikRegular,
                                  fontWeight: FontWeight.w400,
                                  fontSize: FontSizes.setFontValue_14,
                                  color: AppColor.color_2D2D2D,
                                ),
                              ),
                            ],
                          ),
                          if (transaction.status.isNotEmpty)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: HightWidthSizes.setValue_10,
                                vertical: HightWidthSizes.setValue_4,
                              ),
                              decoration: BoxDecoration(
                                color: statusBgColor,
                                borderRadius: BorderRadius.circular(
                                    HightWidthSizes.setValue_20),
                              ),
                              child: Text(
                                transaction.status.capitalizeFirst ??
                                    transaction.status,
                                style: TextStyle(
                                  fontFamily: AppFonts.rubikMedium,
                                  fontWeight: FontWeight.w600,
                                  fontSize: FontSizes.setFontValue_12,
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
            ),
          );
        }),
      ),
    );
  }
}

class DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColor.color_ECECEC
      ..strokeWidth = 1;

    const dashWidth = 5;
    const dashSpace = 3;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
