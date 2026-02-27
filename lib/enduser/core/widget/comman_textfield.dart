import 'package:flutter/material.dart';
import '../values/app_colors.dart';

class CommanTextField extends StatelessWidget {

  final String hint;
  final String label;
  final int keyboardType;
  final int inputAction;
  final int maxlines;
  final bool isPassword;
  final bool isBottomLine;
  final bool isEnable;
  final Widget? prefixIcon;
  final Widget? sufixIcon;
  final TextEditingController? controller;


   const CommanTextField({
     required this.hint,
     required this.label,
     required this.keyboardType,
     required this.inputAction,
     required this.maxlines,
     this.prefixIcon,
     this.sufixIcon,
     this.isPassword = false,
     this.isBottomLine = true,
     this.isEnable = true,
     required this.controller,
   });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style:TextStyle(
          fontSize: 14,
          fontFamily: "PoppinsRegular",),

      minLines: 1,
      maxLines: maxlines,
      obscureText: isPassword,
      controller: controller,
      autofocus: false,
      enabled: isEnable,
      decoration: InputDecoration(
        // isDense: true,
        enabledBorder:OutlineInputBorder(
          borderRadius: BorderRadius.circular(5.0),
          borderSide: BorderSide(
            color: AppColors.black,
            // width: 2.0,
          ),
        ),
        focusedBorder:OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(
            // width: 100,
            color: AppColors.black,
          ),
        ),
        labelText: label,
        labelStyle: hintText(),
        hintText: hint,
        hintStyle: hintText(),
        fillColor: Colors.white,
        prefixIcon: prefixIcon,
        suffixIcon:sufixIcon,

      ),
      keyboardType: keyboardTypes(keyboardType),
      textInputAction: keyboardActions(inputAction),
    );
  }

  TextInputType keyboardTypes(int value) {
    switch (value) {
      case 1:
        return TextInputType.emailAddress;
      case 2:
        return TextInputType.visiblePassword;
      case 3:
        return TextInputType.number;
      case 4:
        return TextInputType.name;
      case 5:
        return TextInputType.text;
      case 6:
        return TextInputType.url;
      case 7:
        return TextInputType.datetime;
      case 8:
        return TextInputType.multiline;
      case 9:
        return TextInputType.streetAddress;
      case 10:
        return TextInputType.none;
      default:
        return TextInputType.none;
    }
  }

  TextInputAction keyboardActions(int value) {
    switch (value) {
      case 1:
        return TextInputAction.next;
      case 2:
        return TextInputAction.done;
      case 3:
        return TextInputAction.previous;
      case 4:
        return TextInputAction.search;
      case 5:
        return TextInputAction.go;
      case 6:
        return TextInputAction.send;
      case 7:
        return TextInputAction.newline;
      case 8:
        return TextInputAction.join;
      case 9:
        return TextInputAction.continueAction;
      case 10:
        return TextInputAction.emergencyCall;
      case 11:
        return TextInputAction.none;
      default:
        return TextInputAction.none;
    }
  }



  InputDecoration inputDecoration(BuildContext context, String hint, String lable) {
    return InputDecoration(
      enabledBorder: inputBorder(),
      focusedBorder: inputBorder(),
      labelText: lable,
      labelStyle: hintText(),
      hintText: hint,
      hintStyle: hintText(),
    );
  }

  UnderlineInputBorder inputBorder() {
    return  const UnderlineInputBorder(
        borderSide: BorderSide(color:  AppColors.orderDateClr));
  }

  TextStyle hintText() {
    return  const TextStyle(color: AppColors.black );
  }


}
