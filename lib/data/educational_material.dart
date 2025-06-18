class EducationalMaterial {
  final int id;
  final String title;
  final String description;
  final String thumbnail;
  final String materialFile;
  final String materialUrl;
  final String materialType; // 'file' or 'url'
  final int isPublish;
  final int userId;
  final DateTime createdAt;
  final DateTime updatedAt;

  EducationalMaterial({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.materialFile,
    required this.materialUrl,
    required this.materialType,
    required this.isPublish,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
  });
}
