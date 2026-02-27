

class BaseModel {
  bool? success;
  String? screenCode;
  int? total_items_count;
  String? message;


  BaseModel({this.success, this.screenCode, this.message});

  BaseModel.fromJson(Map<String, dynamic> json) {
    success = json['success'];
    screenCode = json['screen_code'];
    total_items_count = json['total_items_count'];
    message = json['message'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['success'] = success;
    data['screen_code'] = screenCode;
    data['message'] = message;
    data['total_items_count'] = total_items_count;
    return data;
  }
}