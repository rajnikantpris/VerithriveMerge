import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/font_sizes.dart';
import '../theme/fonts.dart';
import '../theme/hight_width_sizes.dart';

class CustomTextField extends StatefulWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    this.icon,
    this.controller,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.inputFormatters,
    this.suffixIcon,
    this.enabled = true,
    this.autofocus = false,
    this.readOnly = false,
    this.onTap,
    this.showLabel = true,
    this.borderColor,
    this.hintTextColor,
    this.hintTextFontFamily,
    this.hintTextFontSize,
    this.borderRadius,
  });

  final String label;
  final String hintText;
  final IconData? icon;
  final TextEditingController? controller;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final int maxLines;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffixIcon;
  final bool enabled;
  final bool autofocus;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool showLabel;
  final Color? borderColor;
  final Color? hintTextColor;
  final String? hintTextFontFamily;
  final double? hintTextFontSize;
  final BorderRadius? borderRadius;

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  // Local controller that we manage - this prevents disposal issues
  late TextEditingController _localController;
  bool _isDisposed = false;
  bool _isSyncing = false; // Prevent infinite sync loops

  @override
  void initState() {
    super.initState();
    // Always create a local controller
    final initialText = _getInitialText();
    _localController = TextEditingController(text: initialText);
    // Listen to local controller changes to sync to original
    _localController.addListener(_syncToOriginal);
    _setupSync();
  }

  @override
  void didUpdateWidget(CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _setupSync();
      // Sync text if original controller changed
      final newText = _getInitialText();
      if (_localController.text != newText) {
        _localController.text = newText;
      }
    }
  }

  String _getInitialText() {
    if (widget.controller == null) return '';
    try {
      return widget.controller!.text;
    } catch (e) {
      // Controller is disposed
      return '';
    }
  }

  void _setupSync() {
    // Remove old listeners
    if (widget.controller != null) {
      try {
        widget.controller!.removeListener(_syncFromOriginal);
      } catch (e) {
        // Controller already disposed, ignore
      }
    }

    // Add new listener if controller exists and is valid
    if (widget.controller != null) {
      try {
        // Test if controller is still valid
        final _ = widget.controller!.text;
        widget.controller!.addListener(_syncFromOriginal);
      } catch (e) {
        // Controller is disposed, don't add listener
      }
    }
  }

  void _syncFromOriginal() {
    if (_isDisposed || _isSyncing || widget.controller == null) return;
    try {
      _isSyncing = true;
      final originalText = widget.controller!.text;
      if (_localController.text != originalText) {
        _localController.text = originalText;
      }
    } catch (e) {
      // Original controller was disposed, stop syncing
      try {
        widget.controller?.removeListener(_syncFromOriginal);
      } catch (_) {
        // Ignore
      }
    } finally {
      _isSyncing = false;
    }
  }

  void _syncToOriginal() {
    if (_isDisposed || _isSyncing || widget.controller == null) return;
    try {
      _isSyncing = true;
      final localText = _localController.text;
      if (widget.controller!.text != localText) {
        widget.controller!.text = localText;
      }
    } catch (e) {
      // Original controller was disposed, stop syncing
      // Don't remove listener here as it's on local controller, not original
    } finally {
      _isSyncing = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    // Remove listener from local controller
    _localController.removeListener(_syncToOriginal);

    // Remove listener from original controller
    if (widget.controller != null) {
      try {
        widget.controller!.removeListener(_syncFromOriginal);
      } catch (e) {
        // Controller already disposed, ignore
      }
    }
    // Dispose local controller
    _localController.dispose();
    super.dispose();
  }

  // Safe wrapper for onChanged callback
  void _safeOnChanged(String value) {
    // Sync to original controller first
    _syncToOriginal();

    // Then call the callback
    if (widget.onChanged == null) return;
    try {
      widget.onChanged!(value);
    } catch (e) {
      // Controller was disposed during callback, ignore silently
    }
  }

  // Safe wrapper for validator
  String? _safeValidator(String? value) {
    if (widget.validator == null) return null;
    try {
      return widget.validator!(value);
    } catch (e) {
      // Controller was disposed during validation, return null (no error)
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel)
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: AppFonts.rubikRegular,
              fontWeight: FontWeight.w400,
              fontSize: FontSizes.setFontValue_14,
              color: AppColor.color_2D2D2D,
            ),
          ),
        if (widget.showLabel) SizedBox(height: HightWidthSizes.setValue_5),
        Builder(
          builder: (context) {
            // Use local controller instead of the original to prevent disposal issues
            try {
              return TextFormField(
                controller: _localController,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                validator: _safeValidator,
                onChanged: _safeOnChanged,
                onFieldSubmitted: widget.onSubmitted,
                onTap: widget.onTap,
                readOnly: widget.readOnly,
                maxLines: widget.maxLines,
                inputFormatters: widget.inputFormatters,
                enabled: widget.enabled,
                autofocus: widget.autofocus,
                style: TextStyle(
                  fontFamily: AppFonts.rubikRegular,
                  fontWeight: FontWeight.w400,
                  fontSize: FontSizes.setFontValue_16,
                  color: AppColor.color_0E1027,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    fontFamily:
                        widget.hintTextFontFamily ?? AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize:
                        widget.hintTextFontSize ?? FontSizes.setFontValue_16,
                    color: widget.hintTextColor ?? AppColor.color_9D9D9D,
                    height: 1.0, // line-height: 100%
                    letterSpacing: 0, // letter-spacing: 0%
                  ),
                  hintMaxLines: 1,
                  prefixIcon: widget.icon != null
                      ? Icon(
                          widget.icon,
                          color: AppColor.color_9D9D9D,
                          size: HightWidthSizes.setValue_16,
                        )
                      : null,
                  suffixIcon: widget.suffixIcon,
                  filled: true,
                  fillColor: AppColor.white,
                  isDense: false,
                  border: OutlineInputBorder(
                    borderRadius: widget.borderRadius ??
                        BorderRadius.circular(HightWidthSizes.setValue_10),
                    borderSide: BorderSide(
                      color: widget.borderColor ?? AppColor.borderColor,
                      width: HightWidthSizes.setValue_1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: widget.borderRadius ??
                        BorderRadius.circular(HightWidthSizes.setValue_10),
                    borderSide: BorderSide(
                      color: widget.borderColor ?? AppColor.borderColor,
                      width: HightWidthSizes.setValue_1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: widget.borderRadius ??
                        BorderRadius.circular(HightWidthSizes.setValue_10),
                    borderSide: BorderSide(
                      color: AppColor.color_32435F,
                      width: HightWidthSizes.setValue_1,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: widget.borderRadius ??
                        BorderRadius.circular(HightWidthSizes.setValue_10),
                    borderSide: BorderSide(
                      color: Colors.red,
                      width: HightWidthSizes.setValue_1,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: widget.borderRadius ??
                        BorderRadius.circular(HightWidthSizes.setValue_10),
                    borderSide: BorderSide(
                      color: Colors.red,
                      width: HightWidthSizes.setValue_1,
                    ),
                  ),
                  errorStyle: TextStyle(
                    fontFamily: AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize: FontSizes.setFontValue_12,
                    color: Colors.red,
                    height: 1.4,
                  ),
                  errorMaxLines: 5,
                  contentPadding: EdgeInsets.only(
                    left: HightWidthSizes.setValue_14,
                    right: widget.suffixIcon != null
                        ? HightWidthSizes.setValue_40
                        : HightWidthSizes.setValue_14,
                    top: HightWidthSizes.setValue_14,
                    bottom: HightWidthSizes.setValue_14,
                  ),
                ),
              );
            } catch (e) {
              // If controller becomes disposed during build, return a disabled field
              return TextFormField(
                enabled: false,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    fontFamily:
                        widget.hintTextFontFamily ?? AppFonts.rubikRegular,
                    fontWeight: FontWeight.w400,
                    fontSize:
                        widget.hintTextFontSize ?? FontSizes.setFontValue_16,
                    color: widget.hintTextColor ?? AppColor.color_9D9D9D,
                  ),
                  filled: true,
                  fillColor: AppColor.white,
                  border: OutlineInputBorder(
                    borderRadius: widget.borderRadius ??
                        BorderRadius.circular(HightWidthSizes.setValue_10),
                    borderSide: BorderSide(
                      color: widget.borderColor ?? AppColor.borderColor,
                      width: HightWidthSizes.setValue_1,
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ],
    );
  }
}
