import 'package:backend/src/config/env.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:test/test.dart';

void main() {
  test('test mysql operations', () async {
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
      final insertResult = await conn.execute(
        'INSERT INTO users (name, email, password_hash) VALUES (:name, :email, :pass)',
        {
          'name': 'Test User',
          'email': 'repro_${DateTime.now().millisecondsSinceEpoch}@example.com',
          'pass': 'hash123',
        },
      );

      final selectResult = await conn.execute(
        'SELECT id, name, email, password_hash, created_at, updated_at FROM users WHERE id = :id',
        {'id': insertResult.lastInsertID},
      );

      expect(selectResult.rows.isNotEmpty, isTrue);
    } finally {
      await conn.close();
    }
  });
}
