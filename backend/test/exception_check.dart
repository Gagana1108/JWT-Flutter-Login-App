import 'package:mysql_client/mysql_client.dart';

void main() async {
  try {
    final conn = await MySQLConnection.createConnection(
      host: '127.0.0.1',
      port: 3306,
      userName: 'root',
      password: 'wrong_password_test_123',
    );
    await conn.connect();
  } catch (e) {
    print('Type name: ${e.runtimeType}');
    print('Type is Exception: ${e is Exception}');
    print('Type is FormatException: ${e is FormatException}');
    print('Error message: ${e.toString()}');
  }
}
