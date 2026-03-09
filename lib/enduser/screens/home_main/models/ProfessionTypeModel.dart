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
    List<SubTypeModel> subTypesList = [];
    if (json['sub_types'] != null) {
      subTypesList = (json['sub_types'] as List<dynamic>)
          .map((item) => SubTypeModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ProfessionTypeModel(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      subTypes: subTypesList,
    );
  }
}

class SubTypeModel {
  final String id;
  final String subType;
  final String? image;

  SubTypeModel({
    required this.id,
    required this.subType,
    this.image,
  });

  factory SubTypeModel.fromJson(Map<String, dynamic> json) {
    // Read image directly from the confirmed 'image' key
    String? imageUrl = json['image']?.toString().trim();

    return SubTypeModel(
      id: json['id']?.toString() ?? '',
      subType: json['sub_type']?.toString() ?? '',
      image: (imageUrl != null && imageUrl.isNotEmpty) ? imageUrl : null,
    );
  }
}