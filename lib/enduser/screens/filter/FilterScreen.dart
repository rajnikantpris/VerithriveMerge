import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'FilterView.dart';

class FilterScreen extends GetView {
  const FilterScreen({Key? key, this.pageCategory = 'wellness'});
  
  final String pageCategory;

  @override
  Widget build(BuildContext context) {
    return FilterView(pageCategory: pageCategory);
  }
}


