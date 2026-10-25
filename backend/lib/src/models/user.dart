import 'package:backend/src/utils/date_formatter.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final String? passwordHash;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'user',
    this.passwordHash,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isAdmin => role == 'admin';

  factory User.fromRow(Map<String, dynamic> row) {
    return User(
      id: row['id'] is int
          ? row['id'] as int
          : int.parse(row['id'].toString()),
      name: row['name']?.toString() ?? '',
      email: row['email']?.toString() ?? '',
      role: row['role']?.toString() ?? 'user',
      passwordHash: row['password_hash']?.toString(),
      createdAt: DateFormatter.parse(row['created_at']),
      updatedAt: DateFormatter.parse(row['updated_at']),
    );
  }

  Map<String, dynamic> toJson({bool includePassword = false}) {
    final data = <String, dynamic>{
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (includePassword && passwordHash != null) {
      data['password_hash'] = passwordHash;
    }
    return data;
  }
}
