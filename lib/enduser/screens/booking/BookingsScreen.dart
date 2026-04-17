import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import 'package:verithrive_dev/enduser/utils/app_colors.dart';
import 'package:verithrive_dev/enduser/utils/app_text_styles.dart';
import '../../core/widget/animated_loader.dart';
import '../cart/DashedLinePainter.dart';
import '../../models/Booking.dart';
import '../../utils/AppText.dart';
import 'BookingsController.dart';

class BookingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Get controller - it should be initialized in MainScreen, but handle if not
    final controller = Get.find<BookingsController>(tag: 'bookings');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 4, // 🔴 Add shadow depth (try 2-8)
        shadowColor: Colors.black.withOpacity(
          0.1,
        ), // Optional: customize shadow color
        scrolledUnderElevation: 4,
        centerTitle: true,
        title: Text(
          AppText.bookings,
          style: AppTextStyles.popinSemiboldTextStyle(
            fontSize: 20,
            color: AppColors.black,
          ),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: AnimatedLoader(
              assetPath: AppAssets.loader1,
              width: 80,
              height: 80,
              color: AppColors.primaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Show cancellation success screen
        if (controller.showCancellationSuccess.value) {
          return RefreshIndicator(
            onRefresh: () async {
              controller.loadBookings();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: _buildCancellationSuccessView(),
              ),
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            controller.loadBookings();
          },
          child: SingleChildScrollView(
            controller: controller.scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              // My bookings section
              Text(
                'My bookings',
                style: AppTextStyles.mediumTextStyle(
                  fontSize: 20,
                  color: AppColors.color252525,
                ),
              ),
              SizedBox(height: 12),
              Obx(
                () => controller.myBookings.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: controller.myBookings
                            .map(
                              (booking) => _buildBookingCard(
                                context,
                                booking,
                                controller,
                                isUpcoming: true,
                              ),
                            )
                            .toList(),
                      ),
              ),
              SizedBox(height: 24),
              // Past bookings section
              Text(
                'Past bookings',
                style: AppTextStyles.mediumTextStyle(
                  fontSize: 20,
                  color: AppColors.color252525,
                ),
              ),
              SizedBox(height: 12),
              Obx(
                () => controller.pastBookings.isEmpty
                    ? SizedBox.shrink()
                    : Column(
                        children: controller.pastBookings
                            .map(
                              (booking) => _buildBookingCard(
                                context,
                                booking,
                                controller,
                                isUpcoming: false,
                                isPast: true,
                              ),
                            )
                            .toList(),
                      ),
              ),
              SizedBox(height: 24),
            ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildCancellationSuccessView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(AppAssets.right_circle),
          SizedBox(height: 24),
          Text(
            'Booking cancelled',
            style: AppTextStyles.popinSemiboldTextStyle(
              fontSize: 18,
              color: AppColors.blueColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppColors.lightGreyF5F7F8,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          'No booking yet!',
          style: AppTextStyles.regularTextStyle(
            fontSize: 16,
            color: AppColors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildBookingCard(
    BuildContext context,
    Booking booking,
    BookingsController controller, {
    required bool isUpcoming,
    bool isPast = false,
  }) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final timeFormat = DateFormat('h:mm a');
    final endTime = booking.dateTime.add(Duration(hours: 1));
    final Color primaryTextColor = isUpcoming
        ? isPast
              ? Color(0xFF414141).withAlpha(400)
              : AppColors.black
        : isPast
        ? Color(0xFF898989).withAlpha(400)
        : AppColors.greyText;

    final Color textColor = isUpcoming
        ? isPast
        ? Color(0xFF414141).withAlpha(400)
        : AppColors.color2B2B2B
        : isPast
        ? Color(0xFF898989).withAlpha(400)
        : AppColors.color2B2B2B;


    final Color priceColor = isUpcoming
        ? isPast
              ? Color(0xFF414141).withAlpha(400)
              : AppColors.blueColor
        : isPast
        ? Color(0xFF898989).withAlpha(400)
        : AppColors.greyText;

    Color getStatusColor(String? status) {
      if (status == null) return textColor;
      switch (status.toLowerCase()) {
        case 'completed':
          return AppColors.greenText;
        case 'cancelled':
        case 'failed':
          return AppColors.redDark;
        case 'confirmed':
        return AppColors.primaryColor;
        case 'in_progress':
          return AppColors.wellnessTextColor;
        default:
          return textColor;
      }
    }

    Color getPaymentStatusColor(String? status) {
      if (status == null) return textColor;
      switch (status.toLowerCase()) {
        case 'success':
          return AppColors.greenText;
        case 'partially_refunded':
          return AppColors.orangeDotColor;
        case 'failed':
        case 'cancelled':
        case 'refunded':
          return AppColors.redDark;
        default:
          return textColor;
      }
    }

    return Obx(() {
      final isHighlighted = controller.highlightedBookingId.value == booking.id;
      
      return AnimatedContainer(
        key: controller.getOrCreateKey(booking.id),
        duration: const Duration(milliseconds: 500),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isHighlighted 
              ? Border.all(color: AppColors.primaryColor, width: 2)
              : Border.all(color: Colors.transparent, width: 2),
          boxShadow: isHighlighted ? [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            )
          ] : null,
        ),
        child: Card(
          margin: EdgeInsets.zero,
          elevation: isUpcoming ? 4 : 4,
          shadowColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          color: Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Consultation type and price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      booking.consultationType,
                      style: AppTextStyles.regularTextStyle(
                        fontSize: 16,
                        color: primaryTextColor,
                      ),
                    ),
                    Text(
                      '£${booking.price.toStringAsFixed(0)}',
                      style: AppTextStyles.popinSemiboldTextStyle(
                        fontSize: 20,
                        color: priceColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                CustomPaint(
                  size: Size(double.infinity, 1),
                  painter: DashedLinePainter(),
                ),
                SizedBox(height: 12),
                // Date & Time
                Text(
                  AppText.dateTime,
                  style: AppTextStyles.popinRegularTextStyle(
                    fontSize: 14,
                    color: isPast
                        ? Color(0xFF9E9E9E).withAlpha(400)
                        : AppColors.color9D9D9D,
                  ),
                ),
                SizedBox(height: 4),
            /*    Text(
                  '${dateFormat.format(booking.dateTime)} ${timeFormat.format(booking.dateTime)}-${timeFormat.format(endTime)}',
                  style: AppTextStyles.regularTextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),*/

                Text(
                  booking.dateTimeRange.toString(),
                  style: AppTextStyles.regularTextStyle(
                    fontSize: 14,
                    color: textColor,
                  ),
                ),
                SizedBox(height: 12),
                CustomPaint(
                  size: Size(double.infinity, 1),
                  painter: DashedLinePainter(),
                ),
                SizedBox(height: 12),
                // Booking ID & Transaction ID
                if (booking.uniqueBookingId != null) ...[
                  Row(
                    children: [
                      if (booking.uniqueBookingId != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Booking Id',
                                style: AppTextStyles.popinRegularTextStyle(
                                  fontSize: 14,
                                  color: isPast
                                      ? Color(0xFF9E9E9E).withAlpha(400)
                                      : AppColors.color9D9D9D,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                booking.uniqueBookingId!,
                                style: AppTextStyles.regularTextStyle(
                                  fontSize: 14,
                                  color: isPast
                                      ? Color(0xFF414141).withAlpha(400)
                                      : AppColors.color2B2B2B,
                                ),
                              ),
                            ],
                          ),
                        ),

                    ],
                  ),
                  SizedBox(height: 12),

                ],
                CustomPaint(
                  size: Size(double.infinity, 1),
                  painter: DashedLinePainter(),
                ),
                SizedBox(height: 12),
                if ( booking.uniqueTransactionId != null) ...[
                  Row(
                    children: [

                      if (booking.uniqueTransactionId != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Transaction Id',
                                style: AppTextStyles.popinRegularTextStyle(
                                  fontSize: 14,
                                  color: isPast
                                      ? Color(0xFF9E9E9E).withAlpha(400)
                                      : AppColors.color9D9D9D,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                booking.uniqueTransactionId!,
                                style: AppTextStyles.regularTextStyle(
                                  fontSize: 14,
                                  color: isPast
                                      ? Color(0xFF414141).withAlpha(400)
                                      : AppColors.color2B2B2B,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 12),

                ],


                CustomPaint(
                  size: Size(double.infinity, 1),
                  painter: DashedLinePainter(),
                ),
                SizedBox(height: 12),
                // Address
                Text(
                  AppText.address,
                  style: AppTextStyles.popinRegularTextStyle(
                    fontSize: 14,
                    color: isPast
                        ? Color(0xFF9E9E9E).withAlpha(400)
                        : AppColors.color9D9D9D,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  booking.address,
                  style: AppTextStyles.regularTextStyle(
                    fontSize: 14,
                    color: isPast
                        ? Color(0xFF414141).withAlpha(400)
                        : AppColors.color2B2B2B,
                  ),
                ),
                SizedBox(height: 12),
                CustomPaint(
                  size: Size(double.infinity, 1),
                  painter: DashedLinePainter(),
                ),
                SizedBox(height: 12),

                // Price Breakdown
                if (booking.priceBreakdown != null) ...[
                  Text(
                    'Price Breakdown',
                    style: AppTextStyles.popinRegularTextStyle(
                      fontSize: 14,
                      color: isPast
                          ? Color(0xFF9E9E9E).withAlpha(400)
                          : AppColors.color9D9D9D,
                    ),
                  ),
                  SizedBox(height: 8),
                  _buildBreakdownRow('Service amount', booking.priceBreakdown!.serviceAmount, isPast),
                  _buildBreakdownRow('Platform fee', booking.priceBreakdown!.platformFee, isPast),
                  // _buildBreakdownRow('Booking deposit', booking.priceBreakdown!.bookingFixDepositAmount, isPast),
                  if (booking.priceBreakdown!.refundAmount > 0)
                    _buildBreakdownRow('Refund amount', booking.priceBreakdown!.refundAmount, isPast, isRefund: true),
                  SizedBox(height: 12),
                  CustomPaint(
                    size: Size(double.infinity, 1),
                    painter: DashedLinePainter(),
                  ),
                  SizedBox(height: 12),
                ],

                // Booking & Payment Status
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Status',
                            style: AppTextStyles.popinRegularTextStyle(
                              fontSize: 14,
                              color: isPast
                                  ? Color(0xFF9E9E9E).withAlpha(400)
                                  : AppColors.color9D9D9D,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            booking.bookingStatus?.split('_').map((e) => e.capitalizeFirst).join(' ') ?? 'N/A',
                            style: AppTextStyles.mediumTextStyle(
                              fontSize: 14,
                              color: isPast ? getStatusColor(booking.bookingStatus).withAlpha(400) : getStatusColor(booking.bookingStatus),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Status',
                            style: AppTextStyles.popinRegularTextStyle(
                              fontSize: 14,
                              color: isPast
                                  ? Color(0xFF9E9E9E).withAlpha(400)
                                  : AppColors.color9D9D9D,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            booking.paymentStatus?.replaceAll('_', ' ').capitalizeFirst ?? 'N/A',
                            style: AppTextStyles.mediumTextStyle(
                              fontSize: 14,
                              color: isPast ? getPaymentStatusColor(booking.paymentStatus).withAlpha(400) : getPaymentStatusColor(booking.paymentStatus),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                CustomPaint(
                  size: Size(double.infinity, 1),
                  painter: DashedLinePainter(),
                ),
                SizedBox(height: 12),
                // Consultation with
                Text(
                  'Consultation with',
                  style: AppTextStyles.popinRegularTextStyle(
                    fontSize: 14,
                    color: isPast
                        ? Color(0xFF9E9E9E).withAlpha(400)
                        : AppColors.color9D9D9D,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    // Therapist avatar
                    ClipOval(
                      child: booking.therapistImageUrl != null && booking.therapistImageUrl!.isNotEmpty
                          ? Image.network(
                              booking.therapistImageUrl!,
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  height: 40,
                                  width: 40,
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.grey.shade200,
                                  ),
                                  child: Center(
                                    child: SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: SvgPicture.asset(
                                        AppAssets.profile,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Container(
                              height: 40,
                              width: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey.shade200,
                              ),
                              child: Center(
                                child: SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: SvgPicture.asset(
                                    AppAssets.profile,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            booking.therapistName,
                            style: AppTextStyles.mediumTextStyle(
                              fontSize: 14,
                              color: isPast
                                  ? Color(0xFF414141).withAlpha(400)
                                  : AppColors.blueColor,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            booking.therapistTitle,
                            style: AppTextStyles.regularTextStyle(
                              fontSize: 12,
                              color: isPast
                                  ? Color(0xFF9E9E9E).withAlpha(400)
                                  : AppColors.greyText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isUpcoming)
                      ElevatedButton(
                        onPressed: () => controller.messageTherapistWithProfile(
                          booking.therapistName,
                          booking.professionalId,
                          profileImageUrl: booking.therapistImageUrl,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          padding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Message',
                          style: TextStyle(
                            fontFamily: 'Rubik',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 8),

                // Cancel/Reschedule info (only for upcoming bookings)
                if (isUpcoming && booking.bookingStatus != 'in_progress') ...[
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLightColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryLightColor,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: SvgPicture.asset(AppAssets.info),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppText.cancelRescheduleInfo,
                            style: AppTextStyles.regularTextStyle(
                              fontSize: 12,
                              color: AppColors.blueColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => controller.editBooking(booking.id),
                          icon: SvgPicture.asset(AppAssets.edit),
                          label: Text(
                            AppText.editBooking,
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: AppColors.primaryColor,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1,
                              decorationColor: AppColors.primaryColor,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: AppColors.primaryColor,
                              width: 1,
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              controller.showCancelBookingDialog(booking.id),
                          icon: SvgPicture.asset(AppAssets.cancel),
                          label: Text(
                            'Cancel booking',
                            style: TextStyle(
                              fontFamily: 'Rubik',
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                              decoration: TextDecoration.underline,
                              decorationThickness: 1,
                              decorationColor: Colors.red[200],
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.redDark,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildBreakdownRow(String label, double amount, bool isPast, {bool isRefund = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.regularTextStyle(
              fontSize: 14,
              color: isPast ? Color(0xFF414141).withAlpha(400) : AppColors.color2B2B2B,
            ),
          ),
          Text(
            '£${amount.toStringAsFixed(2)}',
            style: AppTextStyles.mediumTextStyle(
              fontSize: 14,
              color: isRefund
                ? (isPast ? AppColors.redDark.withAlpha(400) : AppColors.redDark)
                : (isPast ? Color(0xFF414141).withAlpha(400) : AppColors.color2B2B2B),
            ),
          ),
        ],
      ),
    );
  }
}
