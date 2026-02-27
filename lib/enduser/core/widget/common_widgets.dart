import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'dart:io';
import '../../utils/AppText.dart';
import '../values/app_colors.dart';

class CommonUtils {
  static CommonUtils? commonUtils;
  static CommonUtils getIntance() {
    commonUtils ??= CommonUtils();
    return commonUtils!;
  }
  void toastMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      backgroundColor: AppColors.black,
      textColor: AppColors.colorWhite,
      timeInSecForIosWeb: 5,
    );
  }

  Future<List<String>> getDeviceData() async {
    var deviceInfo = DeviceInfoPlugin();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    List<String> data = [];
    if (Platform.isIOS) {
      var iosDeviceInfo = await deviceInfo.iosInfo;
      data.add(iosDeviceInfo.identifierForVendor!);
      data.add(iosDeviceInfo.model!);
      data.add(iosDeviceInfo.utsname.version.toString());
      data.add(packageInfo.buildNumber);
    } else {
      var androidDeviceInfo = await deviceInfo.androidInfo;
      if (androidDeviceInfo.id != null) {
        data.add(androidDeviceInfo.id);
      } else {
        data.add(androidDeviceInfo.id);
      }
      data.add(androidDeviceInfo.model);
      data.add(androidDeviceInfo.version.sdkInt.toString());
      data.add(packageInfo.version);
      data.add(packageInfo.buildNumber);
    }
    return data;
  }

  showAlertWithMultipleAction(BuildContext context, String message, onPressedOK(), ) {
    showDialog(
        builder: (ctx) => AlertDialog(
          content: Text(message),
          actions: <Widget>[
            TextButton(
                child: const Text(AppText.yes),
                onPressed: () {
                  Navigator.pop(ctx);
                  onPressedOK();
                }),
            TextButton(
                child: const Text(AppText.cancel),
                onPressed: () {
                  Navigator.pop(ctx);
                  // onPressedCancel();
                }),
          ],
        ),
        context: context);
  }


}