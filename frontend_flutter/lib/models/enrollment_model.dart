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
        id: json['id']?.toString() ?? json['_id']?.toString() ?? json['Id']?.toString(),
        classroomId: json['classroomId']?.toString() ?? json['ClassroomId']?.toString() ?? '',
        studentId: json['studentId']?.toString() ?? json['StudentId']?.toString() ?? '',
        status: json['status']?.toString() ?? json['Status']?.toString() ?? 'Pending',
        requestedAt: json['requestedAt'] != null ? DateTime.tryParse(json['requestedAt'].toString()) : 
                     (json['RequestedAt'] != null ? DateTime.tryParse(json['RequestedAt'].toString()) : null),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'classroomId': classroomId,
        'studentId': studentId,
        'status': status,
        'requestedAt': requestedAt?.toIso8601String(),
      };
}
