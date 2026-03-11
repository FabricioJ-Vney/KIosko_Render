class ClassEnrollment {
  final String? id;
  final String classroomId;
  final String studentId;
  final String status;
  final DateTime? requestedAt;

  ClassEnrollment({
    this.id,
    required this.classroomId,
    required this.studentId,
    required this.status,
    this.requestedAt,
  });

  factory ClassEnrollment.fromJson(Map<String, dynamic> json) => ClassEnrollment(
        id: json['id']?.toString() ?? json['_id']?.toString(),
        classroomId: json['classroomId'] ?? '',
        studentId: json['studentId'] ?? '',
        status: json['status'] ?? 'Pending',
        requestedAt: json['requestedAt'] != null ? DateTime.parse(json['requestedAt']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'classroomId': classroomId,
        'studentId': studentId,
        'status': status,
        'requestedAt': requestedAt?.toIso8601String(),
      };
}
