import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../theme/colors.dart';
import '../../theme/fonts.dart';
import '../../theme/hight_width_sizes.dart';
import '../../theme/font_sizes.dart';
import '../../theme/image_paths.dart';
import '../../widgets/response_dialog.dart';
import 'calendar_controller.dart';
import 'home_controller.dart';

/// Calendar tab extracted from HomeView so it can be reused and kept lean.
class CalendarTab extends StatelessWidget {
  const CalendarTab({super.key, required this.controller});

  final CalendarController controller;

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
                SizedBox(height: HightWidthSizes.setValue_16),
                _ServiceFormatSection(controller: controller),
                SizedBox(height: HightWidthSizes.setValue_12),
                _AvailabilitySection(controller: controller),
                SizedBox(height: HightWidthSizes.setValue_12),
                _EmptyStateSection(
                  title: 'Booked slots',
                  placeholder: 'No slots booked yet',
                  onAdd: () {},
                ),
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

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HightWidthSizes.setValue_65,
      child: Obx(() {
        final weekDates = controller.monthDates;
        return ListView.separated(
          controller: controller.dateScrollController,
          scrollDirection: Axis.horizontal,
          itemBuilder: (_, index) {
            final date = weekDates[index];
            final label = _weekdayLabel(date);
            final selected = _isSameDay(date, controller.selectedDate.value);
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

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = controller.selectedDate.value;
      final monthDays = _buildMonthDays(selected);

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
                      child: dotColors.isNotEmpty
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
  });

  final String label;
  final String day;
  final bool selected;

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
          SizedBox(height: HightWidthSizes.setValue_8),
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

class _EmptyStateSection extends StatelessWidget {
  const _EmptyStateSection({
    required this.title,
    required this.placeholder,
    required this.onAdd,
  });

  final String title;
  final String placeholder;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: HightWidthSizes.setValue_10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  color: AppColor.color_2D2D2D,
                  fontSize: FontSizes.setFontValue_16,
                ),
              ),
              title == "Booked slots"
                  ? SizedBox(
                      height: HightWidthSizes.setValue_50,
                    )
                  : ElevatedButton.icon(
                      onPressed: onAdd,
                      icon: Text(
                        'Add',
                        style: TextStyle(
                          fontFamily: AppFonts.rubikRegular,
                          fontWeight: FontWeight.w400,
                          color: AppColor.white,
                          fontSize: FontSizes.setFontValue_14,
                        ),
                      ),
                      label: Icon(
                        Icons.add,
                        size: HightWidthSizes.setValue_18,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColor.color_2FC4B2,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: HightWidthSizes.setValue_10,
                          vertical: HightWidthSizes.setValue_6,
                        ),
                        minimumSize: Size(
                          HightWidthSizes.setValue_70,
                          HightWidthSizes.setValue_32,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            HightWidthSizes.setValue_6,
                          ),
                        ),
                        elevation: 0,
                      ),
                    ),
            ],
          ),
          Container(
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
                placeholder,
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
        ],
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

