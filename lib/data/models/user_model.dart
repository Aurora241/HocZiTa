class UserModel {
  final String id;
  final String name;
  final String email;
  final String password;
  final String? avatarPath;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    this.avatarPath,
    required this.createdAt,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? password,
    String? avatarPath,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      password: password ?? this.password,
      avatarPath: avatarPath ?? this.avatarPath,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'avatarPath': avatarPath,
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'],
        name: json['name'],
        email: json['email'],
        password: json['password'],
        avatarPath: json['avatarPath'],
        createdAt: DateTime.parse(json['createdAt']),
      );
}
