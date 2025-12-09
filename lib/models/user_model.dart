import 'dart:convert';

class UserModel {
  final String name;
  final String businessName;
  final String email;
  final String password;
  final DateTime joinDate;
  final String? profileImagePath; // Field Baru: Path Foto Profil

  UserModel({
    required this.name,
    required this.businessName,
    required this.email,
    required this.password,
    required this.joinDate,
    this.profileImagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'businessName': businessName,
      'email': email,
      'password': password,
      'joinDate': joinDate.toIso8601String(),
      'profileImagePath': profileImagePath, // Simpan path
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? '',
      businessName: map['businessName'] ?? '',
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      joinDate: map['joinDate'] != null
          ? DateTime.parse(map['joinDate'])
          : DateTime.now(),
      profileImagePath: map['profileImagePath'], // Load path
    );
  }

  String toJson() => json.encode(toMap());
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(json.decode(source));
}
