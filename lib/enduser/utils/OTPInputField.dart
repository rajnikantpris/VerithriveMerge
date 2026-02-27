import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';

class OTPInputField extends StatefulWidget {
  final int length;
  final Function(String) onCompleted;
  final Function(String)? onChanged;
  final double fieldWidth;
  final double fieldHeight;
  final double borderRadius;
  final Color borderColor;
  final Color focusedBorderColor;
  final Color? filledBorderColor;
  final Color fillColor;
  final TextStyle textStyle;
  final GlobalKey? fieldKey;

  const OTPInputField({
    Key? key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.fieldWidth = 50,
    this.fieldHeight = 50,
    this.borderRadius = 8,
    this.borderColor = const Color(0xFFE0E0E0),
    this.focusedBorderColor = AppColors.primaryColor,
    this.filledBorderColor,
    this.fillColor = Colors.white,
    this.textStyle = const TextStyle(
      fontSize: 24,
      fontFamily: 'Rubik',
      fontWeight: FontWeight.w500,
      color: Colors.black,
    ),
    this.fieldKey,
  }) : super(key: fieldKey ?? key);

  @override
  State<OTPInputField> createState() => _OTPInputFieldState();
}

class _OTPInputFieldState extends State<OTPInputField> {
  late List<TextEditingController> _controllers;
  late List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (index) => TextEditingController(),
    );
    _focusNodes = List.generate(
      widget.length,
      (index) {
        final focusNode = FocusNode();
        focusNode.addListener(() {
          setState(() {});
        });
        return focusNode;
      },
    );
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _onChanged(String value, int index) {
    // Get current OTP after any change
    String currentOTP = _controllers.map((c) => c.text).join();
    
    // Call onChanged callback if provided (for any change)
    if (widget.onChanged != null) {
      widget.onChanged!(currentOTP);
    }
    
    if (value.isNotEmpty) {
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Get complete OTP
        if (currentOTP.length == widget.length) {
          widget.onCompleted(currentOTP);
        }
      }
    }
  }

  void _onKeyEvent(RawKeyEvent event, int index) {
    if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        if (_controllers[index].text.isEmpty && index > 0) {
          _focusNodes[index - 1].requestFocus();
        }
      }
    }
  }

  void clearOTP() {
    for (var controller in _controllers) {
      controller.clear();
    }
    _focusNodes[0].requestFocus();
    
    // Call onChanged callback if provided (for clear operation)
    if (widget.onChanged != null) {
      widget.onChanged!(''); // Empty string when cleared
    }
  }

  String getOTP() {
    return _controllers.map((c) => c.text).join();
  }

  void setOTP(String otp) {
    if (otp.length == widget.length) {
      for (int i = 0; i < widget.length && i < otp.length; i++) {
        _controllers[i].text = otp[i];
      }
      setState(() {});
      // Trigger the onCompleted callback
      widget.onCompleted(otp);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return SizedBox(
          width: widget.fieldWidth,
          height: widget.fieldHeight,
          child: RawKeyboardListener(
            focusNode: FocusNode(),
            onKey: (event) => _onKeyEvent(event, index),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _controllers[index],
              builder: (context, value, child) {
                final hasText = value.text.isNotEmpty;
                final hasFocus = _focusNodes[index].hasFocus;
                final borderColor = hasFocus
                    ? widget.focusedBorderColor
                    : (hasText
                        ? (widget.filledBorderColor ?? AppColors.black)
                        : widget.borderColor);
                
                return TextField(
                  controller: _controllers[index],
                  focusNode: _focusNodes[index],
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  maxLength: 1,
                  style: widget.textStyle,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  decoration: InputDecoration(
                    counterText: '',
                    filled: true,
                    fillColor: widget.fillColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: borderColor,
                        width: hasFocus ? 1 : 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: borderColor,
                        width: hasFocus ? 1 : 1,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(widget.borderRadius),
                      borderSide: BorderSide(
                        color: borderColor,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => _onChanged(value, index),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}