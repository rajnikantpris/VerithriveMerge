class ProfessionSubTypeModel {
  final String? id;
  final String? professionType;
  final String? subType;

  const ProfessionSubTypeModel({
    this.id,
    this.professionType,
    this.subType,
  });

  factory ProfessionSubTypeModel.fromJson(Map<String, dynamic> json) =>
      ProfessionSubTypeModel(
        id: json['_id'] as String?,
        professionType: json['profession_type'] as String?,
        subType: json['sub_type'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) '_id': id,
        if (professionType != null) 'profession_type': professionType,
        if (subType != null) 'sub_type': subType,
      };
}

