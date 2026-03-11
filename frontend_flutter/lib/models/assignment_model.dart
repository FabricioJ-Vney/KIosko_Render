class Assignment {
  final String? id;
  final String title;
  final String description;
  final String teacherId;
  final String? rubricId;
  final DateTime? dueDate;
  final String? accessCode;
  final String? classroomId;

  Assignment({
    this.id,
    required this.title,
    required this.description,
    required this.teacherId,
    this.rubricId,
    this.dueDate,
    this.accessCode,
    this.classroomId,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) => Assignment(
    id: json['id']?.toString() ?? json['_id']?.toString(),
    title: json['title'] as String? ?? 'Sin Título',
    description: json['description'] as String? ?? '',
    teacherId: json['teacherId'] as String? ?? '',
    rubricId: json['rubricId'] as String?,
    dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
    accessCode: json['accessCode'] as String?,
    classroomId: json['classroomId'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'teacherId': teacherId,
    'rubricId': rubricId,
    'dueDate': dueDate?.toIso8601String(),
    'accessCode': accessCode,
    'classroomId': classroomId,
  };
}
