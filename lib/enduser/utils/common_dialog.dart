import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'app_colors.dart';


void showResponseDialog({
  required String message,
  String? title,
  bool isError = false,
  VoidCallback? onOkPressed,
  bool showButton = true,
}) {
  showDialog(
    context: Get.context!,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (BuildContext context) {
      // Auto-dismiss after 2 seconds if showButton is false
      if (!showButton) {
        Timer(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
          // Wait 2 seconds after dismiss, then call onOkPressed
          // Timer(const Duration(seconds: 2), () {
          onOkPressed?.call();
          // });
        });
      }

      return PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(
            horizontal: 16,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon (optional - can show success or error icon)
                if (isError)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppColors.colorB53232.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: AppColors.colorB53232,
                      size: 30,
                    ),
                  )
                else
                  Container(
                    width: 60,
                    height:60,
                    decoration: BoxDecoration(
                      color: AppColors.color2FC4B2.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_circle_outline,
                      color: AppColors.color2FC4B2,
                      size: 30,
                    ),
                  ),
                SizedBox(height: 20),

                // Title (optional)
                if (title != null && title.isNotEmpty) ...[
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Rubik',
                      fontWeight: FontWeight.w500,
                      fontSize: 20,
                      color: isError
                          ? AppColors.colorB53232
                          : AppColors.color2FC4B2,
                    ),
                  ),
                  SizedBox(height: 12),
                ],

                // Message
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Rubik',
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                    color: AppColors.color2D2D2D,
                    height: 1.5,
                  ),
                ),
                if (showButton) ...[
                  SizedBox(height: 24),

                  // OK button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onOkPressed?.call();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isError
                            ? AppColors.colorB53232
                            : AppColors.color2FC4B2,
                        foregroundColor: AppColors.white,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            10,
                          ),
                        ),
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          fontFamily: 'Rubik',
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}
