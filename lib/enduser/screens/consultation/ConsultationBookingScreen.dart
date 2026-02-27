import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:verithrive_dev/enduser/utils/app_assets.dart';
import '../../core/widget/animated_loader.dart';
import '../../utils/AppText.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_text_styles.dart';
import 'ConsultationBookingController.dart';

class ConsultationBookingScreen extends StatelessWidget {
  final controller = Get.put(ConsultationBookingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.white,
        elevation: 4, // 🔴 Add shadow depth (try 2-8
        shadowColor: Colors.black.withOpacity(
          0.1,
        ), // Optional: customize shadow color
        scrolledUnderElevation: 4,
        leading: IconButton(
          icon: SvgPicture.asset(AppAssets.back),
          onPressed: () => Get.back(),
        ),
        title: Text(
          AppText.consultationInPerson,
          style: AppTextStyles.mediumTextStyle(
            fontSize: 20,
            color: AppColors.black
          ),
        ),
        centerTitle: false,
      ),
      body: Column(
        children: [

          Container(
            margin: EdgeInsets.all(10),
            decoration: BoxDecoration(
              border:Border.all(color: AppColors.grey),
              borderRadius: BorderRadius.circular(10)
            ),
            child: Column(children: [
              // Calendar Header
              Obx(() => Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() {
                      final now = DateTime.now();
                      final currentMonth = DateTime(now.year, now.month, 1);
                      final canGoPrevious = controller.selectedMonth.value.isAfter(currentMonth) || 
                                           controller.selectedMonth.value.isAtSameMomentAs(currentMonth);
                      return IconButton(
                        icon: Icon(Icons.chevron_left, 
                          color: canGoPrevious ? AppColors.black : AppColors.grey),
                        onPressed: canGoPrevious ? controller.previousMonth : null,
                      );
                    }),
                    Text(
                      controller.getFormattedMonth(),
                      style: AppTextStyles.popinSemiboldTextStyle(
                        fontSize: 16,
                        color: AppColors.blueColor,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.chevron_right, color: AppColors.black),
                      onPressed: controller.nextMonth,
                    ),
                  ],
                ),
              )),

              SizedBox(height: 12),

              // Available Days - Horizontal Scrollable
              Obx(() => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _buildAvailableDays(),
                ),
              )),

              SizedBox(height: 10,),
              
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.lightGrey,
                  borderRadius: BorderRadius.circular(50)
                ),
              ),

              SizedBox(height: 10,),
              
            ],),
          ),

          SizedBox(height: 20),

          // Legend
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20,vertical: 10),
            margin: EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
                border:Border.all(color: AppColors.grey),
                borderRadius: BorderRadius.circular(10)
            ),
            child: Row(
              children: [
                _buildLegendItem(
                    AppColors.availableColor, AppText.available),
                SizedBox(width: 20),
                _buildLegendItem(AppColors.unavailableColor, AppText.unavailable),
              ],
            ),
          ),

          SizedBox(height: 20),

          // Time Slots
          Expanded(
            child: Obx(() {
              if (controller.isLoadingAvailability.value) {
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
              
              if (controller.timeSlots.isEmpty) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Obx(() => Text(
                      controller.apiMessage.value.isNotEmpty 
                          ? controller.apiMessage.value 
                          : 'No time slots available for this date',
                      style: AppTextStyles.regularTextStyle(
                        fontSize: 16,
                        color: AppColors.greyText,
                      ),
                      textAlign: TextAlign.center,
                    )),
                  ),
                );
              }
              
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: ListView.builder(
                  itemCount: controller.timeSlots.length,
                  itemBuilder: (context, index) {
                    return _buildTimeSlot(controller.timeSlots[index],index);
                  },
                ),
              );
            }),
          ),

        ],
      ),
    );
  }

  List<Widget> _buildAvailableDays() {
    List<Widget> days = [];
    List<DateTime> availableDays = controller.getAvailableDays();
    List<String> dayNames = [AppText.sun, AppText.mon, AppText.tue, AppText.wed, AppText.thu, AppText.fri, AppText.sat];

    for (int i = 0; i < availableDays.length; i++) {
      DateTime day = availableDays[i];
      String dayName = dayNames[day.weekday % 7]; // Get day name based on weekday
      bool isSelected = controller.isDaySelected(day);

      days.add(
        GestureDetector(
          onTap: () => controller.selectDay(day),
          child: Container(
            width: 45,
            height: 70,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.black : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.grey),
            ),
            margin: EdgeInsets.all(5),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayName,
                  style: AppTextStyles.regularTextStyle(
                    fontSize: 14,
                    color: isSelected ? AppColors.white : AppColors.color6B808B,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  day.day.toString(),
                  style: AppTextStyles.mediumTextStyle(
                    fontSize: 16,
                    color: isSelected ? AppColors.white : AppColors.blueColor,
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.orangeDotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return days;
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.regularTextStyle(
            fontSize: 14,
            color: AppColors.blueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeSlot(String time,int index) {
    return Obx(() {
      bool isAvailable = controller.isSlotAvailable(time);
      bool isSelected = controller.isSlotSelected(time);
      bool isDisabled = controller.isSlotDisabled(time);
      bool isUnavailable = controller.isSlotUnavailable(time);

      return Column(
        children: [

          Container(
            height: 0.5,
            color: AppColors.grey,
          ),

          Container(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time label on the left
                Container(
                  width: MediaQuery.of(Get.context!).size.width * 0.16,
                  child: Text(
                    time,
                    style: AppTextStyles.regularTextStyle(
                      fontSize: 12,
                      color: isDisabled ? AppColors.grey : AppColors.color757575,
                    ),
                  ),
                ),

                // Horizontal slot container
                Expanded(
                  child: GestureDetector(
                    onTap: isAvailable ? () => controller.selectTimeSlot(time) : null,
                    child: Container(
                      margin: EdgeInsets.only(left: 8),
                 /*     decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: AppColors.grey,
                            width: 1,
                          ),
                        ),
                      ),*/
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryColor
                              : isAvailable
                              ? AppColors.availableColor
                              : isDisabled
                              ? AppColors.lightGrey
                              : AppColors.unavailableColor,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected
                              ? Border(
                            left: BorderSide(
                              color: AppColors.primaryColor,
                              width: 4,
                            ),
                          )
                              : isUnavailable
                              ? Border(
                            left: BorderSide(
                              color: Colors.red.shade400,
                              width: 4,
                            ),
                          )
                              : null,
                        ),
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.only(left: 16),
                        child: isUnavailable
                            ? Text(
                          AppText.unavailable,
                          style: AppTextStyles.regularTextStyle(
                            fontSize: 12,
                            color: AppColors.black,
                          ),
                        )
                            : null,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 10,),

         // (index == controller.timeSlots.length - 1) ? SizedBox(height: 10,) : SizedBox(),
        ],
      );
    });
  }
}