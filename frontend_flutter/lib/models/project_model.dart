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
    this.iconUrl
  });

  factory Project.fromJson(Map<String, dynamic> json) =>
      Project(
        id: json['id'],
        teamName: json['teamName'],
        title: json['title'] ?? json['teamName'],
        category: json['category'],
        description: json['description'],
        status: json['status'],
        technologies: (json['technologies'] as List?)?.cast<String>(),
        studentId: json['studentId'],
        assignedTeacherId: json['assignedTeacherId'],
        coverImageUrl: json['coverImageUrl'],
        iconUrl: json['iconUrl'],
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
  };
}
