// lib/app/utils/CustomTextField.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';
import '../utils/app_text_styles.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool enabled;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextCapitalization textCapitalization;
  final bool showLabel;
  final Color? textColor;
  final BorderRadius? borderRadius;
  final bool hideLeftBorder;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final GlobalKey<FormFieldState<String>>? formFieldKey;

  const CustomTextField({
    Key? key,
    required this.controller,
    required this.label,
    required this.hint,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
    this.enabled = true,
    this.readOnly = false,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
    this.showLabel = true,
    this.textColor,
    this.borderRadius,
    this.hideLeftBorder = false,
    this.focusNode,
    this.onChanged,
    this.formFieldKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final textField = TextFormField(
          key: formFieldKey,
          controller: controller,
          focusNode: focusNode,
          obscureText: isPassword,
          obscuringCharacter: '*',
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          textCapitalization: textCapitalization,
          onChanged: (value) {
            if (onChanged != null) {
              onChanged!(value);
            }
          },
          style: textColor != null 
              ? AppTextStyles.inputStyle(color: textColor!)
              : AppTextStyles.inputStyle(),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.hintStyle(),
            prefixIcon: prefixIcon != null
                ? Padding(
              padding:  EdgeInsets.all(14),
              child: prefixIcon,
            )
                : null,
            suffixIcon: suffixIcon != null
                ? Padding(
              padding: (suffixIcon != null && prefixIcon != null) ? EdgeInsets.zero : EdgeInsets.all(14),
              child: suffixIcon,
            )
                : null,
            prefixIconConstraints: BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            suffixIconConstraints: BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            filled: true,
            fillColor: hideLeftBorder ? Colors.transparent : AppColors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: hideLeftBorder
                ? OutlineInputBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  )
                : OutlineInputBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.lightGrey,
                      width: 1,
                    ),
                  ),
            enabledBorder: hideLeftBorder
                ? OutlineInputBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  )
                : OutlineInputBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.lightGrey,
                      width: 1,
                    ),
                  ),
            focusedBorder: hideLeftBorder
                ? OutlineInputBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  )
                : OutlineInputBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: AppColors.blueColor,
                      width: 1,
                    ),
                  ),
            errorBorder: hideLeftBorder
                ? OutlineInputBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  )
                : OutlineInputBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 1,
                    ),
                  ),
            focusedErrorBorder: hideLeftBorder
                ? OutlineInputBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  )
                : OutlineInputBorder(
                    borderRadius: borderRadius ?? BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: Colors.grey,
                      width: 1.5,
                    ),
                  ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel && label.isNotEmpty) ...[
          Text(
            label,
            style: AppTextStyles.labelStyle(),
          ),
          SizedBox(height: 8),
        ],
        hideLeftBorder
            ? Container(
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: borderRadius ?? BorderRadius.circular(8),
                  border: Border(
                    top: BorderSide(color: AppColors.lightGrey, width: 1),
                    right: BorderSide(color: AppColors.lightGrey, width: 1),
                    bottom: BorderSide(color: AppColors.lightGrey, width: 1),
                  ),
                ),
                child: textField,
              )
            : textField,
      ],
    );
  }
}