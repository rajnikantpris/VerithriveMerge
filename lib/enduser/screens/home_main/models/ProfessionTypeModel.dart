class ProfessionTypeModel {
  final String id;
  final String type;
  final List<SubTypeModel> subTypes;

  ProfessionTypeModel({
    required this.id,
    required this.type,
    required this.subTypes,
  });

  factory ProfessionTypeModel.fromJson(Map<String, dynamic> json) {
    return ProfessionTypeModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      subTypes: (json['sub_types'] as List<dynamic>?)
              ?.map((item) => SubTypeModel.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'sub_types': subTypes.map((subType) => subType.toJson()).toList(),
    };
  }
}

class SubTypeModel {
  final String id;
  final String subType;
  final String image;

  SubTypeModel({
    required this.id,
    required this.subType,
    required this.image,
  });

  factory SubTypeModel.fromJson(Map<String, dynamic> json) {
    return SubTypeModel(
      id: json['id']?.toString() ?? '',
      subType: json['sub_type']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sub_type': subType,
      'image': image,
    };
  }
}

