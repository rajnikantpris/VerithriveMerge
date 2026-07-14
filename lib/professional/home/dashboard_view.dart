import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common/base_view.dart';
import '../../theme/colors.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../theme/image_paths.dart';
import '../../theme/font_sizes.dart';
import '../../routes/app_routes.dart';
import '../../../services/analytics_service.dart';
import 'home_controller.dart';

/// Dashboard tab extracted from HomeView so it can be reused and kept lean.
class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key, required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(
                    left: HightWidthSizes.setValue_10,
                    right: HightWidthSizes.setValue_10,
                    top: HightWidthSizes.setValue_10,
                    bottom: HightWidthSizes.setValue_10,
                  ),
                  padding: EdgeInsets.only(
                    top: HightWidthSizes.setValue_10,
                    bottom: HightWidthSizes.setValue_10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      HightWidthSizes.setValue_14,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: HightWidthSizes.setValue_8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Obx(() {
                    final showMonth = controller.showMonthView.value;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: HightWidthSizes.setValue_5),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: controller.goToPreviousMonth,
                              child: Container(
                                margin: EdgeInsets.only(
                                  left: HightWidthSizes.setValue_10,
                                ),
                                child: const Icon(Icons.chevron_left,
                                    color: AppColor.color_32435F),
                              ),
                            ),
                            Text(
                              controller.getMonthYearText(),
                              style: TextStyle(
                                fontFamily: AppFonts.rubikBold,
                                fontWeight: FontWeight.w600,
                                color: AppColor.color_32435F,
                                fontSize: FontSizes.setFontValue_16,
                              ),
                            ),
                            GestureDetector(
                              onTap: controller.goToNextMonth,
                              child: Container(
                                margin: EdgeInsets.only(
                                  right: HightWidthSizes.setValue_10,
                                ),
                                child: const Icon(Icons.chevron_right,
                                    color: AppColor.color_32435F),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: HightWidthSizes.setValue_12),
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 200),
                          firstChild: _WeekCalendar(controller: controller),
                          secondChild: _MonthCalendar(controller: controller),
                          crossFadeState: showMonth
                              ? CrossFadeState.showSecond
                              : CrossFadeState.showFirst,
                        ),
                        SizedBox(height: HightWidthSizes.setValue_10),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: controller.toggleCalendarView,
                          child: SizedBox(
                            height: HightWidthSizes.setValue_15,
                            child: Center(
                              child: Container(
                                width: HightWidthSizes.setValue_50,
                                height: HightWidthSizes.setValue_4,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade400,
                                  borderRadius: BorderRadius.circular(
                                    HightWidthSizes.setValue_20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
                // Upcoming sessions section
                Obx(() {
                  // Hide entire upcoming sessions section if selected date is in the past
                  if (controller.isSelectedDatePast) {
                    return SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          left: HightWidthSizes.setValue_10,
                          right: HightWidthSizes.setValue_10,
                          bottom: HightWidthSizes.setValue_15,
                          top: HightWidthSizes.setValue_15,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Upcoming sessions',
                              style: TextStyle(
                                fontFamily: AppFonts.poppinsSemiBold,
                                fontWeight: FontWeight.w600,
                                color: AppColor.color_484848,
                                fontSize: FontSizes.setFontValue_16,
                              ),
                            ),
                            Row(
                              children: [
                                Obx(
                                  () => Theme(
                                    data: Theme.of(context).copyWith(
                                      checkboxTheme: CheckboxThemeData(
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            HightWidthSizes.setValue_4,
                                          ),
                                        ),
                                        side: BorderSide(
                                          color: AppColor.color_B5B6CA,
                                          width: HightWidthSizes.setValue_1,
                                        ),
                                      ),
                                    ),
                                    child: SizedBox(
                                      width: HightWidthSizes.setValue_20,
                                      height: HightWidthSizes.setValue_20,
                                      child: Checkbox(
                                        value: controller.addToCalendar.value,
                                        onChanged:
                                            controller.toggleAddToCalendar,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: HightWidthSizes.setValue_5),
                                Text(
                                  'Add to calendar',
                                  style: TextStyle(
                                    fontFamily: AppFonts.rubikRegular,
                                    fontWeight: FontWeight.w400,
                                    color: AppColor.color_2D2D2D,
                                    fontSize: FontSizes.setFontValue_14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (controller.upcomingSessions.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(
                            left: HightWidthSizes.setValue_10,
                            right: HightWidthSizes.setValue_10,
                          ),
                          child: Column(
                            children: controller.upcomingSessions
                                .map(
                                  (session) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: HightWidthSizes.setValue_12,
                                    ),
                                    child: _SessionCard(
                                      session: session,
                                      controller: controller,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        )
                      else
                        Container(
                          margin: EdgeInsets.only(
                            left: HightWidthSizes.setValue_10,
                            right: HightWidthSizes.setValue_10,
                          ),
                          child: Container(
                            width: double.infinity,
                            height: HightWidthSizes.setValue_100,
                            decoration: BoxDecoration(
                              color: AppColor.color_F7F7F7,
                              borderRadius: BorderRadius.circular(
                                HightWidthSizes.setValue_10,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'No upcoming sessions',
                                style: TextStyle(
                                  fontFamily: AppFonts.rubikRegular,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0x80263238),
                                  fontSize: FontSizes.setFontValue_14,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),

                // Cancelled sessions section
                Obx(() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          left: HightWidthSizes.setValue_10,
                          right: HightWidthSizes.setValue_10,
                          bottom: HightWidthSizes.setValue_15,
                          top: HightWidthSizes.setValue_15,
                        ),
                        child: Text(
                          'Cancelled sessions',
                          style: TextStyle(
                            fontFamily: AppFonts.poppinsSemiBold,
                            fontWeight: FontWeight.w600,
                            color: AppColor.color_484848,
                            fontSize: FontSizes.setFontValue_16,
                          ),
                        ),
                      ),
                      if (controller.cancelledSessions.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(
                            left: HightWidthSizes.setValue_10,
                            right: HightWidthSizes.setValue_10,
                          ),
                          child: Column(
                            children: controller.cancelledSessions
                                .map(
                                  (session) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: HightWidthSizes.setValue_12,
                                    ),
                                    child: _SessionCard(
                                      session: session,
                                      controller: controller,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        )
                      else
                        Container(
                          margin: EdgeInsets.only(
                            left: HightWidthSizes.setValue_10,
                            right: HightWidthSizes.setValue_10,
                          ),
                          child: Container(
                            width: double.infinity,
                            height: HightWidthSizes.setValue_100,
                            decoration: BoxDecoration(
                              color: AppColor.color_F7F7F7,
                              borderRadius: BorderRadius.circular(
                                HightWidthSizes.setValue_10,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'No cancelled sessions',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppFonts.rubikRegular,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0x80263238),
                                  fontSize: FontSizes.setFontValue_14,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),

                // Past sessions section
                Obx(() {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: EdgeInsets.only(
                          left: HightWidthSizes.setValue_10,
                          right: HightWidthSizes.setValue_10,
                          bottom: HightWidthSizes.setValue_15,
                          top: HightWidthSizes.setValue_15,
                        ),
                        child: Text(
                          'Completed sessions',
                          style: TextStyle(
                            fontFamily: AppFonts.poppinsSemiBold,
                            fontWeight: FontWeight.w600,
                            color: AppColor.color_484848,
                            fontSize: FontSizes.setFontValue_16,
                          ),
                        ),
                      ),
                      if (controller.pastSessions.isNotEmpty)
                        Container(
                          margin: EdgeInsets.only(
                            left: HightWidthSizes.setValue_10,
                            right: HightWidthSizes.setValue_10,
                          ),
                          child: Column(
                            children: controller.pastSessions
                                .map(
                                  (session) => Padding(
                                    padding: EdgeInsets.only(
                                      bottom: HightWidthSizes.setValue_12,
                                    ),
                                    child: _SessionCard(
                                      session: session,
                                      controller: controller,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        )
                      else
                        Container(
                          margin: EdgeInsets.only(
                            left: HightWidthSizes.setValue_10,
                            right: HightWidthSizes.setValue_10,
                          ),
                          child: Container(
                            width: double.infinity,
                            height: HightWidthSizes.setValue_100,
                            decoration: BoxDecoration(
                              color: AppColor.color_F7F7F7,
                              borderRadius: BorderRadius.circular(
                                HightWidthSizes.setValue_10,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'No completed sessions',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: AppFonts.rubikRegular,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0x80263238),
                                  fontSize: FontSizes.setFontValue_14,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekCalendar extends StatelessWidget {
  const _WeekCalendar({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HightWidthSizes.setValue_72,
      child: Obx(() {
        final weekDates = controller.monthDates;
        return ListView.separated(
          controller: controller.dateScrollController,
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, index) {
            final date = weekDates[index];
            final label = _weekdayLabel(date);
            final selected = _isSameDay(date, controller.selectedDate.value);
            final showDot = controller.shouldShowBookingDot(date);
            final hasBooking = controller.hasBookingOnDate(date);
            return Container(
              margin: EdgeInsets.only(
                left: HightWidthSizes.setValue_2,
                right: HightWidthSizes.setValue_2,
              ),
              child: GestureDetector(
                onTap: () => controller.selectDate(date),
                child: _DatePill(
                  label: label,
                  day: date.day.toString(),
                  selected: selected,
                  bookingDotColor: showDot
                      ? (hasBooking
                          ? AppColor.greenText
                          : AppColor.color_E74C3C)
                      : null,
                ),
              ),
            );
          },
          separatorBuilder: (_, __) =>
              SizedBox(width: HightWidthSizes.setValue_1),
          itemCount: weekDates.length,
        );
      }),
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({required this.controller});

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedDate.value;
      final monthDays = _buildMonthDays(selected);
      controller.bookingPresenceByDate.length;

      return Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _monthWeekdayLabels.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              final today = DateTime.now();
              final isSelectedWeekday = index == (today.weekday % 7);

              return Expanded(
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: HightWidthSizes.setValue_2,
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: HightWidthSizes.setValue_8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelectedWeekday
                        ? AppColor.color_32435F
                        : AppColor.color_F5F7F8,
                    borderRadius: BorderRadius.circular(
                      HightWidthSizes.setValue_10,
                    ),
                    border: Border.all(
                      color: isSelectedWeekday
                          ? AppColor.color_32435F
                          : AppColor.color_ECECEC,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w500,
                        color: isSelectedWeekday
                            ? AppColor.white
                            : AppColor.color_6B808B,
                        fontSize: FontSizes.setFontValue_13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: HightWidthSizes.setValue_8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: monthDays.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: HightWidthSizes.setValue_6,
              crossAxisSpacing: HightWidthSizes.setValue_6,
              childAspectRatio: 1,
            ),
            itemBuilder: (_, index) {
              final day = monthDays[index];
              final isSelected = _isSameDay(day.date, selected);
              final isCurrentMonth = day.isCurrentMonth;
              final dotColors = isCurrentMonth
                  ? controller.getEventColorsForDate(day.date)
                  : const <Color>[];

              final textColor = isSelected
                  ? Colors.white
                  : isCurrentMonth
                      ? AppColor.color_32435F
                      : Colors.grey.shade400;

              return GestureDetector(
                onTap: () => controller.selectDate(day.date),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: HightWidthSizes.setValue_30,
                      height: HightWidthSizes.setValue_30,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColor.color_32435F
                            : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColor.color_32435F
                              : Colors.transparent,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${day.date.day}',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikRegular,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          fontSize: FontSizes.setFontValue_15,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: HightWidthSizes.setValue_14,
                      child: isCurrentMonth && dotColors.isNotEmpty
                          ? Padding(
                              padding: EdgeInsets.only(
                                top: HightWidthSizes.setValue_6,
                              ),
                              child: _EventDots(
                                colors: dotColors,
                                selected: isSelected,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      );
    });
  }
}

class _EventDots extends StatelessWidget {
  const _EventDots({required this.colors, required this.selected});

  final List<Color> colors;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: colors
          .map(
            (color) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: HightWidthSizes.setValue_2,
              ),
              child: Container(
                width: HightWidthSizes.setValue_6,
                height: HightWidthSizes.setValue_6,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.label,
    required this.day,
    required this.selected,
    this.bookingDotColor,
  });

  final String label;
  final String day;
  final bool selected;
  final Color? bookingDotColor;

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? Theme.of(context).colorScheme.primary : Colors.grey;
    return Container(
      width: HightWidthSizes.setValue_45,
      decoration: BoxDecoration(
        color: selected ? AppColor.color_32435F : AppColor.white,
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_12),
        border: Border.all(color: selected ? color : Colors.grey.shade300),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: selected
                ? TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    color: AppColor.color_F1F1F1,
                    fontSize: FontSizes.setFontValue_14,
                  )
                : TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    color: AppColor.color_6B808B,
                    fontSize: FontSizes.setFontValue_14,
                  ),
          ),
          SizedBox(height: HightWidthSizes.setValue_4),
          Text(
            day,
            style: selected
                ? TextStyle(
                    fontFamily: AppFonts.rubikBold,
                    fontWeight: FontWeight.w600,
                    color: AppColor.color_F1F1F1,
                    fontSize: FontSizes.setFontValue_14,
                  )
                : TextStyle(
                    fontFamily: AppFonts.rubikBold,
                    fontWeight: FontWeight.w600,
                    color: AppColor.color_32435F,
                    fontSize: FontSizes.setFontValue_14,
                  ),
          ),
          SizedBox(height: HightWidthSizes.setValue_4),
          SizedBox(
            width: HightWidthSizes.setValue_6,
            height: HightWidthSizes.setValue_6,
            child: bookingDotColor != null
                ? Container(
                    decoration: BoxDecoration(
                      color: bookingDotColor,
                      shape: BoxShape.circle,
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _MonthDay {
  _MonthDay({required this.date, required this.isCurrentMonth});

  final DateTime date;
  final bool isCurrentMonth;
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.controller,
  });

  final SessionData session;
  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_14),
        border: Border.all(color: AppColor.color_ECECEC),
        boxShadow: [
          BoxShadow(
            color: AppColor.color_ECECEC,
            blurRadius: HightWidthSizes.setValue_3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              left: HightWidthSizes.setValue_14,
              right: HightWidthSizes.setValue_14,
              top: HightWidthSizes.setValue_10,
              bottom: HightWidthSizes.setValue_10,
            ),
            decoration: BoxDecoration(
              color: AppColor.color_0045B5_0A,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(HightWidthSizes.setValue_14),
                topRight: Radius.circular(HightWidthSizes.setValue_14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    session.title,
                    style: TextStyle(
                      fontFamily: AppFonts.poppinsBold,
                      fontWeight: FontWeight.w700,
                      color: AppColor.color_414141,
                      fontSize: FontSizes.setFontValue_14,
                    ),
                  ),
                ),
                if (session.isCancelled)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: HightWidthSizes.setValue_8,
                      vertical: HightWidthSizes.setValue_4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.color_B53232,
                      borderRadius: BorderRadius.circular(
                        HightWidthSizes.setValue_4,
                      ),
                    ),
                    child: Text(
                      'Cancelled',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        color: AppColor.white,
                        fontSize: FontSizes.setFontValue_12,
                      ),
                    ),
                  ),
                if (session.isPasted && !session.isCancelled)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: HightWidthSizes.setValue_8,
                      vertical: HightWidthSizes.setValue_4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.color_2FC4B2,
                      borderRadius: BorderRadius.circular(
                        HightWidthSizes.setValue_4,
                      ),
                    ),
                    child: Text(
                      'Completed',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        color: AppColor.white,
                        fontSize: FontSizes.setFontValue_12,
                      ),
                    ),
                  ),
                if (session.isInProgress)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: HightWidthSizes.setValue_8,
                      vertical: HightWidthSizes.setValue_4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColor.color_0045B5,
                      borderRadius: BorderRadius.circular(
                        HightWidthSizes.setValue_4,
                      ),
                    ),
                    child: Text(
                      'In Progress',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        color: AppColor.white,
                        fontSize: FontSizes.setFontValue_12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(height: HightWidthSizes.setValue_12),
          Row(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: HightWidthSizes.setValue_14,
                  right: HightWidthSizes.setValue_14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        AppImages.user_list_svg(
                          width: HightWidthSizes.setValue_15,
                          height: HightWidthSizes.setValue_15,
                        ),
                        SizedBox(width: HightWidthSizes.setValue_5),
                        Text(
                          session.name,
                          style: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontWeight: FontWeight.w400,
                            color: AppColor.color_414141,
                            fontSize: FontSizes.setFontValue_14,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: HightWidthSizes.setValue_5),
                    Row(
                      children: [
                        AppImages.clock_list_svg(
                          width: HightWidthSizes.setValue_15,
                          height: HightWidthSizes.setValue_15,
                        ),
                        SizedBox(width: HightWidthSizes.setValue_5),
                        Text(
                          session.timeRange,
                          style: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontWeight: FontWeight.w400,
                            color: AppColor.color_898989,
                            fontSize: FontSizes.setFontValue_14,
                          ),
                        ),
                        SizedBox(width: HightWidthSizes.setValue_10),
                        AppImages.calender_list_svg(
                          width: HightWidthSizes.setValue_15,
                          height: HightWidthSizes.setValue_15,
                        ),
                        SizedBox(width: HightWidthSizes.setValue_5),
                        Text(
                          session.dateLabel,
                          style: TextStyle(
                            fontFamily: AppFonts.rubikRegular,
                            fontWeight: FontWeight.w400,
                            color: AppColor.color_898989,
                            fontSize: FontSizes.setFontValue_14,
                          ),
                        ),
                      ],
                    ),
                    (session.isCancelled || session.isPasted)
                        ? SizedBox(height: HightWidthSizes.setValue_10)
                        : SizedBox.shrink(),
                  ],
                ),
              ),
            ],
          ),
          if (!session.isCancelled && !session.isPasted) ...[
            SizedBox(height: HightWidthSizes.setValue_10),
            Center(
              child: Container(
                margin: EdgeInsets.only(
                  left: HightWidthSizes.setValue_14,
                  right: HightWidthSizes.setValue_14,
                ),
                height: HightWidthSizes.setValue_1,
                decoration: BoxDecoration(
                  color: AppColor.color000000.withOpacity(0.1),
                ),
              ),
            ),
            if (session.isInProgress)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _ActionButton(
                    onTap: () {
                      Get.toNamed(
                        Routes.chat,
                        arguments: {
                          'userId': session.userId,
                          'name': session.name,
                        },
                      );
                    },
                    icon: AppImages.chat_list_svg(
                      width: HightWidthSizes.setValue_15,
                      height: HightWidthSizes.setValue_15,
                    ),
                    label: 'Message',
                    textColor: AppColor.color_2FC4B2,
                  ),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    onTap: () {
                      // Analytics: Log cancel session tap event
                      AnalyticsService.instance.logEvent(
                        name: 'cancel_session_tap',
                        parameters: {
                          'screen_name': 'ProfessionalHomeScreen',
                          'screen_class': 'DashboardView',
                          'element_text': 'Cancel Session',
                          'element_location': 'button_tap_cta',
                          'page_category': 'home',
                        },
                      );
                      showCancelSessionDialog(context, session.id, controller);
                    },
                    icon: AppImages.delete_list_svg(
                      width: HightWidthSizes.setValue_15,
                      height: HightWidthSizes.setValue_15,
                    ),
                    label: 'Cancel',
                    textColor: AppColor.color_B53232,
                  ),
                  Center(
                    child: Container(
                      width: HightWidthSizes.setValue_2,
                      height: HightWidthSizes.setValue_25,
                      decoration: BoxDecoration(
                        color: AppColor.color000000.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(
                          HightWidthSizes.setValue_20,
                        ),
                      ),
                    ),
                  ),
                  _ActionButton(
                    onTap: () {
                      Get.toNamed(
                        Routes.rescheduleSession,
                        arguments: session,
                      );
                    },
                    icon: AppImages.refresh_list_svg(
                      width: HightWidthSizes.setValue_15,
                      height: HightWidthSizes.setValue_15,
                    ),
                    label: 'Reschedule',
                    textColor: AppColor.color_0045B5,
                  ),
                  Center(
                    child: Container(
                      width: HightWidthSizes.setValue_2,
                      height: HightWidthSizes.setValue_25,
                      decoration: BoxDecoration(
                        color: AppColor.color000000.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(
                          HightWidthSizes.setValue_20,
                        ),
                      ),
                    ),
                  ),
                  _ActionButton(
                    onTap: () {
                      Get.toNamed(
                        Routes.chat,
                        arguments: {
                          'userId': session.userId,
                          'name': session.name,
                        },
                      );
                    },
                    icon: AppImages.chat_list_svg(
                      width: HightWidthSizes.setValue_15,
                      height: HightWidthSizes.setValue_15,
                    ),
                    label: 'Message',
                    textColor: AppColor.color_2FC4B2,
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.onTap,
    required this.icon,
    required this.label,
    this.textColor,
  });

  final VoidCallback onTap;
  final Widget icon;
  final String label;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: icon,
      label: Text(
        label,
        style: TextStyle(
          fontFamily: AppFonts.rubikRegular,
          fontWeight: FontWeight.w400,
          color: textColor,
          fontSize: FontSizes.setFontValue_15,
        ),
      ),
    );
  }
}

String _weekdayLabel(DateTime date) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return labels[date.weekday - 1];
}

bool _isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

List<_MonthDay> _buildMonthDays(DateTime reference) {
  final firstDay = DateTime(reference.year, reference.month, 1);
  final startWeekday = firstDay.weekday % 7; // Sunday -> 0
  final daysInMonth = DateTime(reference.year, reference.month + 1, 0).day;
  final previousMonthDayCount = DateTime(
    reference.year,
    reference.month,
    0,
  ).day;

  final days = <_MonthDay>[];

  for (int i = startWeekday - 1; i >= 0; i--) {
    final day = previousMonthDayCount - i;
    days.add(
      _MonthDay(
        date: DateTime(reference.year, reference.month - 1, day),
        isCurrentMonth: false,
      ),
    );
  }

  for (int i = 1; i <= daysInMonth; i++) {
    days.add(
      _MonthDay(
        date: DateTime(reference.year, reference.month, i),
        isCurrentMonth: true,
      ),
    );
  }

  final remainder = days.length % 7;
  if (remainder != 0) {
    final extra = 7 - remainder;
    for (int i = 1; i <= extra; i++) {
      days.add(
        _MonthDay(
          date: DateTime(reference.year, reference.month + 1, i),
          isCurrentMonth: false,
        ),
      );
    }
  }

  return days;
}

const _monthWeekdayLabels = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

void showCancelSessionDialog(
  BuildContext context,
  String sessionId,
  HomeController controller,
) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext context) {
      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: HightWidthSizes.setValue_16,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: HightWidthSizes.setValue_10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(HightWidthSizes.setValue_24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Title
                Text(
                  'Cancel session',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_20,
                    color: AppColor.color000000,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_16),

                // Body text
                Text(
                  'Life happens. Are you sure you want to cancel this session?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize: FontSizes.setFontValue_16,
                    color: AppColor.color_2D2D2D,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_24),

                // Yes, cancel session button (Primary)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      controller.cancelSession(sessionId);
                      showSessionCancelledDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.color_2FC4B2,
                      foregroundColor: AppColor.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(
                        vertical: HightWidthSizes.setValue_14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          HightWidthSizes.setValue_10,
                        ),
                      ),
                    ),
                    child: Text(
                      'Yes, cancel session',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikMedium,
                        fontWeight: FontWeight.w500,
                        fontSize: FontSizes.setFontValue_16,
                        color: AppColor.white,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_12),

                // No, go back button (Secondary - text link)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      // Analytics: Log cancel session go back event
                      AnalyticsService.instance.logEvent(
                        name: 'cancel_session_tap',
                        parameters: {
                          'screen_name': 'ProfessionalHomeScreen',
                          'screen_class': 'DashboardView',
                          'element_text': 'go back',
                          'element_location': 'button_tap_cta',
                          'page_category': 'home',
                        },
                      );
                      Navigator.of(context).pop();
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: HightWidthSizes.setValue_14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          HightWidthSizes.setValue_10,
                        ),
                      ),
                    ),
                    child: Text(
                      'No, go back',
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        fontSize: FontSizes.setFontValue_16,
                        color: AppColor.color_32435F,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void showSessionCancelledDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext dialogContext) {
      // Auto-dismiss after 10 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (dialogContext.mounted && Navigator.of(dialogContext).canPop()) {
          Navigator.of(dialogContext).pop();
        }
      });

      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: HightWidthSizes.setValue_5,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColor.white,
              borderRadius: BorderRadius.circular(HightWidthSizes.setValue_10),
            ),
            padding: EdgeInsets.all(HightWidthSizes.setValue_10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Teal circle with white checkmark
                Container(
                  width: HightWidthSizes.setValue_80,
                  height: HightWidthSizes.setValue_80,
                  decoration: BoxDecoration(
                    color: AppColor.color_2FC4B2,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: AppColor.white,
                    size: HightWidthSizes.setValue_50,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_24),

                // Session cancelled text
                Text(
                  'Session cancelled',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_20,
                    color: AppColor.color_2FC4B2,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
