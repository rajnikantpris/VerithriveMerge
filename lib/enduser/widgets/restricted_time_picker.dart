import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class RestrictedTimePicker {
  static Future<TimeOfDay?> showRestrictedTimePicker({
    required BuildContext context,
    required TimeOfDay initialTime,
    TimeOfDay? minTime,
    TimeOfDay? maxTime,
  }) async {
    TimeOfDay? selectedTime = initialTime;

    return showDialog<TimeOfDay>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            constraints: BoxConstraints(maxHeight: 350, maxWidth: 280),
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Select Time',
                  style: AppTextStyles.mediumTextStyle(
                    fontSize: 16,
                    color: AppColors.black,
                  ),
                ),
                SizedBox(height: 12),
                
                // Time Selection
                Flexible(
                  child: _TimePickerList(
                    initialTime: initialTime,
                    minTime: minTime,
                    maxTime: maxTime,
                    onTimeSelected: (time) {
                      selectedTime = time;
                    },
                  ),
                ),
                
                SizedBox(height: 12),
                
                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.regularTextStyle(
                          fontSize: 14,
                          color: AppColors.greyText,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(selectedTime),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryColor,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'OK',
                        style: AppTextStyles.mediumTextStyle(
                          fontSize: 14,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TimePickerList extends StatefulWidget {
  final TimeOfDay initialTime;
  final TimeOfDay? minTime;
  final TimeOfDay? maxTime;
  final Function(TimeOfDay) onTimeSelected;

  const _TimePickerList({
    required this.initialTime,
    this.minTime,
    this.maxTime,
    required this.onTimeSelected,
  });

  @override
  State<_TimePickerList> createState() => _TimePickerListState();
}

class _TimePickerListState extends State<_TimePickerList> {
  late TimeOfDay selectedTime;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    selectedTime = widget.initialTime;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedTime();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedTime() {
    final timeOptions = _generateTimeOptions();
    final index = timeOptions.indexWhere(
      (time) => time.hour == selectedTime.hour && time.minute == selectedTime.minute,
    );
    if (index != -1 && _scrollController.hasClients) {
      // Calculate scroll position (item height is 60)
      final scrollPosition = index * 60.0;
      // Center the selected item
      final viewportHeight = _scrollController.position.viewportDimension;
      final targetPosition = scrollPosition - (viewportHeight / 2) + 30;
      
      _scrollController.animateTo(
        targetPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isTimeValid(TimeOfDay time) {
    int timeMinutes = time.hour * 60 + time.minute;
    
    if (widget.minTime != null) {
      int minMinutes = widget.minTime!.hour * 60 + widget.minTime!.minute;
      // Allow times from minTime onwards (including minTime)
      if (timeMinutes < minMinutes) return false;
    }
    
    if (widget.maxTime != null) {
      int maxMinutes = widget.maxTime!.hour * 60 + widget.maxTime!.minute;
      // Allow times up to maxTime (including maxTime)
      if (timeMinutes > maxMinutes) return false;
    }
    
    return true;
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  List<TimeOfDay> _generateTimeOptions() {
    List<TimeOfDay> options = [];
    
    // Both minTime and maxTime must be set to generate options
    if (widget.minTime == null || widget.maxTime == null) {
      return options;
    }
    
    // Start from minTime (including it)
    int startHour = widget.minTime!.hour;
    int startMinute = widget.minTime!.minute;
    // Round down to nearest 5-minute interval
    startMinute = (startMinute ~/ 5) * 5;
    
    // End at maxTime (including it)
    int endHour = widget.maxTime!.hour;
    int endMinute = widget.maxTime!.minute;
    // Round down to nearest 5-minute interval
    endMinute = (endMinute ~/ 5) * 5;
    
    // Check if we have a valid range
    int startTotalMinutes = startHour * 60 + startMinute;
    int endTotalMinutes = endHour * 60 + endMinute;
    
    if (startTotalMinutes > endTotalMinutes) {
      return options; // No valid times in range
    }
    
    // Generate all times in 5-minute intervals including boundaries
    int currentHour = startHour;
    int currentMinute = startMinute;
    
    // Continue until we reach or exceed the end time
    while (currentHour < endHour || (currentHour == endHour && currentMinute <= endMinute)) {
      TimeOfDay time = TimeOfDay(hour: currentHour, minute: currentMinute);
      
      // Double-check validation - time must be between min and max (inclusive)
      int timeMinutes = currentHour * 60 + currentMinute;
      int minMinutes = widget.minTime!.hour * 60 + widget.minTime!.minute;
      int maxMinutes = widget.maxTime!.hour * 60 + widget.maxTime!.minute;
      
      // Include times from minTime to maxTime (inclusive)
      if (timeMinutes >= minMinutes && timeMinutes <= maxMinutes) {
        options.add(time);
      }
      
      // Move to next 5-minute interval
      currentMinute += 5;
      if (currentMinute >= 60) {
        currentMinute = 0;
        currentHour++;
        if (currentHour >= 24) break;
      }
    }
    
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final timeOptions = _generateTimeOptions();
    
    // Find initial selected index
    int initialIndex = timeOptions.indexWhere(
      (time) => time.hour == selectedTime.hour && time.minute == selectedTime.minute,
    );
    if (initialIndex == -1 && timeOptions.isNotEmpty) {
      initialIndex = 0;
    }

    if (timeOptions.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text(
            'No available times',
            style: AppTextStyles.regularTextStyle(
              fontSize: 16,
              color: AppColors.greyText,
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: timeOptions.length,
      itemBuilder: (context, index) {
        final time = timeOptions[index];
        final isSelected = time.hour == selectedTime.hour && time.minute == selectedTime.minute;
        
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedTime = time;
                });
                widget.onTimeSelected(time);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primaryColor.withOpacity(0.1)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected 
                        ? AppColors.primaryColor 
                        : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatTime(time),
                      style: AppTextStyles.mediumTextStyle(
                        fontSize: 15,
                        color: isSelected 
                            ? AppColors.primaryColor 
                            : AppColors.black,
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppColors.primaryColor,
                        size: 18,
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

