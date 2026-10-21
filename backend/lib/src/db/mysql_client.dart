import 'package:backend/src/config/env.dart';
import 'package:mysql_client/mysql_client.dart';

class DatabaseClient {
  final String host;
  final int port;
  final String dbName;
  final String user;
  final String password;

  DatabaseClient({
    String? host,
    int? port,
    String? dbName,
    String? user,
    String? password,
  })  : host = host ?? EnvConfig.dbHost,
        port = port ?? EnvConfig.dbPort,
        dbName = dbName ?? EnvConfig.dbName,
        user = user ?? EnvConfig.dbUser,
        password = password ?? EnvConfig.dbPassword;

  Future<MySQLConnection> getConnection() async {
    final conn = await MySQLConnection.createConnection(
      host: host,
      port: port,
      databaseName: dbName,
      userName: user,
      password: password,
    );
    await conn.connect();
    return conn;
  }

  /// Executes database operation and automatically closes connection.
  Future<R> withConnection<R>(
    Future<R> Function(MySQLConnection conn) action,
  ) async {
    final conn = await getConnection();
    try {
      return await action(conn);
    } finally {
      await conn.close();
    }
  }
}
