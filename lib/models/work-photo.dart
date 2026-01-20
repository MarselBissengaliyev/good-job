class WorkPhoto {
  final int id;
  final String path;
  final int masterProfileId;
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WorkPhoto({
    required this.id,
    required this.path,
    required this.masterProfileId,
    required this.sortOrder,
    this.createdAt,
    this.updatedAt,
  });

  factory WorkPhoto.fromJson(Map<String, dynamic> json) {
    print('Parsing WorkPhoto from JSON: $json');
    
    // Добавляем безопасное извлечение данных
    final id = json['id'] ?? 0;
    final path = json['path']?.toString() ?? '';
    final masterProfileId = json['master_profile_id'] ?? json['masterProfileId'] ?? 0;
    final sortOrder = json['sort_order'] ?? json['sortOrder'] ?? 0;
    
    print('Parsed values: id=$id, path=$path, masterProfileId=$masterProfileId, sortOrder=$sortOrder');
    
    return WorkPhoto(
      id: id,
      path: path,
      masterProfileId: masterProfileId,
      sortOrder: sortOrder,
      createdAt: json['created_at'] != null && json['created_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null && json['updated_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }
  
  @override
  String toString() {
    return 'WorkPhoto{id: $id, path: $path}';
  }
}