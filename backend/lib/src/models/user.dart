import 'package:backend/src/utils/date_formatter.dart';

class User {
  final int id;
  final String name;
  final String email;
  final String? passwordHash;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.passwordHash,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromRow(Map<String, dynamic> row) {
    return User(
      id: row['id'] is int
          ? row['id'] as int
          : int.parse(row['id'].toString()),
      name: row['name']?.toString() ?? '',
      email: row['email']?.toString() ?? '',
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
    if (includePassword && passwordHash != null) {
      data['password_hash'] = passwordHash;
    }
    return data;
  }
}
