import 'package:backend/src/config/env.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:test/test.dart';

void main() {
  test('test mysql_client connection and queries', () async {
    EnvConfig.init();

    final conn = await MySQLConnection.createConnection(
      host: EnvConfig.dbHost,
      port: EnvConfig.dbPort,
      userName: EnvConfig.dbUser,
      password: EnvConfig.dbPassword,
      databaseName: EnvConfig.dbName,
    );

    await conn.connect();

    try {
      final email = 'test_mysql_client_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final res = await conn.execute(
        'INSERT INTO users (name, email, password_hash) VALUES (:name, :email, :passwordHash)',
        {
          'name': 'Test User',
          'email': email,
          'passwordHash': 'hashed_password_123',
        },
      );

      final selectRes = await conn.execute(
        'SELECT id, name, email, password_hash, created_at, updated_at FROM users WHERE id = :id',
        {'id': res.lastInsertID},
      );

      expect(selectRes.rows.length, equals(1));
      final row = selectRes.rows.first;
      final assoc = row.assoc();
      expect(assoc['email'], equals(email));
    } finally {
      await conn.close();
    }
  });
}
