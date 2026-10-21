import 'package:backend/src/config/env.dart';
import 'package:mysql_client/mysql_client.dart';
import 'package:test/test.dart';

void main() {
  test('test datetime insertion format', () async {
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
      final now = DateTime.now().add(const Duration(days: 7)).toUtc();

      // Formatter function
      final formattedStr = '${now.year.toString().padLeft(4, '0')}-'
          '${now.month.toString().padLeft(2, '0')}-'
          '${now.day.toString().padLeft(2, '0')} '
          '${now.hour.toString().padLeft(2, '0')}:'
          '${now.minute.toString().padLeft(2, '0')}:'
          '${now.second.toString().padLeft(2, '0')}';

      print('Formatted datetime string: $formattedStr');

      await conn.execute(
        'INSERT INTO refresh_tokens (user_id, token_hash, expires_at, revoked) VALUES (1, :hash, :expiresAt, 0)',
        {
          'hash': 'test_datetime_${DateTime.now().millisecondsSinceEpoch}',
          'expiresAt': formattedStr,
        },
      );

      print('Inserted successfully with formatted string!');
    } catch (e, stack) {
      print('EXCEPTION: $e');
      print('STACK TRACE: $stack');
      rethrow;
    } finally {
      await conn.close();
    }
  });
}
