import 'package:backend/src/utils/date_formatter.dart';

class RefreshToken {
  final int id;
  final int userId;
  final String tokenHash;
  final DateTime expiresAt;
  final bool revoked;
  final DateTime createdAt;

  RefreshToken({
    required this.id,
    required this.userId,
    required this.tokenHash,
    required this.expiresAt,
    required this.revoked,
    required this.createdAt,
  });

  factory RefreshToken.fromRow(Map<String, dynamic> row) {
    return RefreshToken(
      id: row['id'] is int
          ? row['id'] as int
          : int.parse(row['id'].toString()),
      userId: row['user_id'] is int
          ? row['user_id'] as int
          : int.parse(row['user_id'].toString()),
      tokenHash: row['token_hash']?.toString() ?? '',
      expiresAt: DateFormatter.parse(row['expires_at']),
      revoked: row['revoked'].toString() == '1' || row['revoked'] == true,
      createdAt: DateFormatter.parse(row['created_at']),
    );
  }
}
