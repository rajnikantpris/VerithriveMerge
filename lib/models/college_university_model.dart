class CollegeUniversityModel {
  final String? id;
  final String? name;

  const CollegeUniversityModel({
    this.id,
    this.name,
  });

  factory CollegeUniversityModel.fromJson(Map<String, dynamic> json) =>
      CollegeUniversityModel(
        id: json['_id'] as String?,
        name: json['name'] as String?,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (id != null) '_id': id,
        if (name != null) 'name': name,
      };
}
