import 'package:flutter/services.dart';

class ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;
    
    // Remove all slashes
    text = text.replaceAll('/', '');
    
    // Limit to 4 digits (MMYY)
    if (text.length > 4) {
      text = text.substring(0, 4);
    }
    
    // Add slash after 2 digits
    String formatted = '';
    for (int i = 0; i < text.length; i++) {
      if (i == 2) {
        formatted += '/';
      }
      formatted += text[i];
    }
    
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
