class ProfessionTypeModel {
  final String? id;
  final String? type;

  const ProfessionTypeModel({
    this.id,
    this.type,
  });

  factory ProfessionTypeModel.fromJson(Map<String, dynamic> json) =>
      ProfessionTypeModel(
        id: json['_id'] as String?,
        type: json['type'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) '_id': id,
        if (type != null) 'type': type,
      };
}

