class BaseModel {
  final bool? success;
  final String? message;
  final BaseDataModel? data;

  const BaseModel({
    this.success,
    this.message,
    this.data,
  });

  factory BaseModel.fromJson(Map<String, dynamic> json) => BaseModel(
        success: json['success'] as bool?,
        message: json['message'] as String?,
        data: json['data'] is Map<String, dynamic>
            ? BaseDataModel.fromJson(json['data'] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'success': success,
        'message': message,
        if (data != null) 'data': data!.toJson(),
      };
}

class BaseDataModel {
  final int? count;

  const BaseDataModel({this.count});

  factory BaseDataModel.fromJson(Map<String, dynamic> json) => BaseDataModel(
        count: json['count'] as int?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'count': count,
      };
}
