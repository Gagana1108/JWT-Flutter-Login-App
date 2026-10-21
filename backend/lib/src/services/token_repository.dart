import 'package:backend/src/db/mysql_client.dart';
import 'package:backend/src/models/refresh_token.dart';
import 'package:backend/src/utils/date_formatter.dart';

class TokenRepository {
  final DatabaseClient _dbClient;

  TokenRepository(this._dbClient);

  Future<void> saveRefreshToken({
    required int userId,
    required String tokenHash,
    required DateTime expiresAt,
  }) async {
    await _dbClient.withConnection((conn) async {
      await conn.execute(
        'INSERT INTO refresh_tokens (user_id, token_hash, expires_at, revoked) VALUES (:userId, :tokenHash, :expiresAt, 0)',
        {
          'userId': userId,
          'tokenHash': tokenHash,
          'expiresAt': DateFormatter.toMySQLString(expiresAt),
        },
      );
    });
  }

  Future<RefreshToken?> findTokenByHash(String tokenHash) async {
    return _dbClient.withConnection((conn) async {
      final results = await conn.execute(
        'SELECT id, user_id, token_hash, expires_at, revoked, created_at FROM refresh_tokens WHERE token_hash = :tokenHash LIMIT 1',
        {'tokenHash': tokenHash},
      );

      if (results.rows.isEmpty) return null;

      final row = results.rows.first;
      return RefreshToken.fromRow(row.assoc());
    });
  }

  Future<void> revokeToken(String tokenHash) async {
    await _dbClient.withConnection((conn) async {
      await conn.execute(
        'UPDATE refresh_tokens SET revoked = 1 WHERE token_hash = :tokenHash',
        {'tokenHash': tokenHash},
      );
    });
  }

  Future<void> revokeAllUserTokens(int userId) async {
    await _dbClient.withConnection((conn) async {
      await conn.execute(
        'UPDATE refresh_tokens SET revoked = 1 WHERE user_id = :userId',
        {'userId': userId},
      );
    });
  }
}
