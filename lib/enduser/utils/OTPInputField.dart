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
  final String? initialOTP;

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
    this.initialOTP,
  }) : super(key: fieldKey ?? key);

  @override
  State<OTPInputField> createState() => OTPInputFieldState();
}

class OTPInputFieldState extends State<OTPInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode()..addListener(() => setState(() {}));
    _controller.addListener(_syncFromController);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();

      final initialOTP = widget.initialOTP;
      if (initialOTP != null && initialOTP.isNotEmpty) {
        _fillOTP(initialOTP);
      }
    });
  }

  void _syncFromController() {
    final digits = _sanitizeOTP(_controller.text);
    if (digits.length > widget.length) {
      _fillOTP(digits);
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_syncFromController);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _sanitizeOTP(String raw) {
    return raw.replaceAll(RegExp(r'[^0-9]'), '');
  }

  void _fillOTP(String rawOtp) {
    final digits = _sanitizeOTP(rawOtp);
    if (digits.isEmpty) return;

    final otp = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;

    _controller.value = TextEditingValue(
      text: otp,
      selection: TextSelection.collapsed(offset: otp.length),
    );

    widget.onChanged?.call(otp);

    if (otp.length == widget.length) {
      _focusNode.unfocus();
      TextInput.finishAutofillContext(shouldSave: false);
      widget.onCompleted(otp);
    } else {
      setState(() {});
    }
  }

  void _onInputChanged(String value) {
    final digits = _sanitizeOTP(value);
    final otp = digits.length > widget.length
        ? digits.substring(0, widget.length)
        : digits;

    if (_controller.text != otp) {
      _controller.value = TextEditingValue(
        text: otp,
        selection: TextSelection.collapsed(offset: otp.length),
      );
    }

    widget.onChanged?.call(otp);

    if (otp.length == widget.length) {
      _focusNode.unfocus();
      TextInput.finishAutofillContext(shouldSave: false);
      widget.onCompleted(otp);
    } else {
      setState(() {});
    }
  }

  void clearOTP() {
    _controller.clear();
    _focusNode.requestFocus();
    widget.onChanged?.call('');
    setState(() {});
  }

  String getOTP() => _controller.text;

  void setOTP(String otp) => _fillOTP(otp);

  int get _activeIndex {
    final length = _controller.text.length;
    if (!_focusNode.hasFocus) return -1;
    return length >= widget.length ? widget.length - 1 : length;
  }

  @override
  Widget build(BuildContext context) {
    final otp = _controller.text;

    return AutofillGroup(
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          height: widget.fieldHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(widget.length, (index) {
                  final hasDigit = index < otp.length;
                  final isActive = index == _activeIndex;
                  final borderColor = isActive
                      ? widget.focusedBorderColor
                      : (hasDigit
                          ? (widget.filledBorderColor ?? AppColors.black)
                          : widget.borderColor);

                  return Container(
                    width: widget.fieldWidth,
                    height: widget.fieldHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: widget.fillColor,
                      borderRadius:
                          BorderRadius.circular(widget.borderRadius),
                      border: Border.all(
                        color: borderColor,
                        width: isActive ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      hasDigit ? otp[index] : '',
                      style: widget.textStyle,
                    ),
                  );
                }),
              ),
              // Hidden field receives keyboard OTP autofill and manual input.
              Positioned.fill(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  enableSuggestions: false,
                  autocorrect: false,
                  showCursor: false,
                  style: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 1,
                  ),
                  cursorColor: Colors.transparent,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  onChanged: _onInputChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