/// Check if a date is in the past (before today, ignoring time)
bool _isPastDate(DateTime date) {
  final today = DateTime.now();
  final dateOnly = DateTime(date.year, date.month, date.day);
  final todayOnly = DateTime(today.year, today.month, today.day);
  return dateOnly.isBefore(todayOnly);
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

class _ServiceFormatSection extends StatelessWidget {
  const _ServiceFormatSection({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: HightWidthSizes.setValue_10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Service format',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  color: AppColor.color_2D2D2D,
                  fontSize: FontSizes.setFontValue_16,
                ),
              ),
              Obx(() {
                final selectedDate = controller.selectedDate.value;
                final isPastDate = _isPastDate(selectedDate);
                // Get approval status from HomeController profile data
                final homeController = Get.isRegistered<HomeController>()
                    ? Get.find<HomeController>()
                    : null;
                final isApproved =
                    homeController?.profileDetails.value?.isApproved ?? false;
                
                if (isPastDate) {
                  return SizedBox(
                    height: HightWidthSizes.setValue_50,
                  );
                }
                
                return ElevatedButton.icon(
                  onPressed: () {
                    // Check if user is approved
                    if (!isApproved) {
                      // Show dialog if not approved
                      showResponseDialog(
                        title: 'Application Under Review',
                        message:
                            'Your professional application has been successfully submitted. Please wait while we review your application. Once it is approved, you will be able to access and use our services.',
                        isError: false,
                        showButton: true,
                      );
                      return;
                    }
                    // Navigate if approved
                    Get.toNamed(
                      Routes.serviceFormat,
                      arguments: controller.selectedDate.value,
                    );
                  },
                  icon: Icon(
                    Icons.add,
                    size: HightWidthSizes.setValue_18,
                  ),
                  label: Text(
                    'Add',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      color: AppColor.white,
                      fontSize: FontSizes.setFontValue_14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.color_2FC4B2,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: HightWidthSizes.setValue_10,
                      vertical: HightWidthSizes.setValue_6,
                    ),
                    minimumSize: Size(
                      HightWidthSizes.setValue_70,
                      HightWidthSizes.setValue_32,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        HightWidthSizes.setValue_6,
                      ),
                    ),
                    elevation: 0,
                  ),
                );
              }),
            ],
          ),
          SizedBox(height: HightWidthSizes.setValue_12),
          Obx(() {
            if (controller.serviceFormats.isEmpty) {
              return Container(
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
                    'Add service format to create availability.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      color: Color(0x80263238),
                      fontSize: FontSizes.setFontValue_14,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: controller.serviceFormats
                  .map((serviceFormat) => _ServiceFormatCard(
                        serviceFormat: serviceFormat,
                        selectedDate: controller.selectedDate.value,
                        onEdit: () {
                          Get.toNamed(
                            Routes.editServiceFormat,
                            arguments: {
                              'serviceFormat': serviceFormat,
                              'selectedDate': controller.selectedDate.value,
                            },
                          );
                        },
                        onDelete: () {
                          _showDeleteConfirmationDialog(
                            serviceFormat.name,
                            () {
                              controller.deleteServiceFormat(serviceFormat.id);
                            },
                          );
                        },
                      ))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _ServiceFormatCard extends StatelessWidget {
  const _ServiceFormatCard({
    required this.serviceFormat,
    required this.selectedDate,
    required this.onEdit,
    required this.onDelete,
  });

  final ServiceFormatItem serviceFormat;
  final DateTime selectedDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: HightWidthSizes.setValue_12),
      padding: EdgeInsets.all(HightWidthSizes.setValue_16),
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border.all(color: AppColor.color_ECECEC),
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_14),
        boxShadow: [
          BoxShadow(
            color: AppColor.color_ECECEC,
            blurRadius: HightWidthSizes.setValue_12,
            offset: const Offset(0, 1),
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
                  serviceFormat.name,
                  style: TextStyle(
                    fontFamily: AppFonts.poppinsMedium,
                    fontWeight: FontWeight.w500,
                    color: AppColor.color_414141,
                    fontSize: FontSizes.setFontValue_14,
                  ),
                ),
              ),
              if (!_isPastDate(selectedDate))
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: EdgeInsets.all(HightWidthSizes.setValue_8),
                        child: AppImages.edit_outline_svg(
                          width: HightWidthSizes.setValue_20,
                          height: HightWidthSizes.setValue_20,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: EdgeInsets.all(HightWidthSizes.setValue_8),
                        child: AppImages.delete_account_svg(
                          width: HightWidthSizes.setValue_20,
                          height: HightWidthSizes.setValue_20,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: HightWidthSizes.setValue_12),
          Container(
            height: 0.5,
            color: AppColor.color_000000.withOpacity(0.2),
          ),
          SizedBox(height: HightWidthSizes.setValue_12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Duration (with "Per session" label for bundles)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (serviceFormat.isBundle)
                      Text(
                        'Per session',
                        style: TextStyle(
                          fontFamily: AppFonts.poppinsRegular,
                          fontWeight: FontWeight.w400,
                          color: AppColor.color_414141.withOpacity(0.6),
                          fontSize: FontSizes.setFontValue_12,
                        ),
                      ),
                    if (serviceFormat.isBundle)
                      SizedBox(height: HightWidthSizes.setValue_4),
                    Text(
                      serviceFormat.duration,
                      style: TextStyle(
                        fontFamily: AppFonts.poppinsRegular,
                        fontWeight: FontWeight.w400,
                        color: AppColor.color_414141,
                        fontSize: FontSizes.setFontValue_14,
                      ),
                    ),
                  ],
                ),
              ),
              // Right side: Price (with "Bundle price" label for bundles)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (serviceFormat.isBundle)
                      Text(
                        'Bundle price',
                        style: TextStyle(
                          fontFamily: AppFonts.poppinsRegular,
                          fontWeight: FontWeight.w400,
                          color: AppColor.color_414141.withOpacity(0.6),
                          fontSize: FontSizes.setFontValue_12,
                        ),
                      ),
                    if (serviceFormat.isBundle)
                      SizedBox(height: HightWidthSizes.setValue_4),
                    Text(
                      serviceFormat.price,
                      style: TextStyle(
                        fontFamily: AppFonts.poppinsSemiBold,
                        fontWeight: FontWeight.w600,
                        color: AppColor.color_414141,
                        fontSize: FontSizes.setFontValue_16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Show offer text for bundles
          if (serviceFormat.isBundle &&
              serviceFormat.offerText != null &&
              serviceFormat.offerText!.isNotEmpty) ...[
            SizedBox(height: HightWidthSizes.setValue_12),
            Container(
              padding: EdgeInsets.all(HightWidthSizes.setValue_12),
              decoration: BoxDecoration(
                color: AppColor.color_CDF1EC, // Light teal background
                borderRadius: BorderRadius.circular(HightWidthSizes.setValue_5),
              ),
              child: Row(
                children: [
                  AppImages.bxs_offer_svg(
                    width: HightWidthSizes.setValue_24,
                    height: HightWidthSizes.setValue_24,
                  ),
                  SizedBox(width: HightWidthSizes.setValue_8),
                  Expanded(
                    child: Text(
                      serviceFormat.offerText!,
                      style: TextStyle(
                        fontFamily: AppFonts.rubikRegular,
                        fontWeight: FontWeight.w400,
                        color: AppColor.color_414141,
                        fontSize: FontSizes.setFontValue_14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AvailabilitySection extends StatelessWidget {
  const _AvailabilitySection({required this.controller});

  final CalendarController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: HightWidthSizes.setValue_10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Availability',
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  color: AppColor.color_2D2D2D,
                  fontSize: FontSizes.setFontValue_16,
                ),
              ),
              Obx(() {
                final selectedDate = controller.selectedDate.value;
                final isPastDate = _isPastDate(selectedDate);
                // Get approval status from HomeController profile data
                final homeController = Get.isRegistered<HomeController>()
                    ? Get.find<HomeController>()
                    : null;
                final isApproved =
                    homeController?.profileDetails.value?.isApproved ?? false;
                
                if (isPastDate) {
                  return SizedBox(
                    height: HightWidthSizes.setValue_50,
                  );
                }
                
                return ElevatedButton.icon(
                  onPressed: () {
                    // Check if user is approved
                    if (!isApproved) {
                      // Show dialog if not approved
                      showResponseDialog(
                        title: 'Application Under Review',
                        message:
                            'Your professional application has been successfully submitted. Please wait while we review your application. Once it is approved, you will be able to access and use our services.',
                        isError: false,
                        showButton: true,
                      );
                      return;
                    }
                    // Navigate if approved
                    Get.toNamed(Routes.createAvailability);
                  },
                  icon: Icon(
                    Icons.add,
                    size: HightWidthSizes.setValue_18,
                  ),
                  label: Text(
                    'Add',
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      color: AppColor.white,
                      fontSize: FontSizes.setFontValue_14,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColor.color_2FC4B2,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: HightWidthSizes.setValue_10,
                      vertical: HightWidthSizes.setValue_6,
                    ),
                    minimumSize: Size(
                      HightWidthSizes.setValue_70,
                      HightWidthSizes.setValue_32,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        HightWidthSizes.setValue_6,
                      ),
                    ),
                    elevation: 0,
                  ),
                );
              }),
            ],
          ),
          SizedBox(height: HightWidthSizes.setValue_12),
          Obx(() {
            if (controller.availabilities.isEmpty) {
              return Container(
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
                    'Add your availability',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppFonts.rubikRegular,
                      fontWeight: FontWeight.w400,
                      color: Color(0x80263238),
                      fontSize: FontSizes.setFontValue_14,
                    ),
                  ),
                ),
              );
            }
            return Column(
              children: controller.availabilities.asMap().entries.map((entry) {
                final index = entry.key;
                final availability = entry.value;
                // Find corresponding raw availability data
                final rawAvailability =
                    index < controller.rawAvailabilities.length
                        ? controller.rawAvailabilities[index]
                        : null;
                return _AvailabilityCard(
                  availability: availability,
                  selectedDate: controller.selectedDate.value,
                  onEdit: () {
                    Get.toNamed(
                      Routes.editAvailability,
                      arguments: {
                        'availability': availability,
                        'rawAvailability': rawAvailability,
                        'selectedDate': controller.selectedDate.value,
                      },
                    );
                  },
                  onDelete: () {
                    _showDeleteAvailabilityDialog(
                      availability.availableFrom,
                      () {
                        controller.deleteAvailability(availability.id);
                      },
                    );
                  },
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _AvailabilityCard extends StatelessWidget {
  const _AvailabilityCard({
    required this.availability,
    required this.selectedDate,
    required this.onEdit,
    required this.onDelete,
  });

  final AvailabilityItem availability;
  final DateTime selectedDate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: HightWidthSizes.setValue_12),
      padding: EdgeInsets.all(HightWidthSizes.setValue_16),
      decoration: BoxDecoration(
        color: AppColor.white,
        border: Border.all(color: AppColor.color_ECECEC),
        borderRadius: BorderRadius.circular(HightWidthSizes.setValue_14),
        boxShadow: [
          BoxShadow(
            color: AppColor.color_ECECEC,
            blurRadius: HightWidthSizes.setValue_12,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Availability',
                style: TextStyle(
                  fontFamily: AppFonts.poppinsMedium,
                  fontWeight: FontWeight.w500,
                  color: AppColor.color_414141,
                  fontSize: FontSizes.setFontValue_14,
                ),
              ),
              if (!_isPastDate(selectedDate))
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: onEdit,
                      child: Container(
                        padding: EdgeInsets.all(HightWidthSizes.setValue_8),
                        child: AppImages.edit_outline_svg(
                          width: HightWidthSizes.setValue_20,
                          height: HightWidthSizes.setValue_20,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: onDelete,
                      child: Container(
                        padding: EdgeInsets.all(HightWidthSizes.setValue_8),
                        child: AppImages.delete_account_svg(
                          width: HightWidthSizes.setValue_20,
                          height: HightWidthSizes.setValue_20,
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: HightWidthSizes.setValue_12),
          Container(
            height: 0.5,
            color: AppColor.color_000000.withOpacity(0.2),
          ),
          SizedBox(height: HightWidthSizes.setValue_12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available from',
                style: TextStyle(
                  fontFamily: AppFonts.poppinsRegular,
                  fontWeight: FontWeight.w400,
                  color: AppColor.color_797979,
                  fontSize: FontSizes.setFontValue_14,
                ),
              ),
              Text(
                availability.availableFrom,
                style: TextStyle(
                  fontFamily: AppFonts.poppinsRegular,
                  fontWeight: FontWeight.w400,
                  color: AppColor.color_414141,
                  fontSize: FontSizes.setFontValue_14,
                ),
              ),
            ],
          ),
          if (availability.breakTimes.isNotEmpty) ...[
            SizedBox(height: HightWidthSizes.setValue_8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Break time',
                  style: TextStyle(
                    fontFamily: AppFonts.poppinsRegular,
                    fontWeight: FontWeight.w400,
                    color: AppColor.color_797979,
                    fontSize: FontSizes.setFontValue_14,
                  ),
                ),
                SizedBox(width: HightWidthSizes.setValue_8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: availability.breakTimes.map((breakTime) {
                      return Text(
                        breakTime,
                        style: TextStyle(
                          fontFamily: AppFonts.poppinsRegular,
                          fontWeight: FontWeight.w400,
                          color: AppColor.color_414141,
                          fontSize: FontSizes.setFontValue_14,
                        ),
                        textAlign: TextAlign.right,
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Helper function to show delete confirmation dialog
void _showDeleteConfirmationDialog(
  String serviceFormatName,
  VoidCallback onConfirm,
) {
  showDialog(
    context: Get.context!,
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
                  'Delete Service Format?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_20,
                    color: AppColor.color_2D3648,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_16),

                // Body text
                Text(
                  'Are you sure you want to delete "$serviceFormatName"?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize: FontSizes.setFontValue_14,
                    color: AppColor.color_2D2D2D,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_24),

                // No, go back button (Primary)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
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
                      'Yes, delete',
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

                // Yes, delete button (Destructive)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
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

/// Helper function to show delete availability confirmation dialog
void _showDeleteAvailabilityDialog(
  String availabilityTime,
  VoidCallback onConfirm,
) {
  showDialog(
    context: Get.context!,
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
                  'Delete Availability?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikMedium,
                    fontWeight: FontWeight.w500,
                    fontSize: FontSizes.setFontValue_20,
                    color: AppColor.color_2D3648,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_16),

                // Body text
                Text(
                  'Are you sure you want to delete availability "$availabilityTime"?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize: FontSizes.setFontValue_14,
                    color: AppColor.color_2D2D2D,
                  ),
                ),
                SizedBox(height: HightWidthSizes.setValue_24),

                // Yes, delete button (Primary)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onConfirm();
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
                      'Yes, delete',
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

                // No, go back button (Secondary)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
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
