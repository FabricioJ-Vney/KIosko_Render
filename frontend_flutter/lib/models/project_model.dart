class Project {
  final String? id;
  final String? teamName;
  final String? title;
  final String? category;
  final String? description;
  final String? status;
  final List<String>? technologies;
  final String? studentId;
  final String? assignedTeacherId;
  final String? coverImageUrl;
  final String? iconUrl;
  final String? assignmentId;

  Project({
    this.id, 
    this.teamName,
    this.title, 
    this.category,
    this.description,
    this.status, 
    this.technologies,
    this.studentId,
    this.assignedTeacherId,
    this.coverImageUrl,
    this.iconUrl,
    this.assignmentId,
  });

  factory Project.fromJson(Map<String, dynamic> json) => Project(
        id: json['id']?.toString() ?? json['Id']?.toString() ?? json['_id']?.toString(),
        teamName: json['teamName']?.toString() ?? json['TeamName']?.toString(),
        title: json['title']?.toString() ?? json['Title']?.toString() ?? (json['teamName']?.toString() ?? json['TeamName']?.toString()),
        category: json['category']?.toString() ?? json['Category']?.toString(),
        description: json['description']?.toString() ?? json['Description']?.toString(),
        status: json['status']?.toString() ?? json['Status']?.toString(),
        technologies: (json['technologies'] as List?)?.cast<String>() ?? (json['Technologies'] as List?)?.cast<String>(),
        studentId: json['studentId']?.toString() ?? json['StudentId']?.toString(),
        assignedTeacherId: json['assignedTeacherId']?.toString() ?? json['AssignedTeacherId']?.toString(),
        coverImageUrl: json['coverImageUrl']?.toString() ?? json['CoverImageUrl']?.toString(),
        iconUrl: json['iconUrl']?.toString() ?? json['IconUrl']?.toString(),
        assignmentId: json['assignmentId']?.toString() ?? json['AssignmentId']?.toString(),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'teamName': teamName,
    'title': title,
    'category': category,
    'description': description,
    'status': status,
    'technologies': technologies,
    'studentId': studentId,
    'assignedTeacherId': assignedTeacherId,
    'coverImageUrl': coverImageUrl,
    'iconUrl': iconUrl,
    'assignmentId': assignmentId,
  };
}
