import 'package:backend/src/db/mysql_client.dart';
import 'package:backend/src/models/user.dart';

class UserRepository {
  final DatabaseClient _dbClient;

  UserRepository(this._dbClient);

  Future<User?> findByEmail(String email) async {
    return _dbClient.withConnection((conn) async {
      final results = await conn.execute(
        'SELECT id, name, email, password_hash, created_at, updated_at FROM users WHERE email = :email LIMIT 1',
        {'email': email.trim().toLowerCase()},
      );

      if (results.rows.isEmpty) return null;

      final row = results.rows.first;
      return User.fromRow(row.assoc());
    });
  }

  Future<User?> findById(int id) async {
    return _dbClient.withConnection((conn) async {
      final results = await conn.execute(
        'SELECT id, name, email, password_hash, created_at, updated_at FROM users WHERE id = :id LIMIT 1',
        {'id': id},
      );

      if (results.rows.isEmpty) return null;

      final row = results.rows.first;
      return User.fromRow(row.assoc());
    });
  }

  Future<User> createUser({
    required String name,
    required String email,
    required String passwordHash,
  }) async {
    return _dbClient.withConnection((conn) async {
      final result = await conn.execute(
        'INSERT INTO users (name, email, password_hash) VALUES (:name, :email, :passwordHash)',
        {
          'name': name.trim(),
          'email': email.trim().toLowerCase(),
          'passwordHash': passwordHash,
        },
      );

      final insertId = result.lastInsertID.toInt();
      final user = await findById(insertId);
      if (user == null) {
        throw Exception('User created but failed to retrieve user record.');
      }
      return user;
    });
  }
}
