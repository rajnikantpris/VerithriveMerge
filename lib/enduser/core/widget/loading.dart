import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../values/app_values.dart';
import 'elevated_container.dart';

class Loading extends StatelessWidget {
  const Loading({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: ElevatedContainer(
        padding: EdgeInsets.all(AppValues.margin),
        child:
        CircularProgressIndicator(
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}
