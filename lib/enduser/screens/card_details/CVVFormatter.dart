import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class CVVFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    
    // Limit to 3 digits
    if (text.length > 3) {
      text = text.substring(0, 3);
    }
    
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}