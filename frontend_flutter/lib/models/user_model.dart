class User {
  final String? id;
  final String? email;
  final String? password;
  final String? fullName;
  final String? role;
  final String? telefono;
  final String? bio;
  final String? fotoPerfil;

  User({this.id, this.email, this.password, this.fullName, this.role, this.telefono, this.bio, this.fotoPerfil});

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'],
        email: json['email'],
        password: json['password'],
        role: json['role'],
        fullName: json['fullName'],
        telefono: json['telefono'],
        bio: json['bio'],
        fotoPerfil: json['fotoPerfil'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'password': password,
        'role': role,
        'fullName': fullName,
        'telefono': telefono,
        'bio': bio,
        'fotoPerfil': fotoPerfil,
      };
}
