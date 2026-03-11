class Classroom {
  final String? id;
  final String name;
  final String description;
  final String teacherId;
  final String accessCode;
  final DateTime? createdAt;

  Classroom({
    this.id,
    required this.name,
    required this.description,
    required this.teacherId,
    required this.accessCode,
    this.createdAt,
  });

  factory Classroom.fromJson(Map<String, dynamic> json) => Classroom(
        id: json['id']?.toString() ?? json['_id']?.toString(),
        name: json['name'] ?? '',
        description: json['description'] ?? '',
        teacherId: json['teacherId'] ?? '',
        accessCode: json['accessCode'] ?? '',
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      );

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'description': description,
      'teacherId': teacherId,
      'accessCode': accessCode,
    };
    if (id != null) data['id'] = id;
    if (createdAt != null) data['createdAt'] = createdAt!.toIso8601String();
    return data;
  }
}
