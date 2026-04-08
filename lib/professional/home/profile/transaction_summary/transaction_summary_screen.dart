import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/common/base_view.dart';
import '../../../../theme/colors.dart';
import '../../../../theme/font_sizes.dart';
import '../../../../theme/fonts.dart';
import '../../../../theme/hight_width_sizes.dart';
import '../../../../theme/image_paths.dart';
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
            return Center(
              child: Text(
                'No transactions found',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontSize: FontSizes.setFontValue_16,
                  color: AppColor.color_9D9D9D,
                ),
              ),
            );
          }

          return ListView.separated(
            controller: controller.scrollController,
            padding: EdgeInsets.all(HightWidthSizes.setValue_16),
            itemCount: controller.transactions.length + (controller.hasMoreData.value ? 1 : 0),
            separatorBuilder: (_, __) =>
                Divider(
                  height: HightWidthSizes.setValue_1,
                  color: AppColor.color_ECECEC,
                ),
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

              return ListTile(
                title: Text(transaction.title),
                subtitle: Text(transaction.formattedDate),
                trailing: Text(
                    transaction.formattedAmount, style: TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          );
        }),
      ),
    );
  }
}
