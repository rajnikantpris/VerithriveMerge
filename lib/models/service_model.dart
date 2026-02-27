class ServiceModel {
  final String? id;
  final String? subTypeId;
  final String? serviceName;
  final bool? isActive;
  final bool? isDeleted;
  final List<SubServiceModel>? subServices;

  const ServiceModel({
    this.id,
    this.subTypeId,
    this.serviceName,
    this.isActive,
    this.isDeleted,
    this.subServices,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['_id'] as String?,
        subTypeId: json['sub_type_id'] as String?,
        serviceName: json['service_name'] as String?,
        isActive: json['is_active'] as bool?,
        isDeleted: json['is_deleted'] as bool?,
        subServices: json['sub_services'] is List
            ? (json['sub_services'] as List)
                .map((item) =>
                    SubServiceModel.fromJson(item as Map<String, dynamic>))
                .toList()
            : null,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) '_id': id,
        if (subTypeId != null) 'sub_type_id': subTypeId,
        if (serviceName != null) 'service_name': serviceName,
        if (isActive != null) 'is_active': isActive,
        if (isDeleted != null) 'is_deleted': isDeleted,
        if (subServices != null)
          'sub_services': subServices!.map((item) => item.toJson()).toList(),
      };
}

class SubServiceModel {
  final String? id;
  final String? subServiceName;

  const SubServiceModel({
    this.id,
    this.subServiceName,
  });

  factory SubServiceModel.fromJson(Map<String, dynamic> json) =>
      SubServiceModel(
        id: json['_id'] as String?,
        subServiceName: json['sub_service_name'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) '_id': id,
        if (subServiceName != null) 'sub_service_name': subServiceName,
      };
}

class ServiceFormatModel {
  final String? id;
  final String? name;
  final bool? isActive;
  final bool? isDeleted;
  final bool? isBundle;
  final int? bundleOf;

  const ServiceFormatModel({
    this.id,
    this.name,
    this.isActive,
    this.isDeleted,
    this.isBundle,
    this.bundleOf,
  });

  factory ServiceFormatModel.fromJson(Map<String, dynamic> json) =>
      ServiceFormatModel(
        id: json['_id'] as String?,
        name: json['name'] as String?,
        isActive: json['is_active'] as bool?,
        isDeleted: json['is_deleted'] as bool?,
        isBundle: json['is_bundle'] as bool?,
        bundleOf: json['bundle_of'] as int?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) '_id': id,
        if (name != null) 'name': name,
        if (isActive != null) 'is_active': isActive,
        if (isDeleted != null) 'is_deleted': isDeleted,
        if (isBundle != null) 'is_bundle': isBundle,
        if (bundleOf != null) 'bundle_of': bundleOf,
      };
}
