import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

class CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    
    // Remove all spaces
    text = text.replaceAll(' ', '');
    
    // Limit to 16 digits
    if (text.length > 16) {
      text = text.substring(0, 16);
    }
    
    // Add space after every 4 digits
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted += ' ';
      }
      formatted += text[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}