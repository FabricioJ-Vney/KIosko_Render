class User {
  final String? id;
  final String? email;
  final String? password;
  final String? fullName;
  final String? role;

  User({this.id, this.email, this.password, this.fullName, this.role});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        email: json['email'],
        password: json['password'],
        role: json['role'],
        fullName: json['fullName'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'password': password,
        'role': role,
        'fullName': fullName,
      };
}
