class User {
  final String? id;
  final String? username;
  final String? password;
  final String? fullName;
  final String? role;

  User({this.id, this.username, this.password, this.fullName, this.role});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        username: json['username'],
        password: json['password'],
        role: json['role'],
        fullName: json['fullName'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'password': password,
        'role': role,
        'fullName': fullName,
      };
}
