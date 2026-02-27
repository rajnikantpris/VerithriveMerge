import 'package:flutter/material.dart';
import 'app_colors.dart';

  Widget text(text,style) {
    return Text(
      text,
      textScaleFactor: 1,
      textAlign: TextAlign.center,
      style: style,);
  }

  Widget FormFields(BuildContext context,Controllers, String hint, String lable,int maxlines){

    return Padding(
      padding:  const EdgeInsets.symmetric(vertical: 8.0,horizontal: 16),
      child: TextFormField(
        style:const TextStyle(
          fontSize: 14,
            fontFamily: "PoppinsRegular"),

        minLines: 1,
        maxLines: maxlines,
        controller: Controllers,
        decoration: InputDecoration(
          labelText: lable,
          labelStyle: const TextStyle(color: AppColors.appColor ),
          fillColor: Colors.white,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: const BorderSide(
              // width: 100,
              color: AppColors.appColor,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(5.0),
            borderSide: const BorderSide(
              color: AppColors.appColor,
              // width: 2.0,
            ),
          ),
        )
      ),
    );
}

  Widget AppbarWithoutTitle(BuildContext context,TitleText){
    return  AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      // shape: RoundedRectangleBorder(
      //     side: BorderSide(color:AppColors.appColor),
      //     borderRadius: BorderRadius.only(bottomLeft:Radius.circular(20))),
      // StarBorder(side: BorderSide(color:  AppColors.appColor),),
      // OvalBorder(side: BorderSide(color: AppColors.appColor)),
      // Border(
      //     bottom: BorderSide(color: AppColors.appColor,)),
      leading: IconButton(
          icon: const Icon(Icons.arrow_back, color:AppColors.black),
          onPressed: () => Navigator.of(context).pop()),
      backgroundColor: AppColors.pageBackground,
      centerTitle: true,
      title:Text(TitleText,) ,
    );
}



