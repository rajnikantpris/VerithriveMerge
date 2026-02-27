enum MediaType { image, video }

class ImageModel {
  const ImageModel({
    required this.name,
    required this.path,
    required this.type,
  });

  final String name;
  final String path;
  final MediaType type;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'path': path,
      'type': type == MediaType.image ? 'image' : 'video',
    };
  }
}

