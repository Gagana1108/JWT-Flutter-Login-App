import 'package:backend/src/db/mysql_client.dart';
import 'package:backend/src/models/user.dart';

class UserRepository {
  final DatabaseClient _dbClient;

  UserRepository(this._dbClient);

  Future<User?> findByEmail(String email) async {
    return _dbClient.withConnection((conn) async {
      final results = await conn.execute(
        'SELECT id, name, email, role, password_hash, created_at, updated_at FROM users WHERE email = :email LIMIT 1',
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
        'SELECT id, name, email, role, password_hash, created_at, updated_at FROM users WHERE id = :id LIMIT 1',
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
        'INSERT INTO users (name, email, role, password_hash) VALUES (:name, :email, "user", :passwordHash)',
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

  Future<User?> updateUserProfile({
    required int id,
    required String name,
  }) async {
    return _dbClient.withConnection((conn) async {
      await conn.execute(
        'UPDATE users SET name = :name WHERE id = :id',
        {
          'id': id,
          'name': name.trim(),
        },
      );
      return findById(id);
    });
  }

  Future<List<User>> getAllUsers() async {
    return _dbClient.withConnection((conn) async {
      final results = await conn.execute(
        'SELECT id, name, email, role, created_at, updated_at FROM users ORDER BY id ASC',
      );

      return results.rows.map((row) => User.fromRow(row.assoc())).toList();
    });
  }

  Future<User?> updateUserRole({
    required int id,
    required String role,
  }) async {
    return _dbClient.withConnection((conn) async {
      await conn.execute(
        'UPDATE users SET role = :role WHERE id = :id',
        {
          'id': id,
          'role': role,
        },
      );
      return findById(id);
    });
  }
}
